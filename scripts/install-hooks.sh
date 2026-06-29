#!/usr/bin/env bash
# Instala o guard-rail de segredos (scripts/hooks/pre-commit → gitleaks) no umbrella e em cada
# repo próprio sob services/. Idempotente. Rode após clonar: `bash scripts/install-hooks.sh`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/scripts/hooks/pre-commit"
[ -f "$HOOK" ] || { echo "✗ não achei $HOOK" >&2; exit 1; }

install_into() {
  local repo="$1"
  [ -d "$repo/.git" ] || { printf '  – %s (não é repo git, pulado)\n' "$repo"; return; }
  # Repos que já gerenciam hooks via core.hooksPath versionado (ex.: doctor-hub-web) integram o
  # gitleaks no próprio hook — não sobrescrever com cópia inerte.
  if git -C "$repo" config core.hooksPath >/dev/null 2>&1; then
    printf '  – %s (usa core.hooksPath — gitleaks já no hook versionado, pulado)\n' "$repo"
    return
  fi
  install -m 0755 "$HOOK" "$repo/.git/hooks/pre-commit"
  printf '  \033[32m✓\033[0m %s\n' "$repo"
}

echo "Instalando hook de pre-commit (gitleaks) em:"
install_into "$ROOT"
for s in "$ROOT"/services/*/; do install_into "${s%/}"; done
echo "Pronto. Teste: faça um commit — segredos staged bloqueiam. Escape: SKIP_GITLEAKS=1."
