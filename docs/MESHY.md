# Como gerar assets no Meshy

Dois caminhos, com o mesmo resultado:
- **MCP** (o Claude gera direto pelo conector `meshy`): inimigos comuns, NPCs, objetos e peças de cenário.
- **Site** (o dono gera usando um cartão de prompt que o Claude entrega): herói, chefes e fantasias, porque o site dá 12 tentativas grátis por tarefa.

O guia de estilo (texto base de prompt, paleta, imagem de referência) é definido na Fase 1 e fica em `docs/ESTILO.md`. Todo prompt começa com esse texto base.

## Fluxo de um asset
1. **Planejar**: `python tools/meshy/ledger.py add <id> --category <cat> --phase <n> --prompt "..."`.
2. **Checar orçamento**: `python tools/meshy/ledger.py can-spend <créditos>`.
3. **Gerar** pelo MCP ou pelo site.
4. **Registrar o gasto**: `python tools/meshy/ledger.py spend <id> <tipo> <créditos> --task-id <id da tarefa>`.
5. **Baixar** para `assets/_inbox/<id>/` e marcar `review`.
6. **Aprovação do dono**. Rejeitado → `rejected` (e gerar de novo se fizer sentido). Aprovado → mover para `assets/<categoria>/<id>/` e marcar `approved`.
7. **Importar e testar no Godot** → marcar `imported`.

Status possíveis: `planned`, `generating`, `review`, `approved`, `rejected`, `imported`.

## Nomes
`<prefixo>_<nome>` em minúsculas com `_`. O arquivo final fica em `assets/<categoria>/<id>/<id>.glb`.

| Categoria | Prefixo | Pasta |
|---|---|---|
| Herói | `hero_` | `assets/characters/` |
| Fantasia do herói | `cos_` | `assets/characters/` |
| Inimigo | `enm_` | `assets/enemies/` |
| Chefe | `boss_` | `assets/enemies/` |
| NPC | `npc_` | `assets/npcs/` |
| Objeto / peça de cenário | `prp_` | `assets/props/` |
| Peça de ambiente (muro, casa, ponte) | `env_` | `assets/environment/` |
| Imagem de referência (PNG) | `ref_` | `docs/design/referencias/` |

## Especificações técnicas

### Personagens (herói, fantasias, inimigos, chefes, NPCs)
- Sempre **humanoides**, em **A-pose** (`pose_mode: a-pose`), corpo inteiro, de frente, sem arma colada no corpo.
- Caminho preferido: imagem conceito (grátis) → Image to 3D → Remesh (se precisar) → Rigging → Animações.
- Polígonos (triângulos): herói 8.000–10.000 · chefe até 12.000 · inimigo 4.000–6.000 · NPC 3.000–5.000.
- Textura: 2K na geração; o Godot reduz para 1K no celular.
- Formato: **GLB**.
- Animações mínimas (biblioteca do Meshy): parado, andar, correr, ataque (2–3 variações), levar dano, morrer. O herói ganha também as animações das 4 skills.
- Fantasia = um novo modelo completo do herói com o mesmo conjunto de animações.

### Objetos e peças de cenário
- Text to 3D com `model_type: smart-topology` (low-poly limpo).
- Polígonos: objeto pequeno 300–1.000 · objeto médio 1.000–2.000 · peça de construção até 3.000.
- `auto_size: true` com `origin_at: bottom` (ponto de apoio no chão).
- Formato: **GLB**. Textura 2K (reduzida para 1K no celular).
- Peças modulares precisam encaixar: muros e pisos com medidas redondas (1 m, 2 m, 4 m).

### Modelos e custos da API (preços de out/2026)
| Uso | Modelo | Créditos |
|---|---|---|
| Imagem conceito | `nano-banana-2` | 6 |
| Personagem (Image to 3D) | `meshy-t2.5` + textura `meshy-n1` | 15 |
| Objeto (Image to 3D ou Text to 3D) | `meshy-t2` + textura `meshy-n1` | 15 (text: 5 preview + 10 refine) |
| Rig (já inclui andar e correr) | — | 5 |
| Animação extra | — | 3 cada |
| Retexture (variação) | — | 10 |
| Remesh / UV | — | 5 |

Animações da biblioteca escolhidas para o herói (ids do Meshy): ataque básico `105` Triple Combo Attack, `92` Double Combo Attack, skills `91` `238` `240` `127` `88` `242` `221` `102` `86`, esquiva `158` Roll Dodge, guarda `89` Combat Idle, dano `178` Hit Reaction, morte `8` Dead.

### Economia de créditos
- Use as imagens conceito (grátis) para acertar o visual antes de gerar o 3D.
- Variações (ex.: goblin → goblin chefe) com Retexture em vez de um modelo novo.
- Reaproveite peças modulares ao máximo.
- Gere só o que a fase atual precisa.

## Cartão de prompt (para gerar no site)

```
ASSET: <id>
FERRAMENTA: Image to 3D (ou Text to 3D)
IMAGEM DE REFERÊNCIA: <arquivo / descrição>
PROMPT: <texto base do ESTILO.md> + <descrição do asset>
CONFIGURAÇÕES:
  - Topologia: <smart topology / triângulos>
  - Polígonos alvo: <número>
  - Pose: A-pose (só personagens)
  - Textura: 2K, PBR desligado
DEPOIS DE GERAR:
  - Rigging: <sim/não>
  - Animações: <lista>
EXPORTAR: GLB
SALVAR EM: assets/_inbox/<id>/<id>.glb
```
