# Contrato de Navegação + Linter (gate de coerência) — 2026-06-22

> **Por que existe:** o Alessandro homologa caçando furo. Já aconteceu de um clique dentro de
> **Demandas** cair na tela do **Regulação/Regional**. Igual fizemos para DADOS (fixture canônica
> `22-demo-fixtures.md`), agora a NAVEGAÇÃO tem **fonte de verdade + verificação automática**.
> Regra: **rodar o linter abaixo ANTES de dizer "pronto".** (D-106)

---

## 1. Contrato (a regra de negócio da navegação)

### Personas (clusters isolados)
| Persona | Home | Telas | Menu lateral |
|---|---|---|---|
| **Demandas Médicas** | `514:6045` Início (Pendências) | Médicos, Escala, Demandas/Sobrepor/Reservado/Status/Multi-cliente/Contratação/Remanejamento, Conta | Início · Médicos · Escala · Demandas |
| **Regulação** (cliente) | `530:6141` Minhas solicitações | Nova solicitação `531:6141`, De acordo `531:6251` | menu próprio (mínimo) |
| **Gestor** (unidade) | `532:6141` Agendamentos | Assumir/Agendar `522:6125` | menu próprio (mínimo) |
| **Neutras** (sem persona) | — | Login `65:2`, Login·erro `66:2`, **Seletor `529:6141`**, Lab QA `552:6041`, modais (`14:2`,`15:2`,`37:2`) | — |

### Invariantes (o que SEMPRE tem que valer)
1. **Isolamento de persona.** Nenhum elemento clicável leva de uma persona para outra.
   A **única** forma de trocar de persona é **avatar → "Entrar como" (Seletor `529:6141`)**.
   → Um clique dentro de Demandas **nunca** abre a tela de GG/GR (e vice-versa).
2. **Alcançabilidade.** Toda tela é acessível a partir do **Login `65:2`** (BFS pelos NAVIGATE).
   GG/GR são alcançados via **Login → Seletor → persona** (não por link cross-persona).
3. **Zero click morto.** Todo destino de NAVIGATE é uma tela que existe.
4. **Zero órfã.** Nenhuma tela fica fora do grafo.
5. **Self-ref do menu ativo é OK.** O item de menu da página atual pode apontar para ela mesma
   (fica "ativo"); isso **não** é furo.

### Handoff entre personas (como o fluxo continua sem vazar)
O pipeline cruza personas (Demandas entrega → **Regulação** dá "de acordo" → **Gestor**
assume/agenda), mas **no protótipo a continuação é por troca de perfil** (avatar→Seletor), não por
um botão que teleporta. Ex.: ao **Provisionar**, Demandas vai para **Status da demanda `495:5955`**
(mostra *Entregue*); para seguir como Regulação, troca-se de perfil pelo Seletor.

---

## 2. Linter (rodar antes de entregar) — `use_figma`, read-only

Cola este script no `use_figma` (fileKey `snTNGRUJO2GwoKpXTHCBjf`). Saída esperada:
`{total, reachable==total, leaks:[], orphans:[], deadClicks:[], selfRefs:[...menu ativo...]}`.
**Se `leaks`, `orphans` ou `deadClicks` não estiverem vazios → NÃO entregar; corrigir antes.**

```js
const page = figma.root.children.find(p => p.id === '0:1');
await figma.setCurrentPageAsync(page);
const frames = page.children.filter(n => ['FRAME','COMPONENT','COMPONENT_SET'].includes(n.type));
const idToName={}; frames.forEach(f=>idToName[f.id]=f.name);
const ids = new Set(frames.map(f=>f.id));

// Membership — manter sincronizado com a tabela de personas acima.
const GG=new Set(['530:6141','531:6141','531:6251']);
const GR=new Set(['532:6141','522:6125']);
const NEUTRAL=new Set(['65:2','66:2','529:6141','552:6041','14:2','15:2','37:2']);
const persona=id=>GG.has(id)?'GG':GR.has(id)?'GR':NEUTRAL.has(id)?'NEUTRAL':'DEMANDAS';

function navs(node){const out=[];(function v(n){
  for(const r of (n.reactions||[])){const acts=r.actions||(r.action?[r.action]:[]);
    for(const a of acts) if(a&&a.type==='NODE'&&a.navigation==='NAVIGATE'&&a.destinationId) out.push({src:n.name,dest:a.destinationId});}
  if('children' in n) for(const c of n.children) v(c);})(node); return out;}

const leaks=[];
for(const f of frames){const pf=persona(f.id); if(pf==='NEUTRAL')continue;
  for(const nv of navs(f)){const pd=persona(nv.dest); if(pd==='NEUTRAL')continue;
    if(pf!==pd) leaks.push(`${f.name} --[${nv.src}]--> ${idToName[nv.dest]} (${pf}->${pd})`);}}

const graph={}; frames.forEach(f=>graph[f.id]=new Set(navs(f).map(n=>n.dest).filter(d=>ids.has(d))));
const seen=new Set(['65:2']); const q=['65:2'];
while(q.length){const cur=q.shift(); for(const d of (graph[cur]||[])) if(!seen.has(d)){seen.add(d);q.push(d);}}
const orphans=frames.filter(f=>!seen.has(f.id)).map(f=>`${f.id} ${f.name}`);

const dead=[], self=[];
for(const f of frames) for(const nv of navs(f)){
  if(!ids.has(nv.dest)) dead.push(`${f.name} --[${nv.src}]--> ${nv.dest}`);
  if(nv.dest===f.id) self.push(`${f.name} --[${nv.src}]--> self`);
}
return JSON.stringify({total:frames.length, reachable:seen.size, leaks, orphans, deadClicks:dead, selfRefs:self});
```

### Manutenção
- Ao **adicionar telas de GG/GR**, inclua os ids nos sets `GG`/`GR` (senão o linter as trata como Demandas).
- Ao **criar um handoff** entre personas, faça-o pelo Seletor — não por link direto.
- Última auditoria limpa: **2026-06-22 — 84/84 alcançáveis, 0 leaks, 0 mortos, 0 órfãs** (D-106).
