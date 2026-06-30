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
  # Hostname efetivo do Keycloak: domínio próprio (https) tem precedência; senão o que vier em
  # keycloak_hostname (ex.: a URL *.run.app, preenchida após o 1º deploy); senão vazio (strict=false).
  kc_hostname = var.keycloak_domain != "" ? "https://${var.keycloak_domain}" : var.keycloak_hostname
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
  replication {
    auto {}
  }
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
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}
resource "google_secret_manager_secret_version" "admin_password" {
  secret      = google_secret_manager_secret.admin_password.id
  secret_data = random_password.admin.result
}

# Secret do service account doctor-hub-admin (gerado pelo TF; o realm e a futura API leem por nome).
resource "random_password" "admin_client" {
  length  = 40
  special = false
}
resource "google_secret_manager_secret" "admin_client_secret" {
  secret_id = "portal-identity-admin-client-secret"
  labels    = local.labels
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}
resource "google_secret_manager_secret_version" "admin_client_secret" {
  secret      = google_secret_manager_secret.admin_client_secret.id
  secret_data = random_password.admin_client.result
}

# Secrets MANUAIS (valor fora do TF/Git): senha de app do Gmail e auth token do Twilio.
# Criados pelo usuário via gcloud ANTES do apply (ver ../README.md). Aqui só referenciamos p/ o IAM.
resource "google_secret_manager_secret_iam_member" "kc_smtp_secret" {
  secret_id = "portal-identity-smtp-password"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.kc.email}"
}
resource "google_secret_manager_secret_iam_member" "kc_twilio_secret" {
  secret_id = "portal-identity-twilio-token"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.kc.email}"
}
resource "google_secret_manager_secret_iam_member" "kc_admin_client_secret" {
  secret_id = google_secret_manager_secret.admin_client_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.kc.email}"
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
      # Hostname: no 1º deploy a URL *.run.app ainda não é conhecida → strict=false deixa o Keycloak
      # derivar do proxy (X-Forwarded-Host). Depois, opcionalmente, fixe keycloak_hostname e reaplique.
      env {
        name  = "KC_HOSTNAME_STRICT"
        value = "false"
      }
      dynamic "env" {
        for_each = local.kc_hostname == "" ? [] : [local.kc_hostname]
        content {
          name  = "KC_HOSTNAME"
          value = env.value
        }
      }
      env {
        name  = "FRONT_BASE_URL"
        value = var.front_base_url
      }
      # OTP: em produção NUNCA logar o código.
      env {
        name  = "OTP_DEV_LOG_CODE"
        value = "false"
      }

      # SMTP (Gmail) — identificadores por env; senha por secret.
      env {
        name  = "SMTP_HOST"
        value = var.smtp_host
      }
      env {
        name  = "SMTP_PORT"
        value = var.smtp_port
      }
      env {
        name  = "SMTP_FROM"
        value = var.smtp_from
      }
      env {
        name  = "SMTP_FROM_DISPLAY"
        value = var.smtp_from_display
      }
      env {
        name  = "SMTP_USER"
        value = var.smtp_from
      }
      env {
        name  = "SMTP_AUTH"
        value = "true"
      }
      env {
        name  = "SMTP_STARTTLS"
        value = "true"
      }
      env {
        name  = "SMTP_SSL"
        value = "false"
      }
      env {
        name = "SMTP_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = "portal-identity-smtp-password"
            version = "latest"
          }
        }
      }

      # Twilio (SMS) — SID/remetente por env; auth token por secret.
      env {
        name  = "TWILIO_ACCOUNT_SID"
        value = var.twilio_account_sid
      }
      env {
        name  = "TWILIO_FROM"
        value = var.twilio_from
      }
      env {
        name = "TWILIO_AUTH_TOKEN"
        value_source {
          secret_key_ref {
            secret  = "portal-identity-twilio-token"
            version = "latest"
          }
        }
      }

      # Secret do service account doctor-hub-admin (resolve ${ADMIN_CLIENT_SECRET} no import do realm).
      env {
        name = "ADMIN_CLIENT_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.admin_client_secret.secret_id
            version = "latest"
          }
        }
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
    google_secret_manager_secret_iam_member.kc_smtp_secret,
    google_secret_manager_secret_iam_member.kc_twilio_secret,
    google_secret_manager_secret_iam_member.kc_admin_client_secret,
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

# Domínio próprio (ex.: id.portaltecnologia.app.br). Pré-requisito: domínio VERIFICADO no Google
# (Search Console) — ver runbook. O cert TLS é provisionado automaticamente pelo Google.
# Os registros DNS a cadastrar no registrador saem do output `dns_records_dominio`.
resource "google_cloud_run_domain_mapping" "kc" {
  count    = var.keycloak_domain == "" ? 0 : 1
  location = var.region
  name     = var.keycloak_domain

  metadata {
    namespace = var.project_id
  }
  spec {
    route_name = google_cloud_run_v2_service.kc.name
  }
}
