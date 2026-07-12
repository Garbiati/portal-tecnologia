# Roadmap por HORIZONTE — índice vivo

> Classificação do farol (`../../docs/missao-visao.md`): cada item é **AGORA · PRÓXIMO · FUTURO/VISÃO ·
> DISCOVERY**. A régua que move de horizonte: **o humano valida que as regras documentadas refletem a
> realidade** (gate `specified` do SDD). Não é um plano de datas — é "onde cada peça está na fila da reescrita".

## 🎯 AGORA — regras validadas, construído ou buildable
| Item | Estado | Ref |
|---|---|---|
| **EMPI Fase 1** (golden record paciente) | ✅ em produção | D-191 |
| **Agendamento resiliente Fase 1** (solicitação + outbox + state machine) | ✅ em produção | D-192/193/195 |
| **Fundação de multi-tenancy** (Unidade entidade · ClienteId · vínculos N:N · isolamento · vaga-por-vínculo) | ✅ na branch `feat/multi-tenancy-fundacao`, 341 verdes, homologável | D-197→D-208 |

## ⏭️ PRÓXIMO — decidido, aguarda pré-requisito ou discovery curta
| Item | Aguarda | Ref |
|---|---|---|
| **Pull+ack** (integração de saída, cliente busca+confirma) | contrato fechado; ClienteId (feito); provisionar credencial (onboarding) + ref de paciente | D-196 |
| **EMPI Fase 2** (identidade completa: proveniência + external_id FHIR simples/composto + CPF real cripto em prod) | reação do Alessandro à proposta | `docs/design/empi-identidade-proposta.md` |
| **Migração de continuidade** (histórico do SOS Gestor) | **doc da API do SOS Gestor** + snapshot seguro | D-209 |
| **Motor de grants / visibilidade cruzada** (design híbrido) | discovery (granularidade, quem concede) + validação LGPD (DPO) | D-204/D-205 |

## 🔭 FUTURO / VISÃO — desejo; regras a construir juntos
| Item | Nota | Ref |
|---|---|---|
| **Reagendamento por ausência do doutor** (retorno-mesmo-médico × fila-especialidade + handoff clínico + flag de consentimento + RQE) | cenário-farol; regras a refinar | D-210 |
| **Login do Doutor + fila unificada** (prioridade-própria × pool de especialidade) | doutor loga em outro sistema | D-208 |
| **Central de Mensagens** (inbox + e-mail; onde o REJEITADO aparece) | discovery feita; regras a fechar | D-194 |
| **Saldo `min(pool, teto)`** (trava de capacidade) | 7 perguntas abertas | D-190 |
| **Médico tecnológico premiado** (usuário co-constrói e é recompensado) | Visão do farol | farol |
| **Reescrita completa da Teleconsulta** | o horizonte-mãe; peça a peça | D-209 |

## 🔍 DISCOVERY / ABERTO — regras ainda não confirmadas
| Item | Ref |
|---|---|
| Base legal LGPD do acesso cruzado (validar com DPO/jurídico) | D-205 |
| Ordem incremental doctor-hub × regula-hub (absorve × coexiste, por peça) | D-209 |
| API do SOS Gestor (endpoints/campos) — descobrir via doc ou via código dos repos `regula-*` | D-209 |
| Chave composta do external_id (serializada × múltiplos ids) | D-206 / EMPI |

_Atualizar este índice sempre que um item mudar de horizonte (o humano validou = subiu)._
