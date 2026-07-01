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
