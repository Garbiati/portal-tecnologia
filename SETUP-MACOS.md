# Setup do ambiente de DEV no macOS

Guia para reproduzir o ambiente de desenvolvimento do **portal-tecnologia** num Mac novo
(Apple Silicon ou Intel). O umbrella + os 3 `services/` (doctor-hub-api, doctor-hub-web,
portal-identity) rodam 100% local (Postgres + Keycloak em Docker; sem GCP para o loop de dev).

> **O que é seu (nunca passa por mim/git):** os segredos. Traga o bundle
> `~/portal-tecnologia-segredos.local.tar.gz` do Linux por AirDrop/scp/pendrive. Ele contém os
> `.env`, o `doctors-demo.json` (CPFs reais — LGPD) e `CREDENCIAIS-DEV.txt`.

---

## 0) Duas decisões antes de começar
- **Docker:** recomendo **colima** (leve, sem licença) — este guia assume colima. Docker Desktop
  também serve (≥4.34 com *host networking* ligado), mas exige a mesma correção do §Docker.
- **Arquitetura:** `uname -m` → `arm64` (Apple Silicon) usa builds ARM64 do .NET; `x86_64` (Intel) usa x64.

## 1) Toolchain (automatizado)
```bash
# depois de clonar o umbrella (passo 3), ou baixando só este script:
bash scripts/bootstrap-macos.sh
```
Instala via Homebrew: `git gh gitleaks pre-commit node@22 colima docker docker-compose`,
o **.NET SDK 10** (o `global.json` exige **10.0.1xx**; se o cask não trouxer, use o
[instalador oficial](https://dotnet.microsoft.com/download/dotnet/10.0)), e o **pnpm 10.28.2**
via **corepack** (não `brew install pnpm` — a versão é pinada no `package.json`).
`gitleaks` é **obrigatório** no PATH: o pre-commit é *fail-closed* (aborta o commit sem ele).

## 2) GitHub (SSH)
Todas as URLs dos repos são `git@github.com:…` → precisa de chave SSH na máquina nova:
```bash
ssh-keygen -t ed25519 -C "seu-email"      # se ainda não tem
pbcopy < ~/.ssh/id_ed25519.pub            # cola em github.com/settings/keys
gh auth login
```

## 3) Clonar o umbrella + os services
```bash
git clone git@github.com:Garbiati/portal-tecnologia.git ~/portal-tecnologia
cd ~/portal-tecnologia
```
> **Confirme a ORG:** o `setup-clone.sh` usa `Garbiati` por default; o `repos.yml` cita
> `PortalTelemedicina` (renome pendente). Clone da org onde os repos realmente estão.

## 4) Trazer os segredos + rodar o bootstrap dos services
Copie o bundle do Linux (ex.: `scp linux:~/portal-tecnologia-segredos.local.tar.gz ~/`), então:
```bash
bash scripts/setup-clone.sh Garbiati ~/portal-tecnologia-segredos.local.tar.gz
```
Isso: clona `services/{doctor-hub-api,doctor-hub-web,portal-identity}`, restaura os `.env` +
`doctors-demo.json` + `CREDENCIAIS-DEV.txt`, instala os git-hooks e roda `pnpm install` no web.
`cd services/doctor-hub-api && dotnet tool restore` (dotnet-ef — só p/ criar migrations).

**Se o bundle faltar algo**, os `.env` saem dos exemplos (ajuste os valores você):
- `services/doctor-hub-api/.env` ← `.env.example` (`POSTGRES_PASSWORD`, `ConnectionStrings__Postgres` com `Port=5440`, `Seed__Doctors`, `Keycloak__AdminClientSecret`).
- `services/portal-identity/.env` ← `.env.example` (`KEYCLOAK_ADMIN[_PASSWORD]`, `ADMIN_CLIENT_SECRET` **deve bater** com `Keycloak__AdminClientSecret` da API; `SMTP_*`, `TWILIO_*`, `OTP_DEV_LOG_CODE`).
- web: dev não precisa `.env` (usa proxy `/api`→:5092). Só p/ IdP de prod: `.env.local` com `VITE_KEYCLOAK_URL`.

## 5) Docker — ⚠️ a armadilha do `network_mode: host` (a #1 do macOS)
Os dois compose (`services/doctor-hub-api/docker-compose.yml` → Postgres :5440;
`services/portal-identity/docker-compose.yml` → Keycloak :8089/:9000) usam `network_mode: host`,
que **no Mac não expõe no `localhost`** como no Linux (containers rodam numa VM). Sem corrigir,
a API não fala com o Postgres e o front/API não falam com o Keycloak.

**Correção (local, NÃO commitar):** em cada `docker-compose.yml`, troque `network_mode: host`
por publicação de portas — os `command` (`-p 5440`, `--http-port=8089`) continuam iguais:

```yaml
# services/doctor-hub-api/docker-compose.yml  (serviço db)
#   network_mode: host            ← remover
    ports: ["5440:5440"]          ← adicionar
```
```yaml
# services/portal-identity/docker-compose.yml  (serviço keycloak)
#   network_mode: host            ← remover
    ports: ["8089:8089", "9000:9000"]   ← adicionar
```
Como os compose são versionados, deixe essa edição **local** (`git update-index --skip-worktree
docker-compose.yml` em cada service p/ não sujar o status). *Se preferir, eu adiciono um
`docker-compose.macos.yml` commitado por service — me avisa.*

```bash
colima start        # sobe a VM do Docker
docker info | head  # confirma o daemon
```

## 6) Subir a stack + validar
```bash
make -C services/portal-identity up   # Keycloak :8089 (buildando o provider via container Maven)
make up                               # Postgres :5440 + API :5092 + Front :5173/app/
make status
curl -s localhost:5092/health         # {"status":"healthy"} (migrations rodam no boot)
open http://localhost:5173/app/       # login com usuário-semente (ver CREDENCIAIS-DEV.txt)
```
Testes: `make test` (`dotnet test` + `pnpm test`). Alvos úteis: `make help`, `make db`, `make api`, `make web`, `make down`.

## 7) pre-commit (guarda de segredos)
```bash
pre-commit install && pre-commit install --hook-type commit-msg
```
`gitleaks` + `.gitleaks.toml` (allowlist dos CPF/CNPJ fictícios de demo) barram vazamento. Fail-closed.

---

## Referências no repo
`README.md` · `HANDOFF.md` (§ credenciais/segredos/bundle) · `repos.yml` · `scripts/setup-clone.sh` ·
`.pre-commit-config.yaml` · `.gitleaks.toml` · READMEs de cada `services/<repo>`.

## Portas locais (resumo)
| Serviço | Porta | URL |
|---|---|---|
| Front (Vite) | 5173 | http://localhost:5173/app/ |
| API (.NET) | 5092 | http://localhost:5092/health |
| Postgres | 5440 | localhost:5440 (db `doctorhub`) |
| Keycloak | 8089 / 9000 | http://localhost:8089/admin |
