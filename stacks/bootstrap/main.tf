locals {
  # Deterministic v5 UUID for the cluster admin identity.
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
    INSERT INTO users (identity_id, oidc_subject, name, photo_url)
    VALUES ('${local.cluster_admin_identity_id}', '${local.cluster_admin_oidc_subject}', '${local.cluster_admin_name_sql}', '')
    ON CONFLICT (identity_id) DO NOTHING;

    INSERT INTO user_api_tokens (identity_id, name, token_hash, token_prefix, expires_at)
    VALUES (
      '${local.cluster_admin_identity_id}',
      '${local.cluster_admin_api_token_name_sql}',
      '${local.cluster_admin_api_token_hash}',
      '${local.cluster_admin_api_token_prefix}',
      NULL
    )
    ON CONFLICT (token_hash) DO NOTHING;
  SQL
}

resource "random_string" "cluster_admin_api_token" {
  length  = 44
  lower   = true
  upper   = true
  numeric = true
  special = false
}

resource "sql_migrate" "cluster_admin_bootstrap" {
  migration {
    id   = "insert_cluster_admin_user"
    up   = <<-SQL
      INSERT INTO users (identity_id, oidc_subject, name, photo_url)
      VALUES (
        '${local.cluster_admin_identity_id}',
        '${local.cluster_admin_oidc_subject}',
        '${local.cluster_admin_name_sql}',
        ''
      )
      ON CONFLICT (identity_id) DO NOTHING;
    SQL
    down = <<-SQL
      DELETE FROM users WHERE identity_id = '${local.cluster_admin_identity_id}';
    SQL
  }

  migration {
    id   = "insert_cluster_admin_api_token"
    up   = <<-SQL
      INSERT INTO user_api_tokens (identity_id, name, token_hash, token_prefix, expires_at)
      VALUES (
        '${local.cluster_admin_identity_id}',
        '${local.cluster_admin_api_token_name_sql}',
        '${local.cluster_admin_api_token_hash}',
        '${local.cluster_admin_api_token_prefix}',
        NULL
      )
      ON CONFLICT (token_hash) DO NOTHING;
    SQL
    down = <<-SQL
      DELETE FROM user_api_tokens
      WHERE identity_id = '${local.cluster_admin_identity_id}'
        AND name = '${local.cluster_admin_api_token_name_sql}';
    SQL
  }
}

resource "openfga_relationship_tuple" "cluster_admin" {
  store_id               = local.openfga_store_id
  authorization_model_id = local.openfga_model_id
  user                   = "identity:${local.cluster_admin_identity_id}"
  relation               = "admin"
  object                 = "cluster:global"

  depends_on = [
    sql_migrate.cluster_admin_bootstrap,
  ]
}
