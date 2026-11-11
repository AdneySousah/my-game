# Fase 3 — Teste do Meshy

**Objetivo:** provar o fluxo inteiro (gerar no Meshy → aprovar → importar no Godot → jogar) com poucos assets, antes de gerar em volume. No fim da fase, o Lio, a espada, o bandido e as peças de Pradoluz substituem as formas cinzas da arena.

## O que vamos gerar

### Herói — `hero_lio`
| Passo | Ferramenta / modelo | Créditos |
|---|---|---|
| Modelo 3D a partir da imagem aprovada (`ref_lio`) | Image to 3D, `meshy-t2.5` (topologia inteligente, ~9.000 triângulos) + textura `meshy-n1` | 15 |
| Esqueleto (rig), já com andar e correr | Rigging | 5 |
| 14 animações da biblioteca | Animation (3 cada) | 42 |
| **Subtotal** | | **62** |

Animações (id do Meshy): parado `0`, guarda de combate `89`, combo de 3 golpes `105`, rolamento `158`, levar dano `178`, morrer `8`, e uma para cada skill: Corte Giratório `238`, Investida `240`, Golpe Sísmico `127`, Quebra-Guarda `242`, Brado de Guerra `88`, Onda de Corte `221`, Salto Devastador `86`, Julgamento `102`.

As animações de duas espadas (`91`, `92`) ficam para quando o estilo de duas espadas entrar no jogo.

### Arma — `wpn_espada_aprendiz`
Espada simples de aprendiz, modelo separado preso na mão do Lio no Godot. Text to 3D `meshy-t2` (~500 triângulos): prévia 5 + textura 10 = **15**.

### Inimigo — `enm_bandido`
| Passo | Créditos |
|---|---|
| Imagem conceito (`nano-banana-2`, A-pose) | 6 |
| Modelo 3D (`meshy-t2.5` + `meshy-n1`, ~5.000 triângulos) | 15 |
| Rig (com andar e correr) | 5 |
| 4 animações: parado `0`, ataque `97`, levar dano `178`, morrer `8` | 12 |
| **Subtotal** | **38** |

O orc continua como forma simples nesta fase e ganha modelo na Fase 4.

### Peças de Pradoluz (10)
Text to 3D `meshy-t2` (topologia inteligente): prévia 5 + textura 10 = **15 cada**.

| id | Peça | Triângulos |
|---|---|---|
| `prp_arvore` | Árvore frondosa | ~1.500 |
| `prp_arbusto` | Arbusto com flores | ~600 |
| `prp_pedra` | Pedra grande | ~400 |
| `prp_cerca` | Cerca de madeira (2 m) | ~400 |
| `prp_barril` | Barril | ~400 |
| `prp_caixa` | Caixote | ~300 |
| `prp_feno` | Fardo de feno | ~400 |
| `prp_carroca` | Carroça de fazenda | ~1.500 |
| `prp_poco` | Poço de pedra com telhadinho | ~1.200 |
| `env_casa_pequena` | Casa pequena de madeira, telhado laranja | ~3.000 |
| **Subtotal** | | **150** |

## Total
| | Créditos |
|---|---|
| Herói | 62 |
| Espada | 15 |
| Bandido | 38 |
| 10 peças | 150 |
| **Total** | **265** |
| Margem para refazer o que não ficar bom (~20%) | ~55 |
| **Teto da fase** | **~320** (de 2.661 disponíveis até 04/12) |

## Como vai funcionar
1. Eu gero cada asset pelo conector, **na ordem**: herói → espada → bandido → peças. Assim, se o herói não ficar bom, paramos antes de gastar no resto.
2. Antes de pedir o esqueleto e as animações do herói, eu te mostro o modelo para aprovar.
3. Cada asset vai para a pasta de revisão (`assets/_inbox`). Eu te mostro as imagens e você aprova ou pede para refazer.
4. Os aprovados vão para `assets/` e eu monto no Godot:
   - importação automática das animações;
   - espada presa na mão;
   - shader estilo desenho;
   - as peças espalhadas na arena.
5. Você joga a arena com o Lio de verdade e aprova a Fase 3.

**Mudança em relação ao combinado antes:** o plano era fazer o herói no site, por causa das tentativas grátis. Como a imagem do Lio já foi gerada pela API e cada tentativa pelo conector custa só 15 créditos, fica mais simples e rápido fazer tudo pelo conector. Se o modelo não ficar bom depois de 2 tentativas, passamos para o site.
