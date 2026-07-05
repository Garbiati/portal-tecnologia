# Visão de produto, marca & roadmap — doc hub

> Direção estratégica do Alessandro (2026-07-05). Captura a MARCA, o POSICIONAMENTO, a north-star e
> os produtos futuros. Resolve a pergunta aberta do P-009 (marca do produto vs marca do tenant).
> Não é spec de código — é o norte que orienta landing, SEO, priorização e as próximas fatias.

## Marca (resolve P-009)
**Promovemos o PRODUTO: "doc hub".** A Portal Telemedicina é o **case/cliente fundador** (o 1º e
maior caso de uso), **não** a marca de marketing. Ou seja: a landing, o SEO e a comunicação são do
**doc hub como produto** (white-label — P-009); a Portal aparece como prova/case. Se um dia vender
para outra empresa, a marca do produto (doc hub) é o que se promove; a marca do cliente vive no app
dele (tema — P-009).

## 🎯 FOCO ATUAL (MVP — a dor da Portal Telemedicina) — 2026-07-05
Reafirmado pelo Alessandro: **criar escalas de forma FÁCIL** + **gestão de solicitações de atendimento
alocando recursos médicos**. Inicialmente na dor concreta da Portal: **alocar médicos de teleconsulta
a ESPECIALIDADES**, para que cada CLIENTE tenha disponibilidade de agenda conforme sua **necessidade
DINÂMICA por cliente e por mês**. Ou seja o ciclo: escala fácil (oferta) → solicitação do cliente
(demanda por especialidade/mês) → **capacidade × demanda = déficit** → alocação. Sem integrar a
Teleconsulta ainda (para na criação do agendamento — DEP-TC-1). Tudo com DADOS REAIS.

## Posicionamento (o que é, em uma frase)
**doc hub = o sistema médico que facilita a GESTÃO e a DISTRIBUIÇÃO da capacidade médica** — escalas,
médicos e agendamentos — **para clientes públicos ou privados.** Diferenciais que a pesquisa apontou
(discovery 14/15): registrar a agenda real do médico com FACILIDADE (regra + override + preview),
previsibilidade de capacidade, e (north-star) **IA como intérprete/assistente** — ninguém no mercado
médico faz. Anti-posicionamento: não somos "mais um" gerador de escala que quebra em regra complexa.

## 💎 O DIFERENCIAL (o núcleo — Alessandro, 2026-07-05)
Três coisas, juntas, que ninguém no mercado médico faz bem:
1. **Gerenciar recursos médicos com FACILIDADE** — criar escala de forma **simples e intuitiva**
   (a agenda real do médico, sem fricção). ← *é o maior lever ainda a lapidar.*
2. **Visão em TEMPO REAL da capacidade médica** — oferta viva das escalas.
3. **Solicitações + NECESSIDADES por cliente** — demanda e déficit **por cliente do tenant**.

**Hierarquia:** doc hub (produto) → **tenant** (empresa white-label, ex.: Portal) → **clientes do
tenant** (HCs/secretarias) → necessidade dinâmica por cliente/mês. O painel de déficit já cruza
capacidade × demanda **por cliente do tenant**; o RBAC isola por cliente (D-142).

## North-star
Evoluir de "gestão de escala/capacidade" para um **HUB de soluções médicas**, com **estratégia e IA
para tomada de decisão e alocação** — o cérebro que decide *quem atende o quê, quando e por quanto*.

## Roadmap de produtos futuros (do case atual podem surgir)
> Não inferir/priorizar sem decisão — registro como visão. Cada um vira discovery próprio quando for a vez.
1. **Pareamento médico ↔ hospital** — alocar médicos plantonistas à demanda de hospitais/PS.
2. **Cálculo de remuneração por serviço** — quanto o médico recebe por **laudo · atendimento ·
   teleatendimento · plantão em pronto-socorro** (o "tipo de serviço" já modelado — D-150 — é a semente).
3. **IA de estratégia & alocação** — recomenda alocação, prevê déficit, otimiza a distribuição de vagas
   (evolução do painel de capacidade + das solicitações).
4. **Marketplace/hub** — vários produtos médicos sob a mesma plataforma/identidade.

## Onboarding do médico — self-service (evolução futura — só ideia, D-156)
> Registrado a pedido do Alessandro (2026-07-05) como visão; NÃO desenvolver agora.
- **Cadastro do próprio médico** (self-signup), saindo da fase atual em que só **médicos indicados**
  participam. A landing já terá um CTA "candidate-se" em estado **"em breve"** + captura de e-mail
  (notify-me) para avisar quando as inscrições abrirem.
- **Perfil do doutor**: o médico gerencia seus dados/especialidades/valores.
- **Autoproposta de escala**: o próprio médico PROPÕE sua escala → entra num **fluxo de APROVAÇÃO**
  (Demandas/Admin aprova/ajusta) antes de virar oferta de capacidade.
- Conecta com a north-star (hub) e com o produto futuro de pareamento médico↔hospital (D-155).

## Landing & identidade visual (fase 2 — primeiros passos)
- **Objetivo:** landing pública (raiz do doctorhub.app.br, antes do app) que apresenta o PRODUTO,
  indexável (SEO — doc 27/§SEO + este), com a Portal como case.
- **Identidade:** solução médica moderna/confiável; base = paleta da marca (navy #054671 · azul
  #0073BD · âmbar #B85410 · Dark 9.4). Referências de concorrentes = pesquisa (agente 2026-07-05).
- **Imagens de médicos:** opções — (a) **stock licenciado** (Unsplash/Pexels grátis com atenção à
  licença; Shutterstock/Getty pago p/ exclusividade); (b) **geração por IA** (Midjourney/DALL·E) —
  cuidado com o "look de IA" e com autenticidade (produto médico pede credibilidade). Recomendação:
  começar com stock licenciado real; IA como complemento. Decisão + orçamento com o Alessandro.

## Perguntas abertas
- Nome comercial final: "doc hub" fica minúsculo estilizado? Tagline oficial?
- Modelo de negócio/comercial do produto (SaaS por tenant? por médico? por vaga?) — vira P-xxx.
- Escopo da 1ª landing: institucional (o que é + case Portal) vs captação de leads (formulário/demo).
