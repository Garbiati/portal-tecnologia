## portal-platform — entry point (guarda-chuva da empresa). `make help` lista os alvos.
## Product-aware: `make api` usa PRODUCT=doctor-hub; `make api PRODUCT=<outro>` mira outro produto.
PRODUCT ?= doctor-hub
API_DIR := services/$(PRODUCT)-api
WEB_DIR := services/$(PRODUCT)-web

.DEFAULT_GOAL := help
.PHONY: help catalog workspace up status api web db down install test test-api test-web build-web

help: ## Lista os alvos
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

catalog: ## Mostra o catálogo de repos da empresa (repos.yml)
	@grep -E '^\s+- name:|^\s+url:|^\s+status:' repos.yml | sed 's/^/  /'

workspace: ## Clona/atualiza os repos da empresa (com url) em ./workspace/ (gitignored)
	@bash scripts/workspace.sh

up: ## Sobe a stack inteira (Postgres + API + front) com health-check, em background
	@PRODUCT=$(PRODUCT) bash scripts/up.sh

down: ## Derruba a stack inteira (front + API + Postgres; preserva o volume do banco)
	@PRODUCT=$(PRODUCT) bash scripts/down.sh

status: ## Mostra o estado dos serviços (Postgres/Keycloak/API/front)
	@printf 'Postgres: '; docker inspect -f '{{.State.Health.Status}}' doctorhub-db 2>/dev/null || echo 'fora do ar'
	@printf 'Keycloak: '; curl -fsS -o /dev/null -w 'OK (realm portal · portal-identity)\n' http://localhost:8089/realms/portal/.well-known/openid-configuration 2>/dev/null || echo 'fora do ar (make -C services/portal-identity up)'
	@printf 'API     : '; curl -fsS http://localhost:5092/health 2>/dev/null || echo 'fora do ar'; echo
	@printf 'Front   : '; (grep -oE 'http://localhost:[0-9]+/' $(API_DIR)/.run/web.log 2>/dev/null | head -1) || true; \
		curl -fsS -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:5174/ 2>/dev/null || echo 'fora do ar'

db: ## Sobe SÓ o Postgres local (docker compose)
	cd $(API_DIR) && docker compose up -d db

api: ## Roda a API .NET em foreground (http://localhost:5092/health)
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
