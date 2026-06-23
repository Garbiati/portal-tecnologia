---
title: Backlog de Specs (Mapa de Produto)
status: draft
date: 2026-06-14
gerado_por: rascunho automático (a validar com Alessandro)
---

# Backlog de Specs — Mapa de Produto

> Derivado 100% da descoberta validada (`docs/discovery/`, `docs/decisions/`). Cada épico vira
> uma ou mais specs em `specs/<slug>/`. **Tamanhos** usam buckets de horas-ideais (1 dev + IA,
> incluindo spec + teste + código + revisão): XS=4h · S=8h · M=16h · L=32h · XL=60h.
> "Horas-ideais" = trabalho focado, sem reuniões/contexto-switch (o multiplicador real entra na estimativa).

## Épico A — Acesso & RBAC
| Feature | Tam. | Notas |
|---|---|---|
| Autenticação (login, sessão, recuperação) | M | Só Admin/Demandas, Solicitante, Gestor logam (D-010) |
| Modelo de papéis & permissões (RBAC) | M | D-008 |
| Cadastro de usuários + escopo (estado/unidade) | M | SPEC-001; Admin cria Solicitante/Gestor |
| Isolamento de dados por escopo | M | Solicitante=estado, Gestor=unidade |
| Trilha de auditoria (LGPD) | S | Quem fez o quê, quando |
**Subtotal A ≈ 72h**

## Épico B — Cadastro de Médicos & Escala (+ motor de Estoque)
| Feature | Tam. | Notas |
|---|---|---|
| CRUD de médico | S | Doutor é dado, não usuário (D-010) |
| Modelo de escala fixa | M | dias, horário, período válido, consultas/hora, ativo |
| Motor de derivação escala → capacidade (estoque) | L | ⚠️ depende da granularidade (pergunta aberta) |
| Ajuste manual de estoque (retornos/extras) + auditoria | M | D-005 |
| Especialidades (cadastro + mapeamento p/ TC) | S | casar com `internal_specialization_id` |
**Subtotal B ≈ 80h**

## Épico C — Cobertura (mapa) — *candidato a Fase 2*
| Feature | Tam. | Notas |
|---|---|---|
| Mapa de cobertura (especialidade/médico/dia) | M | |
| Exportação tipo "PDF Modelo" | S | pedir o modelo ao Alessandro |
**Subtotal C ≈ 24h**

## Épico D — Solicitação (Demanda)
| Feature | Tam. | Notas |
|---|---|---|
| CRUD de solicitação (especialidades × qtd × mês, por HC) | M | aberta pelo Secretário (Solicitante) |
| Validações + estados (rascunho/enviada) | S | |
| Visão do Solicitante (escopo estadual) | S | |
**Subtotal D ≈ 32h**

## Épico E — Disponibilização (núcleo do sistema)
| Feature | Tam. | Notas |
|---|---|---|
| Dashboard estoque × demanda | L | a visão mais rica |
| Visões (macro, por Governo, contratação) | M | |
| Colunas de saldo (solicitado/disponibilizar/extras/saldo) | M | |
| Máquina de estados Simular / Limpar / Reservar / Emitir | L | coração da alocação |
| Lógica de saldo & flag "vagas > 30 dias" | M | |
**Subtotal E ≈ 112h**

## Épico F — Assunção & Agendamento
| Feature | Tam. | Notas |
|---|---|---|
| Tela de assunção do Gestor (slots da unidade) | M | D-009 |
| Seleção de paciente (lista vinda da TC por HC) | M | D-012 |
| Lógica do médico preferencial (retorno/escolha) | M | D-011 |
| Composição do agendamento | S | médico+paciente+especialidade+HC |
**Subtotal F ≈ 56h**

## Épico G — Remanejamento
| Feature | Tam. | Notas |
|---|---|---|
| Janela configurável (24/48h) | S | D-013 |
| Identificação de slots não assumidos | S | |
| Critério "demanda não atendida" + redistribuição | M | manual na v1 |
| Relatório de slots livres | S | |
**Subtotal G ≈ 40h**

## Épico H — Integração Teleconsulta
| Feature | Tam. | Notas |
|---|---|---|
| Cliente da API de parceiro (auth `X-API-KEY`) | S | D-002 |
| Lookup de paciente (por HC e por CPF/CNS) | S | |
| `POST /integration/appointment` + idempotência (`external_id`) | M | |
| Mapeamento de especialidades + tratamento 409/404 (retry) | M | |
| Setup de PartnerType/API-key com o time da TC + homologação | M | dependência externa (time TC) |
**Subtotal H ≈ 64h**

## Épico J — Fundação / Plataforma
| Feature | Tam. | Notas |
|---|---|---|
| Scaffold + setup (após escolher stack — gate Fase 2) | M | |
| Infra de autenticação | S | |
| Banco de dados + migrations | M | |
| CI/CD + ambientes (homolog/prod) | M | |
| Baseline de segurança (gitleaks/trufflehog/least-privilege) | M | inegociável (healthcare) |
| Harness SDD/TDD (hooks, skills) + portal de docs | M | já parcialmente feito |
**Subtotal J ≈ 88h**

## Épico K — Não-funcionais & Hardening
| Feature | Tam. | Notas |
|---|---|---|
| LGPD (base legal, retenção, auditoria consolidada) | M | paciente vem da TC, reduz exposição (D-012) |
| Observabilidade / logs / telemetria | S | |
| Hardening de segurança + revisão | M | |
| Performance / dimensionamento básico | S | |
**Subtotal K ≈ 48h**

## Cross-cutting
| Item | Horas |
|---|---|
| QA / E2E / suporte a UAT (além do TDD por feature) | 48h |
| Gestão / gates semanais / documentação viva | 40h |

---

## Totais (horas-ideais, caso provável)
| Bloco | Horas |
|---|---|
| A Acesso & RBAC | 72 |
| B Médicos & Escala (+Estoque) | 80 |
| C Cobertura *(Fase 2)* | 24 |
| D Solicitação | 32 |
| E Disponibilização | 112 |
| F Assunção & Agendamento | 56 |
| G Remanejamento | 40 |
| H Integração TC | 64 |
| J Fundação/Plataforma | 88 |
| K Não-funcionais | 48 |
| QA cross-cutting | 48 |
| Gestão/gates | 40 |
| **TOTAL (escopo completo)** | **≈ 704h** |

> A conversão para prazo/custo e os cortes de escopo (tiers) estão em `03-estimativa-esforco.md`
> e `02-scope-entrega-1.md`. As horas-ideais ainda recebem um multiplicador de realidade na estimativa.
