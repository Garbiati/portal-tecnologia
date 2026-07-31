#!/usr/bin/env bash
# Sobe os commits locais dos repos da plataforma para o `origin` (branch atual).
# Existe para o Alessandro trabalhar REMOTO: um comando só, liberado na allowlist
# (.claude/settings.local.json), em vez de liberar `git` inteiro para o agente.
#
# Seguro por construção: só `git push` simples — nunca --force, nunca reset/clean.
# Push só acontece onde há commit à frente do upstream; o resto é relatado e pulado.
#
# Uso:  ./scripts/push-repos.sh            (todos os repos conhecidos)
#       ./scripts/push-repos.sh api web    (só os apelidos indicados)
set -uo pipefail
cd "$(dirname "$0")/.."
RAIZ="$PWD"

# apelido:caminho
REPOS=(
  "umbrella:."
  "api:services/doctor-hub-api"
  "web:services/doctor-hub-web"
  "identity:services/portal-identity"
)

# --sem-gate: pula o hook de pre-push (gate de review P-019). SÓ com autorização explícita do
# Alessandro, e depois de os achados terem sido julgados um a um — o gate já pegou bug real.
SEM_GATE=0
args=()
for a in "$@"; do
  if [ "$a" = "--sem-gate" ]; then SEM_GATE=1; else args+=("$a"); fi
done
set -- ${args[@]+"${args[@]}"}

alvos=("$@")
falhou=0
[ $SEM_GATE -eq 1 ] && echo "⚠ --sem-gate: hook de review PULADO (autorizado pelo Alessandro)."

for entrada in "${REPOS[@]}"; do
  apelido="${entrada%%:*}"
  caminho="${entrada#*:}"

  if [ ${#alvos[@]} -gt 0 ]; then
    quer=0
    for a in "${alvos[@]}"; do [ "$a" = "$apelido" ] && quer=1; done
    [ $quer -eq 1 ] || continue
  fi

  dir="$RAIZ/$caminho"
  if [ ! -d "$dir/.git" ]; then
    printf '· %-9s — sem repo git em %s (pulado)\n' "$apelido" "$caminho"
    continue
  fi

  branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD)
  if ! git -C "$dir" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    printf '· %-9s — branch %s sem upstream (pulado)\n' "$apelido" "$branch"
    continue
  fi

  pendentes=$(git -C "$dir" rev-list --count '@{u}..HEAD')
  if [ "$pendentes" -eq 0 ]; then
    printf '· %-9s — nada a enviar (%s em dia)\n' "$apelido" "$branch"
    continue
  fi

  printf '→ %-9s — enviando %s commit(s) de %s…\n' "$apelido" "$pendentes" "$branch"
  verify=()
  [ $SEM_GATE -eq 1 ] && verify=(--no-verify)
  if git -C "$dir" push ${verify[@]+"${verify[@]}"} origin "$branch"; then
    printf '✓ %-9s — %s commit(s) no origin/%s\n' "$apelido" "$pendentes" "$branch"
  else
    printf '✗ %-9s — FALHOU o push de %s\n' "$apelido" "$branch"
    falhou=1
  fi
done

exit $falhou
