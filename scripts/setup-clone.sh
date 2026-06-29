#!/usr/bin/env bash
# Reconstrói o ambiente COMPLETO a partir de um clone do umbrella (polyrepo).
# Clona os services em services/<repo>, restaura os segredos do bundle (gitignored) e
# reativa o guard-rail de segredos (gitleaks). Uso, dentro do clone do umbrella:
#   bash scripts/setup-clone.sh [ORG] [CAMINHO_DO_BUNDLE]
# Defaults: ORG=Garbiati · bundle=~/portal-tecnologia-segredos.local.tar.gz
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORG="${1:-Garbiati}"
BUNDLE="${2:-$HOME/portal-tecnologia-segredos.local.tar.gz}"
cd "$ROOT"

echo "▸ Clonando os services de $ORG…"
mkdir -p services
for r in doctor-hub-api doctor-hub-web portal-identity; do
  if [ -d "services/$r/.git" ]; then
    echo "  – services/$r já existe — pulado"
  else
    git clone "git@github.com:$ORG/$r.git" "services/$r"
  fi
done

echo "▸ Restaurando segredos (gitignored)…"
if [ -f "$BUNDLE" ]; then
  tar xzf "$BUNDLE" -C "$ROOT"
  echo "  ✓ segredos restaurados de $BUNDLE"
else
  echo "  ⚠ bundle não encontrado em $BUNDLE — copie os .env/CREDENCIAIS manualmente"
fi

echo "▸ Reativando o guard-rail de segredos (gitleaks)…"
bash scripts/install-hooks.sh

echo "▸ Instalando deps do front (pnpm install)…"
if command -v pnpm >/dev/null 2>&1 && [ -d services/doctor-hub-web ]; then
  ( cd services/doctor-hub-web && pnpm install )
else
  echo "  ⚠ pnpm ausente ou web não clonado — rode 'pnpm install' em services/doctor-hub-web depois"
fi

echo "✓ Ambiente pronto. Suba:  make up  (Postgres+API+Front)  e  make -C services/portal-identity up  (Keycloak)"
