## ptm-platform — entry point. `make help` lista os alvos.
API_DIR := services/doctor-hub-api
WEB_DIR := services/doctor-hub-web

.DEFAULT_GOAL := help
.PHONY: help api web db down install test test-api test-web build-web

help: ## Lista os alvos
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

db: ## Sobe o Postgres local (docker compose)
	cd $(API_DIR) && docker compose up -d db

down: ## Derruba o Postgres local
	cd $(API_DIR) && docker compose down

api: ## Roda a API .NET (http://localhost:5000/health)
	cd $(API_DIR) && dotnet run --project src/DoctorHub.Api

install: ## Instala deps do front
	cd $(WEB_DIR) && pnpm install

web: ## Roda o front Vite (http://localhost:5173)
	cd $(WEB_DIR) && pnpm dev

build-web: ## Build de produção do front (gera o PWA)
	cd $(WEB_DIR) && pnpm build

test: test-api test-web ## Roda os testes dos dois services

test-api: ## Testes da API (xUnit)
	cd $(API_DIR) && dotnet test

test-web: ## Testes do front (Vitest)
	cd $(WEB_DIR) && pnpm test
