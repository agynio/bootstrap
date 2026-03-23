locals {
  cluster_admin_identity_id        = "a3c1e9d2-7f4b-5e1a-9c3d-2b8f6a4e7d10"
  cluster_admin_oidc_subject       = "cluster-admin"
  cluster_admin_api_token_name     = "Cluster Admin bootstrap"
  cluster_admin_name_sql           = replace(var.cluster_admin_name, "'", "''")
  cluster_admin_api_token_name_sql = replace(local.cluster_admin_api_token_name, "'", "''")
  cluster_admin_api_token_plaintext = format(
    "agyn_%s",
    random_string.cluster_admin_api_token.result,
  )
  cluster_admin_api_token_hash   = sha256(local.cluster_admin_api_token_plaintext)
  cluster_admin_api_token_prefix = substr(local.cluster_admin_api_token_plaintext, 0, 8)
  cluster_admin_bootstrap_sql    = <<-SQL
    INSERT INTO users (identity_id, oidc_subject, name, nickname, photo_url)
    VALUES ('${local.cluster_admin_identity_id}', '${local.cluster_admin_oidc_subject}', '${local.cluster_admin_name_sql}', '${local.cluster_admin_name_sql}', '')
    ON CONFLICT DO NOTHING;

    INSERT INTO user_api_tokens (id, identity_id, name, token_hash, token_prefix, expires_at, created_at, last_used_at)
    VALUES (
      uuid_generate_v4(),
      '${local.cluster_admin_identity_id}',
      '${local.cluster_admin_api_token_name_sql}',
      '${local.cluster_admin_api_token_hash}',
      '${local.cluster_admin_api_token_prefix}',
      NULL,
      NOW(),
      NULL
    )
    ON CONFLICT DO NOTHING;
  SQL
}

resource "random_string" "cluster_admin_api_token" {
  length  = 44
  lower   = true
  upper   = true
  numeric = true
  special = false
}

resource "kubernetes_job_v1" "cluster_admin_bootstrap" {
  metadata {
    name      = "cluster-admin-bootstrap"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "cluster-admin-bootstrap"
    }
  }

  spec {
    backoff_limit = 3

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "cluster-admin-bootstrap"
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name              = "cluster-admin-bootstrap"
          image             = local.postgres_image
          image_pull_policy = "IfNotPresent"

          env {
            name  = "PGHOST"
            value = "users-db"
          }
          env {
            name  = "PGPORT"
            value = "5432"
          }
          env {
            name  = "PGUSER"
            value = "users"
          }
          env {
            name  = "PGPASSWORD"
            value = var.users_db_password
          }
          env {
            name  = "PGDATABASE"
            value = "users"
          }
          env {
            name  = "PGSSLMODE"
            value = "disable"
          }

          command = [
            "sh",
            "-c",
            <<-EOT
            set -euo pipefail

            attempts=0
            until pg_isready -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" >/dev/null 2>&1; do
              attempts=$((attempts + 1))
              if [ "$attempts" -ge 30 ]; then
                echo "users-db is not ready" >&2
                exit 1
              fi
              sleep 2
            done

            psql -v ON_ERROR_STOP=1 -X <<'SQL'
            ${local.cluster_admin_bootstrap_sql}
            SQL
            EOT
          ]
        }
      }
    }
  }

  wait_for_completion = true

  depends_on = [
    argocd_application.users_db,
    argocd_application.users,
    module.openfga_authorization,
  ]
}

resource "openfga_relationship_tuple" "cluster_admin" {
  store_id               = module.openfga_authorization.store_id
  authorization_model_id = module.openfga_authorization.model_id
  user                   = "identity:${local.cluster_admin_identity_id}"
  relation               = "admin"
  object                 = "cluster:global"

  depends_on = [
    kubernetes_job_v1.cluster_admin_bootstrap,
  ]
}
