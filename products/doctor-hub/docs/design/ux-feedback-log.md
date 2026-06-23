# Log de Feedbacks de UX — Doctor-Hub (1ª entrega, Figma `snTNGRUJO2GwoKpXTHCBjf`)

> Registro de cada feedback do Alessandro e a adequação feita, **para aprender o desejo de UX**.
> Fluxo: feedback → adequação → **homologação do Alessandro** → `✅ DONE`.
> Status: 🟡 em homologação · ✅ homologado (done) · 🔴 reaberto.

---

## #1 — Inativar médico: proximidade + confirmação 🟡 em homologação
**Tela:** Médicos · Ficha (ver) `5:2`. **Data:** 2026-06-17.
**Feedback:** "Inativar médico está muito próximo ao Trocar médico" + "Inativar está sem confirmação."
**Adequação:**
- Removido "Inativar médico" do **cabeçalho** (lá ficou só `● Ativo` + `← Trocar médico`).
- Inativar movido para uma **"Zona de risco"** discreta no **rodapé** do perfil (borda tracejada, botão danger-subtle).
- Adicionada **confirmação** (frame `92:2` "Ficha · inativar (confirmação)"): clicar Inativar → "Inativar este
  médico? … [Cancelar] [Confirmar inativação]". Confirmar → `55:2` (inativo); Cancelar → `5:2`.
- Frame do perfil cresceu para 1270px p/ caber a Zona de risco sem cortar.
**Princípio de UX aprendido (a confirmar):** _ação destrutiva nunca ao lado de navegação; sempre separada
(zona de risco/divisória) e sempre com confirmação._ — coerente com o padrão da Escala (Excluir).
**Pendente após homologar:** propagar o mesmo padrão para a Ficha `incompleto` `51:2` (ainda tem Inativar no topo).

---

## #2 — Estado inativo do médico 🟡 em homologação
**Tela:** Médicos · Ficha · inativo `55:2`. **Data:** 2026-06-17.
**Feedback:** (a) inativo deveria ter **cor/evidência visual** (a mensagem é boa, mas falta evidência);
(b) **Reativar** está sem confirmação e perto do "Trocar médico" — deixar na **mesma área do Inativar**;
(c) está **cortando, falta o scroll**; (d) **médico inativo não pode editar** — ao clicar tem que avisar
que precisa estar ativo.
**Adequação:**
- (a) **Evidência visual:** faixa cinza "⊘ Médico inativo · cadastro em LEITURA"; cards de Dados/
  Provisionamento/Escala **esmaecidos (opacity 0.5)**; badge cinza "Inativo"; Editar acinzentado.
- (b) **Reativar** removido do cabeçalho → **Zona de risco** no rodapé (mesma área do Inativar), agora **com
  confirmação** (frame `110:2`: "Reativar este médico? … [Cancelar] [Confirmar reativação]" → ativo `5:2`).
- (c) **Scroll:** fichas de perfil viraram **viewport 1180 + conteúdo rolável** (`overflowDirection=VERTICAL`)
  — aplicado a `5:2, 92:2, 55:2, 110:2, 111:2`.
- (d) **Edição bloqueada:** Editar no inativo → frame `111:2` com alerta "⚠ Para editar, reative o médico
  primeiro" + [Reativar médico] / [Entendi].
**Princípio de UX aprendido (a confirmar):** _estado inativo = evidência visual forte (fade + rótulo), não só
texto; ações de ciclo de vida (inativar/reativar) vivem juntas numa zona separada e sempre confirmam; tela
longa = scroll, nunca corte; ação indisponível explica o porquê e oferece o caminho (reativar)._

---

## #3 — Arquitetura: duplicação de telas + "cada médico está como Alessandro" 🟡 em andamento
**Data:** 2026-06-17. **Feedback:** (1) clicar nas escalas/fichas sempre mostra o nome do Alessandro;
(2) "se pedir alteração de cor de um botão, como garantimos que TODAS as telas atualizam?".
**Causa-raiz:** telas montadas **clonando frames inteiros** → sem fonte única de verdade.
**Decisão (confirmada pelo Alessandro):** adotar **biblioteca de Componentes/Variants** (página "🎨 Design
System") + **6 médicos com ficha/escala próprias**. Editar 1 master → todas as instâncias atualizam.
**Etapas:** [9 ✅] Button (8 variants) + Badge (5) bindados na marca · [10 ✅] **Sidebar componente** +
**24 telas convertidas** para instância (modais não têm sidebar) — prova viva: editar 1 master → 24 telas mudam ·
[11 ⏳] DoctorRow/Field/Card/Context-header (próximo) · [12 ✅] **6 médicos com ficha/escala próprias**
(Fernando, Juliana, Marcos, Paula, Rafael + Alessandro), cada linha do Localizar abre o médico certo,
cross-links (Gerenciar escala/Ver cadastro) por médico. **Navegação 100% (39 frames)**.
**Ajuste (17/06):** ✅ e-mail e ID externo agora **próprios por médico** (6 fichas + clones de estado); o
"Alessandro" deixou de exibir o e-mail pessoal do Alessandro (virou demo).
**Ajuste 2 (17/06):** ✅ **Editar por médico** — cada ficha abre a edição do PRÓPRIO médico (5 telas de edição
novas: Fernando/Juliana/Marcos/Paula/Rafael), Salvar/Cancelar voltam à ficha certa, resumo "sem escala".
**Navegação 100% (44 frames).**
**⚠️ Sinal de alerta (reforça a Etapa 11):** já são 3 sintomas "vai pro Alessandro" (nome→email→editar),
todos resolvidos clonando. Hoje cada médico = ficha + escala + editar = 3 frames; somar estados (incompleto/
inativo) multiplica. **Recomendação: fazer a Etapa 11 (componentizar o conteúdo da ficha/edição) ANTES de
criar mais telas por médico** — assim 1 tela editável + troca de dados mata essa classe de bug de vez.
**Pendente menor:** "Histórico de alterações" das fichas novas ainda repete o audit demo do Alessandro.

### Etapa 11 — componentizar o conteúdo (em andamento)
Página **🎨 Design System** agora tem os masters: **Button** (8), **Badge** (5), **Sidebar** (4 variants, nas
24 telas), **DoctorRow** (com/sem escala — **16 linhas convertidas** para instância), **Card**, **Field**,
**ContextHeader**. Editar o master → propaga. Navegação **100% (44 frames)** preservada após as conversões.
**ContextHeader** virou variant-set (ativo/inativo) e foi **convertido nas 18 fichas/edições** (nome/CRM/status/
Trocar preservados). **Validado por agente independente: ✅ tudo OK** (navegação 100%, layout íntegro).
**Resta o Card de Dados** (o formulário) — é o bloco mais duplicado (~18 cópias) E o de **conversão in-place
mais arriscada** (estruturas diferentes ver/editar/incompleto/CPF-inválido + ~10 campos por card). Decisão de
risco/retorno pendente com o Alessandro. Detalhe menor: e-mail truncado (largura do campo) a ajustar.
**Princípio aprendido:** _nada de clonar tela cheia; toda tela = instâncias de componentes; dados variam por
override de texto; mudança visual mora no master._
