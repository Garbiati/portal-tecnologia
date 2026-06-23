# Checklist de Aceite — Fase 1 (Gestão de Médicos + Escala)

> Gerado por agent a partir de CLAUDE.md + decisions-log (D-001..D-076) + discovery + código.
> **Fonte de cada item entre colchetes.** Não inferir regra. Usado para HOMOLOGAR o rebuild limpo
> no Figma `snTNGRUJO2GwoKpXTHCBjf`.

## 1. Escopo Fase 1
1ª entrega = **escala médica + cadastro-dono do médico** [D-052], produto = registro-MESTRE do médico
("Doctor-Hub") [D-055]. Duas telas separadas: **Médicos** (cadastro) e **Escala** (gestão de escala) [D-068].
Config/Perfil = adicionados por D-076 mas **secundários** (fora deste checklist).

## 2. GESTÃO DE MÉDICOS (/medicos) — propósito: CADASTRO [D-068]
- **Título** "Médicos" + subtítulo (localizar + manter cadastro) [MedicosPage:39-40]. **Não** cria/edita escala aqui [D-068].
- **Localizar o doutor**: select Especialidade ("Todas" + todas, incl. Clínico Geral p/ filtro) + busca "Nome ou CRM" + "N médico(s)" [LocalizarDoutor]. Filtro segmentado **Todos/Com escala/Sem escala** [D-076]. Linhas: nome, CRM·esp, badge **"● tem escala"(verde)/"sem escala"(neutro)** [D-075b]. Cap (8) + overflow + vazio. Ordem **criação DESC** [D-071d].
- **Cabeçalho contexto**: "Médico" + nome·CRM + "← Trocar médico".
- **Dados do médico** (read-only por padrão; **Editar** libera; **Salvar/Cancelar**; envia TODOS os valores) [D-070]:
  - Nome, CRM = **sempre read-only** (Teleconsulta), **sem selo "(Teleconsulta)"** [D-066/67].
  - **CPF** máscara 000.000.000-00 + validação dígito (bloqueia Salvar; vazio ok) [D-070/71].
  - **Nascimento** date dd/mm/aaaa, **passado + idade ≥18** [D-071c].
  - **Telefone**, **E-mail**, **Valor/h fixa (R$)**, **Valor/h adicional (R$)** [D-053].
  - **Especialidades · RQE por especialidade** (tabela esp+RQE; add/remover; **≥1 p/ salvar**; **Clínico Geral não atribuível**) [D-064/67].
  - Nota discreta "Faltam para o faturamento: CPF/valor fixo/≥1 esp c/ RQE" [D-055].
- **Histórico de alterações** (LGPD): quando·quem·campo·antigo→novo + vazio [D-070].
- **Escala (resumo, LEITURA)**: ativa (badge esp info, vigência, slots/semana, chips períodos) + vazio + "+N arquivadas" + botão **"Gerenciar escala →"** → /escala?doctor= [D-068].

## 3. ESCALA (/escala) — propósito: GERENCIAR escala [D-068]
- **Título "Escala" 1×** (sem topbar) [D-075e] + subtítulo. Localizar próprio + aceita ?doctor= [D-068]. Contexto: nome·CRM + badge tem/sem + Trocar. Link "Ver cadastro do médico →".
- **1 CTA laranja** = "+ Criar nova escala" [D-075a]. Card ativo: badge esp **info/azul** (não verde) [D-075b], "ativa", "slots/semana" **azul-info** [D-075b/Q5], chips períodos. Vazio "Sem escala ativa" + CTA.
- **Criar (Nova escala)** — único fluxo guiado: Especialidade (Clínico Geral fora), Vigência início/fim, Presets (Meia manhã/tarde/Integral/Madrugada/Personalizado), Dias, Períodos (start→end multi; vão=almoço sem slot; add/remover), Duração/consulta, "Criar escala".
  - **Vigência D-073**: início=hoje default, **nunca retroativo**, hoje..hoje+15d, fim≥início.
  - Criar **arquiva a ativa anterior** (avisar) [D-063].
  - **Erros**: sem especialidade(warning→Médicos), sem dia, sem período, start=end, duração≤0, sobreposição, vigência inválida [D-076].
- **Métricas**: herói **"Total previsto"** [D-075c] + Início·Fim/Encerrada·Duração·Atend/dia·/hora·Realizados. **Realizados=0 "(em breve)"** placeholder [D-072b].
- **Linha do tempo** (Gantt todas, eixo meses, legenda Ativa/Arquivada) → **MODAL por botão**, só ≥2 escalas [D-075f, D-076].
- **Arquivar**: separado do Criar, **confirm inline 2-cliques** (sem window.confirm) [D-072c]. ⚠️ "Confirmar arquivamento" deve ser **NEUTRO** (vermelho só p/ Excluir) [D-075d].
- **Reativar**: só na **última arquivada** E **sem ativa**; senão nota explicativa; nada é excluído [D-072d].
- **Excluir**: permanente, discreto, divisória, **vermelho só aqui** [D-075d]; só sem atendimentos (409); confirm inline [D-072].
- **Histórico** colapsável (N arquivadas); card arquivado mostra "Encerrada em" [D-073b].
- **Horas adicionais** [rótulo D-075, era "Disponibilidade adicional"]: só com escala ativa [D-065]; senão "Crie uma escala fixa antes". Campos Dia/Início/Fim/Duração/**Valor/h adicional*(obrig, default cadastro, editável)**/Motivo + Lançar [D-053/65]. Tabela + vazio. → **MODAL** [D-075f]. Vazio E preenchido [D-076].
- **Todos os estados clicáveis** no protótipo [D-076].

## 4. FORA da Fase 1
Solicitação/Disponibilização/Assunção/Agendamento/Remanejamento = M2–M7 [D-052/58]. Config/Perfil = D-076 secundário. PUSH p/ TC = futuro [D-069].

## 5. PERGUNTAS ABERTAS (não assumir) — do agent
1. Marca ainda não no código (seguir D-074/design-system.md). 2. Rótulo "Horas adicionais" vs código. 3. Timeline modal+≥2. 4. Cor do "Confirmar arquivamento" (neutro). 5. Badge slots/semana azul-info. 6. "Valor/h" vs "hora/consulta" [D-053]. 7. Especialidade principal (PROVISÓRIO). 8. MAX_FUTURO_DIAS=15 (default backend, não decisão escrita). 9. Cap 8 médicos. 10. Persistência das horas adicionais (store vs API).
