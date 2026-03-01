resource "null_resource" "argocd_port_forward" {
  triggers = {
    kubeconfig_path = var.kubeconfig_path
    server_addr     = local.argocd_server_addr_normalized
    state_dir       = local.argocd_port_forward_state_dir
    pid_file        = local.argocd_port_forward_pid_file
    log_file        = local.argocd_port_forward_log_file
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      mkdir -p "$PORT_FORWARD_STATE_DIR"

      existing_pid=""
      if [ -f "$PORT_FORWARD_PID_FILE" ]; then
        existing_pid="$(cat "$PORT_FORWARD_PID_FILE" 2>/dev/null || true)"
      fi

      if [ -n "$existing_pid" ] && kill -0 "$existing_pid" >/dev/null 2>&1; then
        if ps -p "$existing_pid" -o args= | grep -F "kubectl" | grep -F "port-forward" | grep -F "$ARGOCD_SERVICE" | grep -F "8080:80" >/dev/null 2>&1; then
          exit 0
        fi
      fi

      if pgrep -f "kubectl.*port-forward.*$ARGOCD_SERVICE.*8080:80" >/dev/null 2>&1; then
        exit 0
      fi

      nohup kubectl --kubeconfig="$KUBECONFIG_PATH" -n "$ARGOCD_NAMESPACE" port-forward "$ARGOCD_SERVICE" 8080:80 >"$PORT_FORWARD_LOG_FILE" 2>&1 &
      echo $! > "$PORT_FORWARD_PID_FILE"
      disown

      sleep 2

      if ! kill -0 "$(cat "$PORT_FORWARD_PID_FILE" 2>/dev/null || echo)" >/dev/null 2>&1; then
        echo "[argocd-port-forward] kubectl port-forward failed to start; inspect $PORT_FORWARD_LOG_FILE" >&2
        exit 1
      fi

      for attempt in {1..10}; do
        if (exec 3<>/dev/tcp/127.0.0.1/8080) 2>/dev/null; then
          exec 3>&-
          break
        fi
        if [ "$attempt" -eq 10 ]; then
          echo "[argocd-port-forward] port 8080 still unreachable after wait; inspect $PORT_FORWARD_LOG_FILE" >&2
          exit 1
        fi
        sleep 1
      done
    EOT

    environment = {
      KUBECONFIG_PATH        = var.kubeconfig_path
      ARGOCD_NAMESPACE       = "argocd"
      ARGOCD_SERVICE         = "svc/argo-cd-argocd-server"
      PORT_FORWARD_STATE_DIR = self.triggers.state_dir
      PORT_FORWARD_PID_FILE  = self.triggers.pid_file
      PORT_FORWARD_LOG_FILE  = self.triggers.log_file
    }
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      if [ -f "$PORT_FORWARD_PID_FILE" ]; then
        pid="$(cat "$PORT_FORWARD_PID_FILE" 2>/dev/null || true)"
        if [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1; then
          kill "$pid" >/dev/null 2>&1 || true
        fi
        rm -f "$PORT_FORWARD_PID_FILE"
      fi

      if [ -f "$PORT_FORWARD_LOG_FILE" ]; then
        rm -f "$PORT_FORWARD_LOG_FILE"
      fi

      if [ -d "$PORT_FORWARD_STATE_DIR" ]; then
        rmdir "$PORT_FORWARD_STATE_DIR" 2>/dev/null || true
      fi
    EOT

    environment = {
      PORT_FORWARD_PID_FILE  = self.triggers.pid_file
      PORT_FORWARD_STATE_DIR = self.triggers.state_dir
      PORT_FORWARD_LOG_FILE  = self.triggers.log_file
    }
  }
}
