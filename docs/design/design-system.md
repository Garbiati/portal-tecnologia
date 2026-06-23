# Design System — Doctor-Hub (marca Portal Telemedicina)

> **Fonte da verdade do visual.** Esta é a especificação que o **Figma** (Variables +
> componentes) e o **código** (`app/src/styles/tokens.css`) devem espelhar — nessa ordem:
> **Figma primeiro, código depois.** Nada de hex solto: sempre `var(--token)` no código e
> Variable no Figma. Decisões registradas em `docs/decisions/decisions-log.md`.

Decisão de direção (Alessandro, 2026-06-16):
1. **Marca modernizada (admin)** — paleta navy/azul como primária, **laranja só em CTAs/ações-chave**,
   layout limpo de painel, **rigor de contraste WCAG 2.2 AA preservado** (gate inegociável — healthcare).
2. **Tipografia híbrida** — **Montserrat** nos títulos (marca) + **Inter** no corpo/tabelas (dados densos).
3. **Design system próprio** sobre os tokens já existentes (não adotar UI kit externo).

---

## 1. Marca extraída do site (portaltelemedicina.com.br, 2026-06-16)

| Papel na marca | Hex | Observação |
|---|---|---|
| Navy (títulos) | `#054671` | cor de título do site |
| Azul corporativo | `#0073BD` | links/nav |
| Teal (cards/seções) | `#2B84A1` | apoio |
| Verde (logo) | `#719430` | apoio |
| **Laranja (ação — "Solicitar Proposta")** | `#ED7225` | traço de marca mais forte |
| Neutros | `#333333` `#969696` `#EFEFEF` | — |
| Fontes | Montserrat (títulos) · Raleway (corpo) | adotamos Montserrat + **Inter** no corpo |

## 2. Contraste WCAG (calculado — AA exige 4.5:1 texto normal, 3:1 UI/large)

| Par | Razão | Veredito |
|---|---|---|
| texto navy `#054671` / branco | 9.90 | ✓ texto |
| texto/azul `#0073BD` / branco | 5.02 | ✓ texto |
| branco em azul `#0073BD` (botão) | 5.02 | ✓ texto |
| branco em azul-hover `#00609E` | 6.63 | ✓ texto |
| **branco em laranja `#ED7225`** | **2.99** | **✗ REPROVA** |
| navy em laranja `#ED7225` | 3.32 | só UI/large |
| **branco em laranja-fill `#B85410`** | **4.87** | **✓ texto** (usar este p/ botão) |
| texto laranja `#B85410` / branco (link) | 4.87 | ✓ texto |
| branco em teal `#2B84A1` | 4.27 | só UI/large → badge/área grande |
| branco em verde `#719430` | 3.51 | só UI/large → badge/área grande |

**Regra que sai daqui:** o laranja vivo `#ED7225` **nunca** recebe texto pequeno. Botão de ação
usa o **fill escurecido `#B85410`** com texto branco. O `#ED7225` fica para decoração/área grande.

## 3. Tokens semânticos (brandizados)

Primitivos de marca a adicionar; neutros **mantêm a escala slate** (já AA-aprovada, harmoniza com navy).

```
/* Marca */
--navy-700:#054671;  --navy-600:#0A557F;  --navy-50:#E7EEF3;   /* sidebar/títulos */
--blue-600:#0073BD;  --blue-700:#00609E;  --blue-50:#E6F1F8;   /* acento: links/nav/info/2ª ação */
--orange-fill:#B85410; --orange-hover:#9A440D; --orange-bright:#ED7225; --orange-50:#FDF0E7; /* AÇÃO */
--teal-500:#2B84A1;  --green-600:#719430;  /* apoio (não-semântico) */

/* Semânticos */
--color-primary:        var(--navy-700);    /* sidebar bg, h1/h2, ênfase estrutural */
--color-accent:         var(--blue-600);    /* links, foco, nav ativo, info, 2ª ação */
--color-accent-hover:   var(--blue-700);
--color-accent-subtle:  var(--blue-50);
--color-action:         var(--orange-fill); /* CTA primária (Salvar, Criar) — texto branco */
--color-action-hover:   var(--orange-hover);
--color-action-bright:  var(--orange-bright); /* SÓ decorativo/área grande, nunca texto pequeno */
--color-text-on-action: #FFFFFF;
/* Status seguem CONVENCIONAIS (verde/vermelho/âmbar) p/ significado universal — não viram marca. */
```

**Regra de uso da cor de ação:** no máximo **uma** CTA laranja por tela (a ação principal da view).
Demais botões = azul (`btn--accent`) ou neutro (`btn--subtle`). Evita "tudo primário".

## 4. Tipografia

```
--font-heading:"Montserrat", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; /* h1–h3, títulos de card */
--font-family:"Inter", system-ui, ...;  /* corpo, tabelas, inputs (mantido) */
```
Escala de tamanhos/linha: **mantida** (já em `tokens.css`). Montserrat só troca a *família* dos títulos.

## 5. Inventário de componentes (a montar no Figma e espelhar no código)

Núcleo (ordem de construção): **Button** (variantes: action/accent/subtle/danger/success · tam sm/md) ·
**Input/Select/DateFieldBR** · **Badge/Chip** (info/success/neutral/warning/danger) · **Card** ·
**Metric** (rótulo+valor) · **Table** (header surface-muted, zebra) · **Sidebar** (navy) ·
**Topbar** · **Toast** · **Empty-state** · **Tabs/segmented** (filtro Todos/Com/Sem) · **Timeline/Gantt da escala**.

## 6. Processo "Figma primeiro" (anti-drift)

1. Mudança de visual começa **aqui** (este doc) → vira **Figma Variables** + componente no arquivo núcleo
   `figma.com/design/NCMcYURZgrHH36f9DTk7di` (conta `a.garbiati@gmail.com`, Full/Pro).
2. Só **depois** o código (`tokens.css` + componentes) espelha 1:1.
3. PR/registro cita o nó do Figma. Assim Figma e código não divergem (débito que estamos quitando agora).

_Atualizado: 2026-06-16 — extração de marca + AA + direção aprovada._
