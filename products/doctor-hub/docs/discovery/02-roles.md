# Papéis / Perfis

> ✅ Mapa confirmado pelo Alessandro em 2026-06-14 (D-008..D-011); **rótulos atualizados em 2026-06-15 (D-048)**.
> ⚠️ Os **rótulos de UI** mudaram, mas as **chaves de papel no código** continuam `solicitante` e `gestor`.

## Papéis que FAZEM LOGIN (usuários do sistema)

| Papel (rótulo) | chave | Quem é | O que faz | Escopo |
|---|---|---|---|---|
| **Administrador** | `admin` | Operador interno (PTM) | Configura o sistema; tudo | Global |
| **Demandas · PTM** | `demandas` | Operador interno (PTM) | Opera a Disponibilização (cria o pool do estado); ajusta retornos/extras; cadastra médicos e escalas; remaneja | Global |
| **Gestor Solicitante** | `solicitante` | Gestor estadual (Secretaria/órgão) | Abre a **solicitação** (especialidade × quantidade × competência) do seu estado | Seu **estado** (HealthCenter) |
| **Gestor** | `gestor` | Gestor de unidade | **Assume** (reserva) slots do pool do seu estado p/ sua unidade (≤ teto diário) e **agenda** paciente + doutor | Sua **unidade** (profile_tag) + vê o pool do seu estado |

> Demo: **Admin = Renata Troncoso**, **Demandas = Yannka Lins**, e **1 Gestor Solicitante + 1 Gestor por estado** (PI, AM, AP, AL, IASEP-PA). Senha `demo`.

## "Papéis" que são apenas DADOS (não logam)

| Entidade | Como entra | Observação |
|---|---|---|
| **Doutor** | Cadastrado (com escala) por um operador Admin/Demandas | Não acessa o sistema. Pode ser "preferencial" num agendamento (D-011). |
| **Paciente** | Selecionado pelo Gestor local no momento de assumir a vaga (D-009) | Não acessa o sistema. Vira parte do agendamento enviado à TC. |

## Fluxo de uma vaga, ponta a ponta (validado)
```
Secretário (Solicitante) abre solicitação  →  Admin/Demandas simula/reserva/emite vagas
   →  Gestor local assume os slots da sua unidade
        →  seleciona o PACIENTE
        →  define o DOUTOR preferencial (retorno = último doutor; senão escolhe)
             →  agendamento (médico+paciente+especialidade+HC) vai para a Teleconsulta
                  (TC respeita o preferencial; se indisponível, outro doutor da mesma especialidade)
```

## Perguntas que restam sobre papéis
- 🔴 **"Regulação" (D-093) × "Gestor Solicitante" (`solicitante`):** no fluxo de demanda (D-092/D-093) o Alessandro nomeou **Regulação** como quem **digita a necessidade** (entrada por `health_center` ≡ cliente, que **pode ser estado ou não**). O papel `solicitante` aqui já "abre a solicitação", mas com escopo **estado**. Confirmar: Regulação é **rename** de Gestor Solicitante, é o **mesmo papel com escopo ampliado** (health_center, não só estado), ou é um **papel novo**? _(não inferido — protótipo da demanda usa o rótulo "Regulação" provisoriamente.)_
- ✅ ~~Escopo de dados~~ **RESOLVIDO → D-038**: Gestor Solicitante vê só o seu estado; Gestor possui a unidade e vê o pool do seu estado.
- 🟡 De onde vem a **lista de pacientes** que o Gestor seleciona ao agendar? (D-012: vem da TC por **unidade**/profile_tag — localizar o endpoint exato).
- ✅ Quem cadastra os Gestores? **Admin**, na tela Usuários (com escopo estado/unidade).
