# ===========================================================================
# CI/CD — Workload Identity Federation (GitHub Actions → GCP, SEM chave).
# O GitHub autentica via OIDC; a SA github-deployer só pode ser impersonada
# pelos repos do owner configurado. Deploy = push imagem + gcloud run deploy.
# ===========================================================================

resource "google_iam_workload_identity_pool" "github" {
  count                     = var.deploy_doctor_hub ? 1 : 0
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
  description               = "OIDC dos repos do GitHub p/ deploy (keyless)."
}

resource "google_iam_workload_identity_pool_provider" "github" {
  count                              = var.deploy_doctor_hub ? 1 : 0
  workload_identity_pool_id          = google_iam_workload_identity_pool.github[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub OIDC"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.owner"      = "assertion.repository_owner"
  }
  # Só tokens do owner configurado (ex.: Garbiati) podem usar este provider.
  attribute_condition = "assertion.repository_owner == '${var.github_owner}'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service account que o CI impersona para deployar.
resource "google_service_account" "github_deployer" {
  count        = var.deploy_doctor_hub ? 1 : 0
  account_id   = "github-deployer"
  display_name = "GitHub Actions deployer (Doctor-Hub CI/CD)"
}

# Permissões do deployer: publicar imagem + deployar Cloud Run + actAs a SA de runtime.
resource "google_project_iam_member" "deployer_run_admin" {
  count   = var.deploy_doctor_hub ? 1 : 0
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.github_deployer[0].email}"
}
resource "google_project_iam_member" "deployer_ar_writer" {
  count   = var.deploy_doctor_hub ? 1 : 0
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_deployer[0].email}"
}
# Necessário p/ o `gcloud run deploy` rodar o serviço como a SA de runtime (doctor-hub-run).
resource "google_service_account_iam_member" "deployer_actas_runtime" {
  count              = var.deploy_doctor_hub ? 1 : 0
  service_account_id = google_service_account.doctor_hub[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_deployer[0].email}"
}

# Liga cada repo do GitHub à SA de deploy (impersonação via WIF).
resource "google_service_account_iam_member" "deployer_wif_bind" {
  for_each           = var.deploy_doctor_hub ? toset(["doctor-hub-api", "doctor-hub-web"]) : []
  service_account_id = google_service_account.github_deployer[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github[0].name}/attribute.repository/${var.github_owner}/${each.value}"
}
