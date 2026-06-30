# Versões e backend do Terraform.
#
# ⚠️ ESQUELETO — NÃO APLICAR sem a fatia de deploy aprovada (ver ../README.md).
#
# Backend: comece LOCAL e migre para GCS assim que o bucket existir. O state contém segredos
# (ex.: senha do Cloud SQL gerada pelo random_password) → o bucket precisa ser PRIVADO e versionado,
# e o tfstate local NUNCA vai para o git (ver .gitignore).
terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Descomente quando o bucket existir (ver README, passo "state remoto"):
  # backend "gcs" {
  #   bucket = "portal-tecnologia-tfstate"   # bucket PRIVADO + versionado no projeto pessoal
  #   prefix = "portal-identity/prod"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
