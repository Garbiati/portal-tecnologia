# Variáveis. Valores reais vão em terraform.tfvars (gitignored) — copie de terraform.tfvars.example.
# NUNCA coloque segredo aqui nem no tfvars commitado.

variable "project_id" {
  description = "Projeto GCP PESSOAL (estratégia: construir pessoal → repassar à empresa)."
  type        = string
  # ex.: "portal-tecnologia"
}

variable "region" {
  description = "Região GCP. southamerica-east1 (São Paulo) p/ latência e residência de dados no Brasil (LGPD)."
  type        = string
  default     = "southamerica-east1"
}

variable "keycloak_image" {
  description = "Imagem de prod do Keycloak (Artifact Registry), com providers + tema embutidos e kc.sh build feito."
  type        = string
  # ex.: "southamerica-east1-docker.pkg.dev/portal-tecnologia/portal-identity/keycloak:1.0.0"
}

variable "keycloak_hostname" {
  description = "Hostname público do Keycloak. No 1º deploy use a URL *.run.app gerada (KC_HOSTNAME); domínio próprio é passo posterior."
  type        = string
  default     = "" # vazio = setar depois com a URL do Cloud Run (ver README)
}

variable "db_tier" {
  description = "Tier do Cloud SQL. db-f1-micro (shared, mais barato) p/ começar; subir conforme necessidade."
  type        = string
  default     = "db-f1-micro"
}

variable "cloud_run_cpu" {
  description = "vCPU do Keycloak no Cloud Run."
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Memória do Keycloak (Keycloak/JVM gosta de >=512Mi; 1Gi confortável)."
  type        = string
  default     = "1024Mi"
}
