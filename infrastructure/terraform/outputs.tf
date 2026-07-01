output "keycloak_url" {
  description = "URL pública do Keycloak (Cloud Run). Use-a como KC_HOSTNAME no 1º deploy."
  value       = google_cloud_run_v2_service.kc.uri
}

output "sql_connection_name" {
  description = "Instance connection name do Cloud SQL (PROJECT:REGION:INSTANCE)."
  value       = google_sql_database_instance.kc.connection_name
}

output "artifact_registry_repo" {
  description = "Caminho do repositório de imagens (push da imagem do Keycloak aqui)."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}

output "admin_password_secret" {
  description = "Nome do secret com a senha do admin bootstrap (leia via gcloud secrets versions access)."
  value       = google_secret_manager_secret.admin_password.secret_id
}

output "idp_ip" {
  description = "IP global do Load Balancer — cadastre um registro A `id` → este IP no registro.br."
  value       = var.keycloak_domain == "" ? "" : google_compute_global_address.kc[0].address
}

output "idp_url" {
  description = "URL final do IdP (domínio próprio se configurado; senão a *.run.app)."
  value       = var.keycloak_domain != "" ? "https://${var.keycloak_domain}" : google_cloud_run_v2_service.kc.uri
}

# --- Doctor-Hub ---
output "doctor_hub_api_run_url" {
  description = "URL *.run.app da API (antes do domínio api. propagar)."
  value       = var.deploy_doctor_hub ? google_cloud_run_v2_service.api[0].uri : ""
}
output "doctor_hub_web_run_url" {
  description = "URL *.run.app do front (antes do domínio doctorhub. propagar)."
  value       = var.deploy_doctor_hub ? google_cloud_run_v2_service.web[0].uri : ""
}
output "doctor_hub_ar_repo" {
  description = "Repositório Artifact Registry das imagens do Doctor-Hub."
  value       = var.deploy_doctor_hub ? "${var.region}-docker.pkg.dev/${var.project_id}/doctor-hub" : ""
}
output "github_wif_provider" {
  description = "Nome completo do WIF provider (usar em google-github-actions/auth workload_identity_provider)."
  value       = var.deploy_doctor_hub ? google_iam_workload_identity_pool_provider.github[0].name : ""
}
output "github_deployer_sa" {
  description = "E-mail da service account de deploy (usar em service_account do auth do GH Actions)."
  value       = var.deploy_doctor_hub ? google_service_account.github_deployer[0].email : ""
}
