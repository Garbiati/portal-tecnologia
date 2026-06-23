# Enforcement: o hook que torna "a spec é a config" REAL

> Sem enforcement, "a spec é a fonte da verdade" é só uma boa intenção. O mecanismo do
> Claude Code que TRANSFORMA isso em regra da máquina é o **hook `PreToolUse`**: ele roda
> ANTES de uma ferramenta (Edit/Write) e pode **bloquear** a ação (exit code 2 = negar).
>
> Aqui está a LÓGICA (pseudocódigo). A implementação real (shell/script) só será escrita
> quando a stack/processo forem aprovados — isto é só o desenho do comportamento.

## Regra 1 — Não codificar sem spec validada
```
PreToolUse(Edit | Write) sobre um arquivo de código:
  feature = inferir_feature_do_caminho(arquivo)        # ex.: src/.../cadastro-usuario/...
  spec = procurar specs/<feature>/spec.md
  SE spec não existe:
      BLOQUEAR("Não há spec para '<feature>'. Crie specs/<feature>/spec.md antes de codificar.")
  SE spec.status == "draft":
      BLOQUEAR("A spec de '<feature>' ainda é rascunho. Um humano precisa validá-la (specified).")
```

## Regra 2 — Teste antes do código (TDD)
```
PreToolUse(Edit | Write) sobre arquivo de código de uma feature:
  SE spec.status == "specified" (ainda não "tested"):
      BLOQUEAR("Escreva primeiro os testes de aceite a partir dos cenários da spec.")
  SE não existe arquivo de teste correspondente:
      BLOQUEAR("Sem teste para '<feature>'. TDD: o teste vem antes.")
```

## Regra 3 — Não fechar sessão com teste quebrado
```
Stop (fim de sessão):
  rodar suíte de testes
  SE algum teste falha:
      BLOQUEAR("Há testes quebrados. Não finalize com a árvore vermelha.")
```

## Regra 4 — Anti-inferência (a Diretriz Suprema, automatizada)
```
PreToolUse(Edit | Write) sobre specs/<feature>/spec.md:
  SE está mudando status de "draft" para "specified"
     E ainda há marcador "🔴" no corpo da spec:
      BLOQUEAR("Não dá para validar uma spec com perguntas 🔴 abertas. Pergunte ao humano.")
```

---

### Por que isto importa para você (1 dev + IA)
Estes 4 hooks são o que impede a IA de "ir codificando e inventando regra". Eles fazem a
máquina **obrigar** o fluxo: dor → spec → validação humana → teste → código. É a tradução
literal do seu pedido "quase nenhuma inferência em regra de negócio".
