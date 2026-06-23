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

## Estrutura — método aqui, specs de feature no produto

> Esta pasta (`specs/` na **raiz**) guarda só o **método**: o ciclo de vida acima + o template.
> **As specs de feature vivem em cada produto:** `products/<produto>/specs/<slug>/`
> (ex.: `products/doctor-hub/specs/medicos-escala/`). Assim cada produto tem suas features isoladas.

```
specs/                          ← raiz: só método
├── README.md                   ← este arquivo (ciclo de vida da spec)
└── _template/spec-template.md   ← modelo a copiar para cada nova feature

products/<produto>/specs/        ← specs de feature do produto
├── README-ui.md                 ← (se houver) índice/convenção de ui.md do produto
└── <slug-da-feature>/
    ├── spec.md                  ← uma feature = uma pasta = uma spec
    └── ui.md                    ← (opcional) recorte de UI
```

Um `STATUS.md` por produto pode ser **gerado** a partir do frontmatter das specs do produto —
embrião do portal visual: o que existe, validado, testado e implementado.

## Como nasce uma spec
1. Copie `specs/_template/spec-template.md` para `products/<produto>/specs/<slug>/spec.md`.
2. Preencha o que se SABE. Tudo que não se sabe vira **Pergunta aberta** (não invente regra).
3. Humano valida → `status: specified`.
4. IA gera os testes de aceite a partir dos critérios → `status: tested`.
5. IA implementa até passar → `status: implemented`.
