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
    "compute.googleapis.com",        # Load Balancer p/ o domínio próprio (domain mapping não existe em SP)
    "sts.googleapis.com",            # Workload Identity Federation (CI keyless)
    "iamcredentials.googleapis.com", # impersonação da SA de deploy
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
    edition           = "ENTERPRISE" # permite os tiers shared-core baratos (db-f1-micro); ENTERPRISE_PLUS não
    tier              = var.db_tier
    availability_type = "ZONAL" # subir p/ REGIONAL (HA) quando justificar custo
    disk_autoresize   = true
    disk_size         = 10

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }
    ip_configuration {
      # IP público habilitado, mas SEM redes autorizadas → só o Cloud SQL Auth Proxy (connector, via IAM)
      # consegue conectar; não há acesso "raw" pela internet.
      ipv4_enabled = true
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
# Cloud Run (v2) — o serviço Keycloak + sidecar Cloud SQL Auth Proxy
#   - min configurável (0 = sob demanda, mais barato); max=1 (cache Infinispan simples).
#   - O banco é acessado via SIDECAR (cloud-sql-proxy) em localhost:5432 → driver Postgres padrão
#     do Keycloak (sem jar extra). O proxy conecta no Cloud SQL pelo connector (IAM).
# ---------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "kc" {
  name     = "portal-identity"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = google_service_account.kc.email
    max_instance_request_concurrency = 80
    scaling {
      min_instance_count = var.cloud_run_min_instances
      max_instance_count = 1
    }

    # Sidecar: Cloud SQL Auth Proxy. Expõe o banco em localhost:5432 dentro da instância.
    containers {
      name  = "cloudsql-proxy"
      image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.14.1"
      args = [
        "--port=5432",
        "--http-address=0.0.0.0",
        "--http-port=9090",
        "--health-check",
        google_sql_database_instance.kc.connection_name,
      ]
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
      startup_probe {
        http_get {
          path = "/startup"
          port = 9090
        }
        initial_delay_seconds = 5
        timeout_seconds       = 5
        period_seconds        = 5
        failure_threshold     = 20
      }
    }

    containers {
      name       = "keycloak"
      image      = var.keycloak_image
      depends_on = ["cloudsql-proxy"] # só sobe o Keycloak depois do proxy pronto
      args       = ["start", "--optimized"]

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

      env {
        name  = "KC_DB"
        value = "postgres"
      }
      # Banco via sidecar (proxy) em localhost:5432 — driver Postgres padrão, sem jar extra.
      env {
        name  = "KC_DB_URL"
        value = "jdbc:postgresql://localhost:5432/keycloak"
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
        value = coalesce(var.smtp_user, var.smtp_from)
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

# ---------------------------------------------------------------------------
# Domínio próprio via LOAD BALANCER HTTPS global + cert gerenciado.
# (O domain mapping simples do Cloud Run NÃO existe em southamerica-east1 → erro 501.)
# DNS: aponte `id.portaltecnologia.app.br` (registro A) para o IP global (output `idp_ip`) no
# registro.br. O certificado gerenciado provisiona sozinho depois que o DNS resolver para o IP.
# ---------------------------------------------------------------------------
resource "google_compute_global_address" "kc" {
  count = var.keycloak_domain == "" ? 0 : 1
  name  = "portal-identity-ip"
}

resource "google_compute_region_network_endpoint_group" "kc" {
  count                 = var.keycloak_domain == "" ? 0 : 1
  name                  = "portal-identity-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.kc.name
  }
}

resource "google_compute_backend_service" "kc" {
  count                 = var.keycloak_domain == "" ? 0 : 1
  name                  = "portal-identity-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"
  backend {
    group = google_compute_region_network_endpoint_group.kc[0].id
  }
}

resource "google_compute_url_map" "kc" {
  count = var.keycloak_domain == "" ? 0 : 1
  name  = "portal-identity-urlmap"
  # Sem Doctor-Hub: tudo cai no IdP. Com Doctor-Hub: roteia por host (id./api./doctorhub).
  default_service = var.deploy_doctor_hub ? google_compute_backend_service.web[0].id : google_compute_backend_service.kc[0].id

  dynamic "host_rule" {
    for_each = var.deploy_doctor_hub ? [1] : []
    content {
      hosts        = [var.keycloak_domain]
      path_matcher = "idp"
    }
  }
  dynamic "host_rule" {
    for_each = var.deploy_doctor_hub ? [1] : []
    content {
      hosts        = [var.api_domain]
      path_matcher = "api"
    }
  }
  dynamic "host_rule" {
    for_each = var.deploy_doctor_hub ? [1] : []
    content {
      hosts        = [var.web_domain]
      path_matcher = "web"
    }
  }
  dynamic "path_matcher" {
    for_each = var.deploy_doctor_hub ? [1] : []
    content {
      name            = "idp"
      default_service = google_compute_backend_service.kc[0].id
    }
  }
  dynamic "path_matcher" {
    for_each = var.deploy_doctor_hub ? [1] : []
    content {
      name            = "api"
      default_service = google_compute_backend_service.api[0].id
    }
  }
  dynamic "path_matcher" {
    for_each = var.deploy_doctor_hub ? [1] : []
    content {
      name            = "web"
      default_service = google_compute_backend_service.web[0].id
    }
  }
}

resource "google_compute_managed_ssl_certificate" "kc" {
  count = var.keycloak_domain == "" ? 0 : 1
  name  = "portal-identity-cert"
  managed {
    domains = [var.keycloak_domain]
  }
}

resource "google_compute_target_https_proxy" "kc" {
  count   = var.keycloak_domain == "" ? 0 : 1
  name    = "portal-identity-https-proxy"
  url_map = google_compute_url_map.kc[0].id
  # cert do id. sempre; + api./doctorhub. quando o Doctor-Hub está ligado (multi-cert por SNI).
  ssl_certificates = concat(
    [google_compute_managed_ssl_certificate.kc[0].id],
    var.deploy_doctor_hub ? [
      google_compute_managed_ssl_certificate.api[0].id,
      google_compute_managed_ssl_certificate.web[0].id,
    ] : []
  )
}

resource "google_compute_global_forwarding_rule" "kc" {
  count                 = var.keycloak_domain == "" ? 0 : 1
  name                  = "portal-identity-fr"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_https_proxy.kc[0].id
  ip_address            = google_compute_global_address.kc[0].id
  port_range            = "443"
}
