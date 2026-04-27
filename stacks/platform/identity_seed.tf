# Seed the synthetic cluster-admin identity in the identity registry.
#
# Why: bootstrap seeds OpenFGA tuples for the cluster-admin identity, but the
# identity service also enforces that identities are registered before certain
# operations (e.g., Organizations.CreateMembership).
#
# This job is safe to re-run (UPSERT) and waits for the identities table to
# exist (identity runs migrations asynchronously after deployment).

resource "kubernetes_job_v1" "seed_cluster_admin_identity" {
  metadata {
    name      = "seed-cluster-admin-identity"
    namespace = kubernetes_namespace.platform.metadata[0].name

    labels = {
      "app.kubernetes.io/name" = "seed-cluster-admin-identity"
    }
  }

  spec {
    backoff_limit = 1

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "seed-cluster-admin-identity"
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name  = "psql"
          image = "public.ecr.aws/docker/library/postgres:16"

          env {
            name  = "PGPASSWORD"
            value = var.identity_db_password
          }

          # NOTE: identity_type here is the identity-db enum value (not the proto enum).
          # user=1, agent=2, runner=4, app=5.
          env {
            name  = "CLUSTER_ADMIN_IDENTITY_ID"
            value = local.cluster_admin_identity_id
          }

          env {
            name  = "CLUSTER_ADMIN_IDENTITY_TYPE"
            value = "1"
          }

          command = ["/bin/sh", "-c"]

          args = [<<-EOT
            set -euo pipefail

            identity_id="$CLUSTER_ADMIN_IDENTITY_ID"
            identity_type="$CLUSTER_ADMIN_IDENTITY_TYPE"

            echo "Waiting for identity-db to accept connections..."
            for i in $(seq 1 60); do
              if pg_isready -h identity-db -U identity -d identity >/dev/null 2>&1; then
                break
              fi
              echo "waiting for identity-db... ($i/60)"
              sleep 5
            done

            echo "Waiting for identities table (identity migrations)..."
            table_ready=0
            for i in $(seq 1 60); do
              table_name=$(psql -h identity-db -U identity -d identity -tAc \
                "SELECT to_regclass('public.identities');" || true)

              if [ "$table_name" = "identities" ]; then
                table_ready=1
                break
              fi

              echo "waiting for identities table... ($i/60)"
              sleep 5
            done

            if [ "$table_ready" -ne 1 ]; then
              echo "ERROR: identities table did not become ready" >&2
              exit 1
            fi

            echo "Seeding cluster-admin identity $identity_id (type=$identity_type)"
            psql -h identity-db -U identity -d identity -v ON_ERROR_STOP=1 -c \
              "INSERT INTO identities (identity_id, identity_type) VALUES ('$identity_id', $identity_type) \
               ON CONFLICT (identity_id) DO UPDATE SET identity_type = EXCLUDED.identity_type;"
          EOT
          ]
        }
      }
    }
  }

  depends_on = [
    argocd_application.identity,
  ]
}
