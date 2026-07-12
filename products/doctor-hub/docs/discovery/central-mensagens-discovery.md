# Discovery — Central de Mensagens (D-194)

> **Status:** DISCOVERY (Double Diamond — entender o problema antes da solução). Base: D-194.
> Não decide nada; mapeia o espaço, os eventos e as perguntas abertas pra virar spec.

## Problema / dor
Eventos **assíncronos** precisam chegar ao usuário — a começar pelo **agendamento REJEITADO** (D-192/D-196):
o cliente pode recusar minutos depois, com o operador já em outra tela. Um erro síncrono na modal não
serve. Precisa de um canal que **persista** o aviso e **alcance** o usuário fora da sessão.

## Função (o "o quê")
Uma **Central de Mensagens** estilo Amazon: (a) uma **inbox dentro do sistema** (lista de mensagens por
usuário, lida/não-lida) e (b) **e-mail** para eventos que valem sair do app. É **transversal** — não só
agendamento; vira o hub de notificações do produto.

## Eventos candidatos (a confirmar quais entram)
- **Agendamento REJEITADO** (conflito no cliente) — o gatilho nº1; o operador precisa reagir (outra vaga).
- Agendamento **CONFIRMADO** pelo cliente (opcional — pode ser só status na tela, sem mensagem).
- Falha de sincronização persistente (cliente fora há muito tempo).
- Futuros: solicitação aceita/negada, vínculo concedido/revogado, saldo esgotado (D-190), grant de acesso (D-204).

## Eixos de design (o espaço)
- **Destinatário:** por papel/escopo — quem recebe o REJEITADO? O operador que criou o agendamento
  (`CriadoPor`)? A unidade? O cliente inteiro? (respeita o isolamento — só vê a mensagem do próprio escopo).
- **Entrega:** in-app sempre + e-mail **por tipo** de evento (nem todo evento vira e-mail). Config por
  usuário? Digest × imediato?
- **Modelo de leitura:** lida/não-lida, badge de contagem, arquivar. Retenção (quanto tempo guarda).
- **Tempo real × polling:** push (SignalR/WebSocket) × polling periódico do front. Pro protótipo, polling
  simples provavelmente basta.
- **Origem do evento:** quem publica? O `EntregaAgendamentoRunner`/pull+ack quando resolve REJEITADO/
  CONFIRMADO. Um outbox de mensagens (mesmo padrão do agendamento) garante que nenhum aviso se perde.

## Esboço técnico (uma leitura, não decisão)
- `Mensagem` (Id, DestinatarioTipo+valor [usuário/unidade/cliente], Tipo, Titulo, Corpo, Lida, CriadaEm,
  ref opcional ao agendamento). Isolada por escopo (um usuário só lê as suas).
- Publicação via **outbox de mensagens** (o produtor grava na mesma transação do evento).
- E-mail via provedor (a definir) só para os tipos marcados "email=true".
- Endpoints: `GET /api/mensagens` (as minhas, não-lidas primeiro), `POST /api/mensagens/{id}/lida`.
- LGPD: mensagem **sem PII de paciente** além de iniciais (mesma regra dura do resto).

## Perguntas abertas (pra fechar a spec)
- 🔴 **Quais eventos** entram na v1 (só REJEITADO? + CONFIRMADO?) e **quem é o destinatário** de cada um.
- 🔴 **E-mail:** quais eventos saem por e-mail; provedor (SES/SendGrid/SMTP); config por usuário.
- 🟡 **Tempo real × polling** para o in-app; retenção; arquivar.
- 🟡 **Sequência:** a Central só é exercível quando houver cliente real que rejeite (pós pull+ack real) —
  na fase 1 do agendamento resiliente o REJEITADO não ocorre. Então esta é **trilha paralela**, entra
  quando a integração de saída ligar.
- 🟢 Reuso: o "outbox de mensagens" pode espelhar o `AgendamentoOutbox` (mesmo padrão).
