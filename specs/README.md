# `specs/` — A especificação É o sistema

> Princípio: **Specification as Source of Truth.** O que está aqui, especificado e validado
> por um humano, é o que o sistema É. O código é um *artefato derivado* da spec — nunca o contrário.
> Se a spec diz que a tela existe, ela existe (e precisa de teste). Se não está aqui, **não existe ainda**.

## Ciclo de vida de uma spec (o "estado vivo")

Cada spec tem um `status` no frontmatter, que avança em um único sentido:

```
draft ──▶ specified ──▶ tested ──▶ implemented
(rascunho) (validada    (teste de   (código passa
           por humano)  aceite      no teste)
                        escrito)
```

| status | significa | quem move |
|---|---|---|
| `draft` | Capturada, mas com perguntas abertas / regras não confirmadas | IA + humano |
| `specified` | Humano confirmou problema, regras e critérios. Vira contrato. | **Humano valida** |
| `tested` | Critérios de aceite viraram teste executável (TDD: teste antes do código) | IA escreve, humano revisa |
| `implemented` | Código existe e passa em todos os testes da spec | IA implementa |

> Regra de ouro (ver `../CLAUDE.md`): nenhuma spec passa de `draft` para `specified`
> com **perguntas abertas pendentes**. Não inferimos — perguntamos.

## Estrutura

```
specs/
├── README.md              ← este arquivo
├── _template/
│   └── spec-template.md   ← modelo a copiar para cada nova feature
└── <slug-da-feature>/
    └── spec.md            ← uma feature = uma pasta = uma spec
```

O `STATUS.md` na raiz do projeto é **gerado** a partir do frontmatter de todas as specs —
é o embrião do portal visual: mostra o que existe, o que está validado, testado e implementado.

## Como nasce uma spec
1. Copie `_template/spec-template.md` para `specs/<slug>/spec.md`.
2. Preencha o que se SABE. Tudo que não se sabe vira **Pergunta aberta** (não invente regra).
3. Humano valida → `status: specified`.
4. IA gera os testes de aceite a partir dos critérios → `status: tested`.
5. IA implementa até passar → `status: implemented`.
