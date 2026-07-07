#!/usr/bin/env bash
# bootstrap-macos.sh — instala o TOOLCHAIN de dev do portal-tecnologia num Mac novo.
# Não toca em segredos e não clona os services (isso é o setup-clone.sh, que precisa do
# bundle de segredos + chave SSH). Idempotente: pode rodar de novo sem estragar nada.
# Guia completo: ../SETUP-MACOS.md
set -euo pipefail

echo "▶ Portal Tecnologia — bootstrap do toolchain (macOS)"
ARCH="$(uname -m)"; echo "  arquitetura: $ARCH  (arm64 = Apple Silicon; x86_64 = Intel)"

# 1) Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "▶ instalando Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # no Apple Silicon o brew fica em /opt/homebrew — carrega no shell atual:
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2) CLIs (idempotente; '|| true' não aborta se já instalado)
echo "▶ brew install: git gh gitleaks pre-commit node@22 colima docker docker-compose"
brew install git gh gitleaks pre-commit node@22 colima docker docker-compose || true
brew install --cask google-cloud-sdk || true   # opcional (Secret Manager / IdP de prod)

# node@22 é keg-only — garante no PATH
brew link --overwrite --force node@22 2>/dev/null || true

# 3) .NET SDK 10 (global.json exige 10.0.1xx, rollForward latestFeature — estrito)
if ! dotnet --list-sdks 2>/dev/null | grep -q '^10\.0\.'; then
  echo "▶ .NET 10 SDK ausente — tentando via cask…"
  brew install --cask dotnet-sdk || true
  if ! dotnet --list-sdks 2>/dev/null | grep -q '^10\.0\.'; then
    echo "  ⚠ cask não trouxe 10.0.1xx. Use o instalador oficial (ARM64/x64 conforme sua máquina):"
    echo "    https://dotnet.microsoft.com/download/dotnet/10.0"
  fi
fi

# 4) pnpm PINADO (10.28.2, campo packageManager do web) — via corepack, NÃO 'brew install pnpm'
corepack enable
corepack prepare pnpm@10.28.2 --activate

echo "▶ verificação:"
git --version
gitleaks version 2>/dev/null || echo "  ⚠ gitleaks ausente (o pre-commit é fail-closed — instale)"
pre-commit --version
node --version
pnpm --version
dotnet --version 2>/dev/null || echo "  ⚠ dotnet 10 pendente (ver acima)"
colima version 2>/dev/null | head -1 || true

cat <<'NEXT'

✅ Toolchain pronto. Próximos passos (VOCÊ faz — segredos/SSH; ver SETUP-MACOS.md):
  1. Chave SSH no GitHub  →  gh auth login
  2. git clone git@github.com:Garbiati/portal-tecnologia.git ~/portal-tecnologia
  3. Traga o bundle de segredos ~/portal-tecnologia-segredos.local.tar.gz  (AirDrop/scp — NUNCA por git)
  4. cd ~/portal-tecnologia && bash scripts/setup-clone.sh Garbiati ~/portal-tecnologia-segredos.local.tar.gz
  5. Docker: colima start   (LEIA SETUP-MACOS.md §Docker — armadilha do network_mode: host)
  6. make -C services/portal-identity up   &&   make up
  7. Validar: make status ; curl localhost:5092/health ; abrir http://localhost:5173/app/
NEXT
