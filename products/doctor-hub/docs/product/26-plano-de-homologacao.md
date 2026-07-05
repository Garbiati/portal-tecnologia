# Plano de Homologação — doc hub (living)

> Roteiro que o Alessandro segue MANUALMENTE (offline) + o mapa dos **harnesses E2E** (D-153) que
> automatizam cada passo. Regra: quando um passo é validado à mão, vira teste automatizado que roda
> contra a infra real (`infrastructure/scripts/homolog-*-e2e.py`). Fonte: descrição do Alessandro
> (2026-07-05) + casos que completam um sistema de gestão médica. **Não se limita a estes passos.**
>
> **Foco do produto (confirmado):** cadastro/importação de médicos · gestão de escalas ·
> previsibilidade da capacidade médica · distribuição de vagas p/ agendamento a partir das
> solicitações dos clientes. Agendamento **não dispara** para a Teleconsulta agora (testar até a
> CRIAÇÃO do agendamento — stub DEP-TC-1).
>
> Legenda de automação: 🟢 harness existe · 🟡 a construir · 🔵 depende de decisão de regra.

## Fase 0 — Identidade & Conta (o seu roteiro)
Fluxo do próprio usuário (autenticação, perfil). Harness: 🟡 `homolog-identidade-e2e.py` (a criar).
1. **Login com senha inicial → exige troca (I-007).** Entrar; confirmar que o Keycloak **obriga**
   trocar a senha no 1º acesso. 🟡 (verificar required action UPDATE_PASSWORD)
2. **Trocar a senha; deslogar; logar com a nova.** 🟡
3. **Perfil → atualizar e-mail** para `a.garbiati@portaltelemedicina.com.br`. Persistiu? 🟡
   ⚠️ hoje "Meus Dados" é **só leitura** (edição de e-mail/nome é pela tela de Usuários) — ver §Gap-A.
4. **Login por OTP e-mail:** deslogar, escolher "outra forma" → código por e-mail → logar com o
   código. 🟡 (I-005 — SMTP real)
5. **Menu Meus Dados → alterar nome → salvar → fechar o app → reabrir → o nome persiste?** 🟡
6. **O nome mudou nas outras telas?** (topbar, avatar, auditoria). Voltar e restaurar o nome. 🟡
7. **Reset de senha ("esqueci a senha")** por e-mail. 🟡 (I-005)

## Fase 1 — Clientes & Projetos
1. Criar cliente aleatório → excluir o criado → recriar → **editar** um dado → excluir de novo. 🟢
   `homolog-clientes-e2e.py` (CRUD + guard de exclusão por vínculo D-148).
2. Casos extra: sigla duplicada (409) · natureza pública×privada · desativar/reativar · tentar
   excluir cliente COM vínculo (deve bloquear com a lista de vínculos). 🟢

## Fase 2 — Usuários, Papéis & Primeiro Acesso
1. Criar **um usuário de cada papel** (admin, demandas, regulação, supervisor) + **um multi-papel**. 🟢/🟡
   (`homolog-usuarios-e2e.py` cobre CRUD; 🟡 estender p/ 1-de-cada-papel + multi.)
2. Pegar o usuário criado + senha → logar → refazer o **fluxo de primeira senha** (I-007). 🟡
3. **Reset de senha para cada usuário.** 🟡
4. **Logar como cada papel e percorrer as telas do papel** — tudo compreensível, elegante,
   **mobile-first**? (checklist visual por papel — ver §Avaliação-Visual). 🟡 (parte manual)

## Fase 3 — Escalas por caso de uso (o CORE)
Cobrir do médico previsível ao dinâmico. Harness base: 🟢 `homolog-escalas-e2e.py` (estender p/ matriz).
1. **Agenda previsível:** FIXA simples (mesmos horários todo dia, sem exceção). 🟢
2. **Horários por dia:** seg 8–14, ter 10–18. 🟢
3. **Exceção mensal:** "não atende na 2ª semana do mês" (D-152). 🟢
4. **Agenda dinâmica:** FIXA + blocos por dia + semanas excluídas + **indisponibilidade** pontual
   + **plantão de reposição** — combinados no mesmo médico. 🟡 (estender harness)
5. **Tipo de serviço × projeto:** teleatendimento/plantão/laudo dedicados a projetos diferentes. 🟢
6. **Invariantes:** conflito de horário bloqueia (INV-1); bloco inválido bloqueia (INV-4). 🟢
7. 🔵 FLEX (congelada — D-151, aguarda conversa); recorrência quinzenal (D-152 pergunta aberta).

## Fase 4 — Solicitações, Sobreposição & Capacidade
1. **Solicitação única de grande volume** (ex.: 300 vagas de Cardio no mês). 🟡
2. **Muitas solicitações pequenas** no mesmo mês (mesma especialidade / especialidades diversas). 🟡
3. **Sobreposição:** o sistema entende se HÁ ou NÃO capacidade médica para atender as solicitações?
   (oferta das escalas × demanda das solicitações, por especialidade × período). 🟡
4. **Falta de capacidade → relatório:** "quanto de capacidade médica falta alocar" (por
   especialidade/projeto) para cobrir a demanda. 🟡🔵 (fórmula de déficit — confirmar D-125/D-142)
5. **Dashboard simples com insights:** oferta vs demanda, cobertura %, onde falta médico,
   quem contratar/alocar. 🟡 (painel já mostra capacidade real — estender p/ demanda×déficit)

## Fase 5 — SEGURANÇA & ESCOPO (transversal — prioridade)
Ver `27-seguranca-gestao-de-risco.md`. Cada usuário só **vê e faz** o que seu papel + vínculo
(cliente/unidade) permitem — testado por **harness NEGATIVO** (`homolog-seguranca-e2e.py` 🟡):
- Papel sem permissão → **403** no endpoint (não só escondido na UI).
- Usuário do cliente A **não lê** dados do cliente B (escopo horizontal / multi-tenant).
- Não-admin não cria/edita usuários nem clientes.
- Sem token → 401 em tudo que é protegido; LGPD: nenhuma resposta/log expõe paciente além de iniciais.

## Gaps já conhecidos (a decidir/corrigir)
- **Gap-A:** "Meus Dados" é só leitura — a edição de e-mail/nome do próprio usuário é pela tela de
  Usuários (admin). Decidir se o próprio usuário edita seu perfil.
- **Gap-B (segurança):** agendamentos — GET global sem filtro por unidade; solicitações — POST/PATCH
  sem RBAC por papel. Entram na matriz D-142 (§27).
- **Gap-C:** relatório de déficit + dashboard de demanda×capacidade ainda não existem (Fase 4.4/4.5).

## Avaliação visual (mobile-first) — checklist por tela
Para cada tela, por papel: cabe na tela do iPhone sem scroll horizontal · alvos ≥44px · textos claros
(sem jargão interno) · estados de loading/erro/vazio · navegação inferior coerente · dark 9.4 legível ·
ação primária óbvia (FAB/CTA). (Parte manual + o QA-por-tela já rodado; re-rodar após mudanças.)
