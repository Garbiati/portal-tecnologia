# ===========================================================================
# Doctor-Hub — API (.NET) + Front (React/nginx) no Cloud Run, mesmo LB do IdP.
# Tudo condicional a var.deploy_doctor_hub (precisa das imagens no Artifact Registry).
# Banco: reusa a instância Cloud SQL do IdP (google_sql_database_instance.kc) com um
# database + usuário dedicados (isolamento lógico; sem custo de instância nova).
# ===========================================================================

locals {
  idp_url = "https://${var.keycloak_domain}"
}

# --- Artifact Registry (imagens api + web) ---
resource "google_artifact_registry_repository" "doctor_hub" {
  count         = var.deploy_doctor_hub ? 1 : 0
  location      = var.region
  repository_id = "doctor-hub"
  format        = "DOCKER"
  description   = "Imagens do Doctor-Hub (api .NET + web nginx)."
}

# --- Banco dedicado na instância existente ---
resource "google_sql_database" "doctorhub" {
  count    = var.deploy_doctor_hub ? 1 : 0
  name     = "doctorhub"
  instance = google_sql_database_instance.kc.name
}

resource "random_password" "doctorhub_db" {
  count   = var.deploy_doctor_hub ? 1 : 0
  length  = 32
  special = false
}

resource "google_sql_user" "doctorhub" {
  count    = var.deploy_doctor_hub ? 1 : 0
  name     = "doctorhub"
  instance = google_sql_database_instance.kc.name
  password = random_password.doctorhub_db[0].result
}

# Connection string completa (consumida como ConnectionStrings__Postgres). Banco via sidecar proxy
# em localhost:5432 (plaintext local; o proxy faz o TLS até o Cloud SQL).
resource "google_secret_manager_secret" "doctorhub_db" {
  count     = var.deploy_doctor_hub ? 1 : 0
  secret_id = "doctor-hub-db-connection"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "doctorhub_db" {
  count       = var.deploy_doctor_hub ? 1 : 0
  secret      = google_secret_manager_secret.doctorhub_db[0].id
  # Maximum Pool Size limita o pool Npgsql por instância (default seria 100) — evita exaustão do
  # Cloud SQL compartilhado (f1-micro, ~25-50 conexões). Aplicar em JANELA SEGURA (novo secret version
  # + restart da API lê o `latest`). Tuning fino do pool vs. tier do banco = item de escala (🟡, P-010).
  secret_data = "Host=localhost;Port=5432;Database=doctorhub;Username=doctorhub;Password=${random_password.doctorhub_db[0].result};SSL Mode=Disable;Maximum Pool Size=15;Timeout=15"
}

# --- Service Account de runtime (API precisa de Cloud SQL + secrets) ---
resource "google_service_account" "doctor_hub" {
  count        = var.deploy_doctor_hub ? 1 : 0
  account_id   = "doctor-hub-run"
  display_name = "Doctor-Hub (api/web) Cloud Run"
}

resource "google_project_iam_member" "dh_sql_client" {
  count   = var.deploy_doctor_hub ? 1 : 0
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.doctor_hub[0].email}"
}
resource "google_secret_manager_secret_iam_member" "dh_db_secret" {
  count     = var.deploy_doctor_hub ? 1 : 0
  secret_id = google_secret_manager_secret.doctorhub_db[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.doctor_hub[0].email}"
}
# A API administra usuários no Keycloak via service account doctor-hub-admin (reusa o secret do IdP).
resource "google_secret_manager_secret_iam_member" "dh_admin_client_secret" {
  count     = var.deploy_doctor_hub ? 1 : 0
  secret_id = google_secret_manager_secret.admin_client_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.doctor_hub[0].email}"
}

# ---------------------------------------------------------------------------
# Cloud Run — API .NET (+ sidecar Cloud SQL Auth Proxy)
# ---------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "api" {
  count    = var.deploy_doctor_hub ? 1 : 0
  name     = "doctor-hub-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.doctor_hub[0].email
    scaling {
      min_instance_count = var.cloud_run_min_instances
      max_instance_count = 2
    }

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
        limits = { cpu = "1", memory = "512Mi" }
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
      name       = "api"
      image      = var.doctor_hub_api_image
      depends_on = ["cloudsql-proxy"]
      ports {
        container_port = 8080
      }
      resources {
        limits = { cpu = var.cloud_run_cpu, memory = "512Mi" }
      }

      env {
        name = "ConnectionStrings__Postgres"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.doctorhub_db[0].secret_id
            version = "latest"
          }
        }
      }
      # Auth (Keycloak/OIDC) — o IdP já no ar.
      env {
        name  = "Auth__Authority"
        value = "${local.idp_url}/realms/portal"
      }
      env {
        name  = "Auth__MetadataAddress"
        value = "${local.idp_url}/realms/portal/.well-known/openid-configuration"
      }
      env {
        name  = "Auth__Audience"
        value = "doctor-hub-api"
      }
      env {
        name  = "Auth__RequireHttpsMetadata"
        value = "true"
      }
      # Admin de usuários (D-143) via service account doctor-hub-admin.
      env {
        name  = "Keycloak__BaseUrl"
        value = local.idp_url
      }
      env {
        name  = "Keycloak__Realm"
        value = "portal"
      }
      env {
        name  = "Keycloak__AdminClientId"
        value = "doctor-hub-admin"
      }
      env {
        name = "Keycloak__AdminClientSecret"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.admin_client_secret.secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "Keycloak__ManagedClientId"
        value = "doctor-hub-api"
      }
      env {
        name  = "Keycloak__LoginClientId"
        value = "doctor-hub-web"
      }
      env {
        name  = "Keycloak__InviteRedirectUri"
        value = "https://${var.web_domain}/"
      }
      # CORS: só o front.
      env {
        name  = "Cors__AllowedOrigins"
        value = "https://${var.web_domain}"
      }
      # Carga inicial dos doutores demo (D-133) enquanto a sync da Teleconsulta não entra.
      env {
        name  = "Seed__Doctors"
        value = "true"
      }

      startup_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 30
      }
      liveness_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        period_seconds    = 30
        failure_threshold = 5
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_iam_member.dh_db_secret,
    google_secret_manager_secret_iam_member.dh_admin_client_secret,
    google_project_iam_member.dh_sql_client,
  ]

  # O CI (GitHub Actions) atualiza a imagem via `gcloud run deploy`. O terraform não deve reverter.
  lifecycle {
    ignore_changes = [template[0].containers[1].image]
  }
}

# ---------------------------------------------------------------------------
# Cloud Run — Front (nginx servindo o SPA)
# ---------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "web" {
  count    = var.deploy_doctor_hub ? 1 : 0
  name     = "doctor-hub-web"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.doctor_hub[0].email
    scaling {
      min_instance_count = var.cloud_run_min_instances
      max_instance_count = 2
    }
    containers {
      name  = "web"
      image = var.doctor_hub_web_image
      ports {
        container_port = 8080
      }
      resources {
        limits   = { cpu = "1", memory = "256Mi" }
        cpu_idle = true # nginx só precisa de CPU por request → mais barato e permite 256Mi
      }
      startup_probe {
        http_get {
          path = "/"
          port = 8080
        }
        initial_delay_seconds = 3
        timeout_seconds       = 3
        period_seconds        = 5
        failure_threshold     = 10
      }
    }
  }

  depends_on = [google_project_service.apis]

  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }
}

# --- Acesso público (a API se protege por JWT; o front é estático público) ---
resource "google_cloud_run_v2_service_iam_member" "api_public" {
  count    = var.deploy_doctor_hub ? 1 : 0
  name     = google_cloud_run_v2_service.api[0].name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
resource "google_cloud_run_v2_service_iam_member" "web_public" {
  count    = var.deploy_doctor_hub ? 1 : 0
  name     = google_cloud_run_v2_service.web[0].name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# --- NEGs + backends (entram no LB via host rules no url_map do main.tf) ---
resource "google_compute_region_network_endpoint_group" "api" {
  count                 = var.deploy_doctor_hub ? 1 : 0
  name                  = "doctor-hub-api-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.api[0].name
  }
}
resource "google_compute_region_network_endpoint_group" "web" {
  count                 = var.deploy_doctor_hub ? 1 : 0
  name                  = "doctor-hub-web-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.web[0].name
  }
}
resource "google_compute_backend_service" "api" {
  count                 = var.deploy_doctor_hub ? 1 : 0
  name                  = "doctor-hub-api-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"
  backend {
    group = google_compute_region_network_endpoint_group.api[0].id
  }
}
resource "google_compute_backend_service" "web" {
  count                 = var.deploy_doctor_hub ? 1 : 0
  name                  = "doctor-hub-web-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"
  backend {
    group = google_compute_region_network_endpoint_group.web[0].id
  }
}

# --- Certs gerenciados (separados p/ não reprovisionar o cert do id.) ---
resource "google_compute_managed_ssl_certificate" "api" {
  count = var.deploy_doctor_hub ? 1 : 0
  name  = "doctor-hub-api-cert"
  managed {
    domains = [var.api_domain]
  }
}
resource "google_compute_managed_ssl_certificate" "web" {
  count = var.deploy_doctor_hub ? 1 : 0
  name  = "doctor-hub-web-cert"
  managed {
    domains = [var.web_domain]
  }
}
