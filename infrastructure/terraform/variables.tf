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

variable "cloud_run_min_instances" {
  description = "Instâncias mínimas. 0 = liga sob demanda (mais barato; cold start ~15s). 1 = sempre pronto."
  type        = number
  default     = 0
}

variable "keycloak_domain" {
  description = "Domínio próprio do IdP (ex.: id.portaltecnologia.app.br — plataforma). Vazio = usa só a URL *.run.app."
  type        = string
  default     = ""
}

variable "front_base_url" {
  description = "URL base do SITE Doctor-Hub (doctorhub.app.br), usada nos redirect URIs do realm. Front é deployado depois."
  type        = string
  default     = "https://doctorhub.app.br"
}

# --- Doctor-Hub (API .NET + Front React) — deploy no mesmo projeto/LB do IdP ---
variable "deploy_doctor_hub" {
  description = "Liga o deploy do Doctor-Hub (API + Front). Precisa das imagens já no Artifact Registry."
  type        = bool
  default     = false
}
variable "doctor_hub_api_image" {
  description = "Imagem da API .NET (Artifact Registry). Ex.: southamerica-east1-docker.pkg.dev/PROJ/doctor-hub/api:TAG"
  type        = string
  default     = ""
}
variable "doctor_hub_web_image" {
  description = "Imagem do Front (nginx) no Artifact Registry."
  type        = string
  default     = ""
}
variable "api_domain" {
  description = "Domínio próprio da API (plataforma). Ex.: api.portaltecnologia.app.br."
  type        = string
  default     = "api.portaltecnologia.app.br"
}
variable "web_domain" {
  description = "Domínio próprio do site Doctor-Hub. Ex.: doctorhub.app.br."
  type        = string
  default     = "doctorhub.app.br"
}
variable "github_owner" {
  description = "Owner do GitHub dos repos (WIF / CI). Ex.: Garbiati."
  type        = string
  default     = "Garbiati"
}

# --- SMTP (Gmail) — só IDENTIFICADORES aqui; a SENHA é secret manual (ver runbook). ---
variable "smtp_host" {
  type    = string
  default = "smtp.gmail.com"
}
variable "smtp_port" {
  type    = string
  default = "587"
}
variable "smtp_from" {
  description = "Remetente (from). Ex.: nao-responda@doctorhub.app.br."
  type        = string
}
variable "smtp_user" {
  description = "Usuário SMTP. Vazio = usa smtp_from. Para SendGrid use a string literal \"apikey\"."
  type        = string
  default     = ""
}
variable "smtp_from_display" {
  type    = string
  default = "Portal Telemedicina"
}

# --- Twilio (SMS) — SID/remetente aqui; o AUTH TOKEN é secret manual (ver runbook). ---
variable "twilio_account_sid" {
  type    = string
  default = ""
}
variable "twilio_from" {
  description = "Número remetente Twilio em E.164 (ex.: +1555...)."
  type        = string
  default     = ""
}
