#!/usr/bin/env bash
# workspace.sh — clona/atualiza os repos da empresa listados em repos.yml dentro de ./workspace/
# Polyrepo: cada repo é independente; isto é só uma visão LOCAL de DEV (workspace/ é gitignored).
# Não usa submodules. Pula repos sem `url` confirmada (Diretriz Suprema: não inventar remote).
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
MANIFEST="$ROOT/repos.yml"
[ -f "$MANIFEST" ] || { echo "repos.yml não encontrado"; exit 1; }

# Extrai (name, url, path) do manifest. Usa python3 se houver; senão, parser simples.
parse() {
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$MANIFEST" <<'PY'
import sys, re
name=url=path=local=None
out=[]
def flush():
    if name: out.append((name,url,path,local))
for line in open(sys.argv[1]):
    s=line.strip()
    m=re.match(r'-\s+name:\s*(\S+)', s)
    if m:
        flush()
        name=m.group(1); url=None; path=None; local=None; continue
    m=re.match(r'url:\s*(\S+)', s)
    if m: url=m.group(1)
    m=re.match(r'path:\s*(\S+)', s)
    if m: path=m.group(1)
    m=re.match(r'local:\s*(\S+)', s)
    if m: local=m.group(1)
flush()
for n,u,p,l in out:
    print(f"{n}\t{u}\t{p}\t{l}")
PY
  else
    awk '/-[ ]+name:/{if(n){print n"\t"u"\t"p"\t"l}; n=$3;u="~";p="~";l="~"} /url:/{u=$2} /path:/{p=$2} /local:/{l=$2} END{if(n)print n"\t"u"\t"p"\t"l}' "$MANIFEST"
  fi
}

mkdir -p "$ROOT/workspace"
while IFS=$'\t' read -r name url path local; do
  [ -z "${name:-}" ] && continue
  case "$path" in
    .) continue ;;                          # o próprio guarda-chuva
    services/*) printf '  ⏭  %-18s (código local em %s — não clonar)\n' "$name" "$path"; continue ;;
  esac
  dest="$ROOT/$path"
  # Migração lógica: se o repo já existe na máquina (campo `local:`), symlink em vez de clonar — não duplica.
  if [ -n "${local:-}" ] && [ "$local" != "~" ]; then
    src="$ROOT/$local"
    if [ -d "$src" ]; then
      if [ -L "$dest" ] || [ ! -e "$dest" ]; then
        ln -sfn "$src" "$dest"
        printf '  🔗  %-18s symlink → %s (repo já existe; não clonado)\n' "$name" "$local"
      else
        printf '  ⏭  %-18s (já há diretório real em %s — deixando como está)\n' "$name" "$path"
      fi
      continue
    fi
    printf '  ⚠  %-18s (local: %s não encontrado — caindo p/ url)\n' "$name" "$local"
  fi
  if [ "$url" = "~" ] || [ -z "$url" ]; then
    printf '  ⏭  %-18s (sem url confirmada — pulando)\n' "$name"; continue
  fi
  if [ -d "$dest/.git" ]; then
    printf '  ↻  %-18s pull (%s)\n' "$name" "$path"
    git -C "$dest" pull --ff-only 2>&1 | sed 's/^/        /' || true
  else
    printf '  ⬇  %-18s clone (%s)\n' "$name" "$path"
    git clone "$url" "$dest" 2>&1 | sed 's/^/        /'
  fi
done < <(parse)
echo "workspace pronto (./workspace/ é gitignored)."
