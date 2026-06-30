# Produção do portal-identity (Keycloak) no GCP pessoal — Cloud Run + Cloud SQL + Secret Manager.
#
# ⚠️ ESQUELETO REVISÁVEL — NÃO APLICAR ainda. Detalhes de integração (ex.: SocketFactory do Cloud SQL
#    no Keycloak, hostname, probes) são validados na fatia de deploy, com credenciais. Ver ../README.md.

locals {
  labels = {
    app        = "portal-identity"
    component  = "keycloak"
    managed_by = "terraform"
    env        = "prod"
  }
}

# ---------------------------------------------------------------------------
# APIs necessárias
# ---------------------------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

# ---------------------------------------------------------------------------
# Artifact Registry — onde mora a imagem de prod do Keycloak
# ---------------------------------------------------------------------------
resource "google_artifact_registry_repository" "images" {
  location      = var.region
  repository_id = "portal-identity"
  format        = "DOCKER"
  description   = "Imagens de produção do portal-identity (Keycloak)."
  labels        = local.labels
  depends_on    = [google_project_service.apis]
}

# ---------------------------------------------------------------------------
# Cloud SQL (PostgreSQL) — banco persistente do Keycloak (prod ≠ H2 efêmero do DEV)
# ---------------------------------------------------------------------------
resource "google_sql_database_instance" "kc" {
  name             = "portal-identity-pg"
  database_version = "POSTGRES_16"
  region           = var.region

  settings {
    tier              = var.db_tier
    availability_type = "ZONAL" # subir p/ REGIONAL (HA) quando justificar custo
    disk_autoresize   = true
    disk_size         = 10

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }
    ip_configuration {
      ipv4_enabled = false # sem IP público; acesso só via socket do Cloud SQL connector
    }
    user_labels = local.labels
  }

  deletion_protection = true # evita drop acidental do banco de identidade
  depends_on          = [google_project_service.apis]
}

resource "google_sql_database" "keycloak" {
  name     = "keycloak"
  instance = google_sql_database_instance.kc.name
}

resource "random_password" "db" {
  length  = 32
  special = false # evita problemas de escaping na connection string
}

resource "google_sql_user" "keycloak" {
  name     = "keycloak"
  instance = google_sql_database_instance.kc.name
  password = random_password.db.result
}

# ---------------------------------------------------------------------------
# Secret Manager — senhas (DB + admin bootstrap). Valores NUNCA no git/tfvars.
# ---------------------------------------------------------------------------
resource "google_secret_manager_secret" "db_password" {
  secret_id = "portal-identity-db-password"
  labels    = local.labels
  replication { auto {} }
  depends_on = [google_project_service.apis]
}
resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db.result
}

resource "random_password" "admin" {
  length  = 24
  special = false
}
resource "google_secret_manager_secret" "admin_password" {
  secret_id = "portal-identity-admin-password"
  labels    = local.labels
  replication { auto {} }
  depends_on = [google_project_service.apis]
}
resource "google_secret_manager_secret_version" "admin_password" {
  secret      = google_secret_manager_secret.admin_password.id
  secret_data = random_password.admin.result
}

# ---------------------------------------------------------------------------
# Service Account do Cloud Run — least privilege (lê segredos + conecta no Cloud SQL)
# ---------------------------------------------------------------------------
resource "google_service_account" "kc" {
  account_id   = "portal-identity-run"
  display_name = "portal-identity (Keycloak) Cloud Run"
}

resource "google_project_iam_member" "kc_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.kc.email}"
}

resource "google_secret_manager_secret_iam_member" "kc_db_secret" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.kc.email}"
}
resource "google_secret_manager_secret_iam_member" "kc_admin_secret" {
  secret_id = google_secret_manager_secret.admin_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.kc.email}"
}

# ---------------------------------------------------------------------------
# Cloud Run (v2) — o serviço Keycloak
#   - min=max=1: 1 instância (cache Infinispan simples; evita cold start). Escalar exige config de cache.
#   - Cloud SQL conectado via socket /cloudsql/<conn>; o JDBC usa o SocketFactory do Cloud SQL
#     (a imagem precisa trazer o connector — ver Dockerfile/README).
# ---------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "kc" {
  name     = "portal-identity"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = google_service_account.kc.email
    max_instance_request_concurrency = 80
    scaling {
      min_instance_count = 1
      max_instance_count = 1
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.kc.connection_name]
      }
    }

    containers {
      image = var.keycloak_image
      # Keycloak roda atrás do proxy do Cloud Run (TLS terminado lá): HTTP interno + headers de proxy.
      args = ["start", "--optimized"]

      ports {
        container_port = 8080
      }
      resources {
        limits = {
          cpu    = var.cloud_run_cpu
          memory = var.cloud_run_memory
        }
        cpu_idle = false # Keycloak não pode "dormir" a CPU (sessões/cache)
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name  = "KC_DB"
        value = "postgres"
      }
      # JDBC via SocketFactory do Cloud SQL (sem IP público). Requer o connector na imagem.
      env {
        name  = "KC_DB_URL"
        value = "jdbc:postgresql:///keycloak?cloudSqlInstance=${google_sql_database_instance.kc.connection_name}&socketFactory=com.google.cloud.sql.postgres.SocketFactory"
      }
      env {
        name  = "KC_DB_USERNAME"
        value = google_sql_user.keycloak.name
      }
      env {
        name = "KC_DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "KC_BOOTSTRAP_ADMIN_USERNAME"
        value = "admin"
      }
      env {
        name = "KC_BOOTSTRAP_ADMIN_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.admin_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "KC_PROXY_HEADERS"
        value = "xforwarded"
      }
      env {
        name  = "KC_HTTP_ENABLED"
        value = "true"
      }
      # Hostname público (setar com a URL *.run.app no 1º deploy; domínio próprio depois).
      env {
        name  = "KC_HOSTNAME"
        value = var.keycloak_hostname
      }

      # Keycloak demora a subir → startup probe generoso.
      startup_probe {
        initial_delay_seconds = 20
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 30
        http_get {
          path = "/health/started"
          port = 9000
        }
      }
      liveness_probe {
        http_get {
          path = "/health/live"
          port = 9000
        }
        period_seconds    = 30
        failure_threshold = 5
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_iam_member.kc_db_secret,
    google_secret_manager_secret_iam_member.kc_admin_secret,
    google_project_iam_member.kc_sql_client,
  ]
}

# Acesso público à URL de login (o Keycloak faz sua própria autenticação).
# Se quiser fechar por IAP/allowlist, trocar por binding específico.
resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.kc.name
  location = google_cloud_run_v2_service.kc.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
