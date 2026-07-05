# Segurança & Gestão de Risco — doc hub

> Resposta à pergunta do Alessandro (2026-07-05): *"não podemos errar em limitações de cada cliente e
> usuário… me preocupa muito a segurança… como eu consigo gerenciar nossos riscos?"* Baseline técnico:
> [`../../../docs/security/security-baseline.md`](../../../../docs/security/security-baseline.md).
> Este doc traduz "gerenciar risco" em: **modelo de ameaças + controles + testes automatizados que
> FALHAM se um limite for violado** (o mesmo espírito do D-153: risco só é gerido quando é testado).

## Como a gente GERENCIA o risco (o processo, não só a lista)
1. **Modelo de ameaças vivo** (abaixo) — o que proteger, de quem, o que não pode acontecer.
2. **Matriz papel × ação × escopo** (D-142) — a fonte da verdade de quem pode o quê. **Você confirma;
   nós não inferimos.** Enquanto não confirmada, o backend fica PERMISSIVO em alguns pontos = risco
   aberto (ver Gaps). Fechá-la é o passo nº1.
3. **Testes NEGATIVOS automatizados** (`homolog-seguranca-e2e.py`) — para cada limite, um teste que
   prova que o proibido **é bloqueado (401/403)**, não só escondido na UI. Roda contra prod/infra
   real. Um limite sem teste negativo = risco não gerido.
4. **Revisão de segurança recorrente** (agente adversarial) a cada mudança de endpoint/tela.
5. **Registro** de cada decisão de segurança (I-xxx/D-xxx) + gaps rastreados até fecharem.

## Modelo de ameaças (STRIDE simplificado)
**Ativos:** dados de médico (CPF — PII) · dados de paciente (só INICIAIS — LGPD) · escalas/capacidade
(valor de negócio) · credenciais/sessões · config do sistema · isolamento entre tenants (P-009).

**Atores:** admin · demandas · regulação · supervisor(gestor) · **usuário mal-intencionado autenticado**
(o mais importante: alguém com login válido tentando exceder seu papel/escopo) · anônimo · tenant vizinho.

| Ameaça | O que NÃO pode acontecer | Controle | Estado |
|---|---|---|---|
| **Elevação de privilégio** (papel excede) | demandas/regulação criar usuário, mudar config, emitir vaga sem permissão | RBAC por endpoint (policy `papel:*`) | ⚠️ PARCIAL — alguns endpoints só exigem "autenticado" (solicitações POST/PATCH, agendamentos) |
| **Acesso horizontal** (cliente A vê cliente B) | Regulação/Supervisor vinculado ao cliente X ler/agir sobre dados do cliente Y | filtro por `clienteId`/`unidade` do token no BACKEND | ⚠️ A VERIFICAR — hoje o escopo é aplicado no front; o backend filtra? (harness vai provar) |
| **Acesso não autenticado** | qualquer dado sem login | FallbackPolicy authenticated + Keycloak | ✅ (GET /clientes deu 401 sem token) |
| **Vazamento de dado sensível** | CPF/paciente em log ou resposta ampla | LGPD: iniciais só; least-privilege | ⚠️ agendamentos GET global expõe iniciais a qualquer autenticado |
| **Multi-tenant** (tenant vizinho) | um tenant acessar dados de outro | stack-por-tenant (P-009): DB/realm isolados | ✅ por isolamento físico (enquanto stack-por-tenant) |
| **Segredo exposto** | senha/token no código/git | Secret Manager + gitleaks + WIF keyless | ✅ (baseline) |
| **Repúdio** (quem fez?) | ação sem rastro | auditoria (quem/quando/ação) | ⚠️ cobre parte — exclusões admin auditadas; estender |

## Gaps abertos = risco a fechar (rastreados)
- **G-1 [ALTO] Escopo horizontal no backend:** confirmar/implementar que Regulação/Supervisor só
  acessam dados do seu cliente/unidade **na API** (não só na UI). Um usuário chamando a API direto
  não pode ler outro cliente. → harness negativo prova o estado atual; correção depende da matriz D-142.
- **G-2 [MÉDIO] RBAC por papel** em solicitações (POST/PATCH) e agendamentos — hoje "autenticado"
  basta. → D-142.
- **G-3 [MÉDIO] agendamentos GET global** sem filtro por unidade expõe iniciais de paciente a
  qualquer autenticado. → escopo por unidade + LGPD.
- **G-4 [BAIXO] auditoria** não cobre todas as ações sensíveis (criação/edição). → estender.

## Decisão que destrava tudo (você): a MATRIZ D-142
Preciso que você confirme, por papel, **o que pode fazer** e **sobre qual escopo**. Proposta de
ponto de partida (NÃO implementada — só p/ você editar):

| Papel | Cria/edita usuários | Cria/edita clientes | Cria escala | Cria solicitação | Dá "de acordo" | Emite/assume vaga | Escopo de dados |
|---|---|---|---|---|---|---|---|
| **Admin** | ✅ | ✅ | ✅ | — | — | — | tudo (do tenant) |
| **Demandas** | — | — | ✅ | — | — | disponibiliza | tudo (do tenant) |
| **Regulação** | — | — | — | ✅ | — | — | **só seu cliente** |
| **Supervisor** | — | — | — | — | ✅ | assume | **só sua unidade** |

Confirme/ajuste e vira regra + testes negativos que travam qualquer violação.

## Como isso "some com o bug de 2 minutos"
O bug que você pega em 2 min de uso é quase sempre (a) dado que não persiste [→ harness E2E D-153] ou
(b) limite que não é aplicado [→ harness NEGATIVO de segurança]. Com os dois rodando por tela contra a
infra real, "pronto" passa a significar **funciona E respeita os limites** — provado, não prometido.
