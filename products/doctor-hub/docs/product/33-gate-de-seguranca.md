# Gate de Segurança — "sobe ou não sobe"

> Mandato do Alessandro (2026-07-05): **segurança é o gate central**. Construir com AI-coding só é
> aceitável se a entrega for **segura, à prova de vazamento de secrets/acessos** e sem config default.
> Este doc é o **checklist operacional** + o **modelo de ameaças** + os **controles automáticos**.
> Nada sobe pra produção com um item 🔴 aberto. Fonte dos achados: pentest interno (doc 27 + este).

## 🎯 Modelo de ameaças (as principais — mapeadas ao medo do Alessandro + OWASP API Top 10)
| Ameaça | O que é | Controle |
|---|---|---|
| **Vazamento de secrets** | senha/token/connection-string no git/código/log | gitleaks pre-commit + CI; segredos só em Secret Manager; `.env` gitignored |
| **Vazamento de dados (LGPD)** | CPF/PII/paciente exposto (resposta/log/arquivo) | `doctors-demo.json` gitignored (2 níveis); PII só p/ papel `VeTudo`; paciente só iniciais |
| **Broken authz — horizontal (API1/BOLA)** | ver/mexer dado de OUTRO cliente/unidade | escopo por `clienteId`/`unidade` no backend, fail-closed |
| **Broken authz — vertical (API3/API5)** | papel baixo faz ação de papel alto / escalar p/ super-admin | políticas por endpoint; `super-admin` fora da allowlist de atribuição |
| **Config default / fraca** | admin/admin, sem brute-force, senha fraca, SSL off | senha admin forte (Secret Manager); brute-force ON; passwordPolicy; SSL forçado |
| **Serviço exposto sem auth** | back/serviço interno alcançável sem credencial | API bearer-only (JWT em tudo); Cloud SQL só via proxy+IAM; front público = só UI |
| **Abuso/DoS** | flood em endpoint anônimo, força-bruta no login | rate-limit (inscrições); brute-force do Keycloak no login |
| **Token/sessão** | token roubado dura demais, redirect aberto | PKCE S256; rotação de refresh; redirectUris estreitos; lifetimes |

## ✅ Checklist do gate (tudo verde p/ subir)
**Estáticos (a cada commit/deploy):**
- [ ] gitleaks: **0 leaks** nos 4 repos.
- [ ] Nenhum arquivo com PII real (CPF) trackeado (`doctors-demo.json` e afins gitignored).
- [ ] `pnpm build`/`dotnet build` verdes (inclui `check:ui`).

**Authz (harness ao vivo + testes):**
- [ ] Todo endpoint sensível exige o papel certo (nenhum "só autenticado" onde precisa de papel).
- [ ] Escopo horizontal: papel de um cliente/unidade **não** lê/mexe em outro (403/vazio).
- [ ] PII (CPF/nasc/tel/email) **nula** p/ quem não é admin/demandas.
- [ ] Escalada p/ super-admin **bloqueada** (atribuição rejeita papel fora da allowlist).

**Identidade/infra:**
- [ ] Sem credencial default (admin/admin → 401).
- [ ] Keycloak: brute-force ON, passwordPolicy setada, SSL `external`, PKCE S256, refresh rotation, redirectUris estreitos.
- [ ] Cloud SQL: SSL exigido; sem redes autorizadas públicas; API/serviços exigem JWT.

## 🤖 Controles automáticos
- **gitleaks** (`.gitleaks.toml` + `.pre-commit-config.yaml`) — barra secret no commit; roda no CI.
- **Harness de pentest** (`infrastructure/scripts/homolog-seguranca-e2e.py`) — sobe usuários efêmeros por papel e testa authn/authz/IDOR/PII contra prod; **roda antes de cada release** (e idealmente num job do CI).
- **`check:ui`** no build (DS-first, sem primitivo/hex solto).
- **Smoke** de hora em hora (routine `smoke-doctor-hub`).

## 📍 Status atual (pentest interno 2026-07-05)
**Fechado ✅:** sem default creds · sem secret no git · CPFs reais não vazaram · JWT valida audience/issuer/HTTPS · api bearer-only · PKCE · escalada super-admin bloqueada · Keycloak K1-K4 (brute-force/senha/rotação/redirect) · Cloud SQL SSL forçado.
**Em correção 🔄 (agente, com teste):** F1 PII em `/api/doctors` · F2 indisponibilidades sem papel · F3 unidade na assunção · F4 leituras cross-cliente · F5 mass-assignment · F6 auditoria gravável · F7 rate-limit em `/api/inscricoes`.
**Dívida registrada (baixo risco):** IP público do Cloud SQL (mitigado; desligar exige IP privado+VPC).

## 🔁 Regra operacional
Toda entrega passa pelo checklist. Achado 🔴 = **não sobe** até corrigir. Mudança em authz/identidade
→ rodar o harness. Novo endpoint → definir a política ANTES de expor (default: negar).
