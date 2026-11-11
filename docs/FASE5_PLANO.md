# Fase 5 — Sistemas (plano, 11/11/2026)

**Objetivo:** dar ao jogador o que fazer com o ouro e os materiais do Ato 1: itens, poções, equipamentos, ferreiro, lojas (ouro e dinheiro real), diárias, calendário de login, conquistas e dificuldade. Tudo segue o GDD (Parte 6) e é testado no Ato 1 antes da Fase 6 (cidades 2 a 5).

Já ficaram prontos na Fase 4 e **não** entram aqui: NPCs, conversas, missões, save.

## Etapas
Cada etapa termina com algo jogável para você testar.

| # | Etapa | O que fica pronto |
|---|---|---|
| 5.1 | **Itens e inventário** | Mochila com espaços; itens com raridade (branco, azul, roxo, dourado) e ícone; detalhes do item; drops de itens dos inimigos e baús; materiais (os 4 de hoje) passam a ser itens; tudo no save |
| 5.2 | **Poções** | Atalhos na tela (vida, fôlego, reforço) com quantidade e recarga; poções pequena/média/grande; reforços de força, pedra e vento (GDD 6.5.1); **reequilíbrio dos chefes** com poções |
| 5.3 | **Equipamentos** | Espaços: espada, 5 de armadura (elmo, peitoral, luvas, calça, botas), 3 acessórios (2 pulseiras, cinto); atributos por peça; tela do personagem com o Lio e as peças; a espada equipada aparece na mão |
| 5.4 | **Ferreiro (Tobias)** | Criar peças com materiais + ouro (encaixes aleatórios 0 a 3); gemas (5 tipos, 5 níveis); fortalecer +1 a +20 com Trevo e Amuleto; quebrar/restaurar; desmontar (100% / 50%) — tudo conforme GDD 6.5 |
| 5.5 | **Lojas** | Loja de ouro da Dona Celeste (equipamentos comuns e raros, poções, Trevo/Broca comuns, Amuleto; vender itens); **loja com dinheiro real** com a camada `Store` (no PC fica desligada; no Android usa o Google Play Billing) |
| 5.6 | **Rotina e metas** | 5 missões diárias por nível; calendário de login de 28 dias (com proteção contra voltar a data); conquistas e títulos (1 equipado, com bônus); escolha de dificuldade no Novo jogo (Fácil / Normal / Difícil, pode diminuir na cidade) |

**Fica para depois:**
- **Duas espadas** (estilo de arma): precisa das animações 91 e 92 do Meshy no Lio (6 créditos) e de uma segunda espada; entra quando houver espadas suficientes (Fase 6), mas o espaço já fica reservado.
- **Modo Infernal** das dungeons: entra na Fase 6, junto com as novas dungeons.
- **Teste real do Google Play Billing:** o código e os produtos ficam prontos na 5.5, mas comprar de verdade só dá para testar com o jogo publicado num canal de teste interno da Play Store (Fase 7). Até lá, uma "loja de teste" no PC simula as compras.

## O que vamos gerar no Meshy

| Grupo | Itens | Créditos aprox. |
|---|---|---|
| **Ícones de itens** (4 folhas de 4×4 ícones, recortadas no Godot) | Poções (vida, fôlego, 3 reforços, 3 tamanhos), Trevo, Trevo Real, Broca, Broca Real, Amuleto, 5 gemas, materiais (couro de orc, osso velho, fragmento de pedra, palha dourada, + 4 do Ato 2), peças de armadura e acessórios por raridade | ~40 |
| **Espadas do Ato 1** (modelo 3D) | 4 espadas novas além da de aprendiz: comum, rara, épica e a lendária do conjunto de Pradoluz | ~60 |
| **Baú** (modelo 3D, aberto e fechado) | Baús nas áreas e no fundo da mina | ~15 |
| **Margem** (~20%) | refazer o que não ficar bom | ~25 |
| **Total** | | **~140** |

**Decisão (11/11/2026): sem visual de conjunto nesta fase** (fica para a Fase 6). Texto original: O GDD diz que o visual do Lio muda com 3+ peças do mesmo conjunto. Cada conjunto é um modelo completo do Lio com esqueleto e as 14 animações (~70 créditos). Dá para fazer **1 conjunto do Ato 1** já nesta fase (fica em ~210 créditos) ou deixar os visuais de conjunto para a Fase 6. Os atributos e bônus de conjunto funcionam de qualquer jeito.

Créditos: a Fase 5 tinha ~500 previstos no roadmap; este plano usa ~140 (ou ~210 com o conjunto). Restam 1.013 no ciclo atual.

## Preços da loja com dinheiro real (rascunho para você decidir)
O GDD diz que os preços são definidos nesta fase. Proposta inicial, em reais, para ajustar:

| Produto | Conteúdo | Preço |
|---|---|---|
| Saco de ouro | 5.000 de ouro | R$ 4,90 |
| Baú de ouro | 30.000 de ouro (+20%) | R$ 24,90 |
| Pacote de EXP | +50% de XP por 1 hora | R$ 3,90 |
| Kit de poções | 10 de vida, 10 de fôlego, 3 reforços | R$ 4,90 |
| Trevo Real | 1 unidade | R$ 6,90 |
| Broca Real | 1 unidade | R$ 4,90 |
| Amuleto de Proteção | 1 unidade | R$ 3,90 |

Os valores de ouro serão calibrados com a economia da 5.5 (quanto o jogador ganha por hora jogando), para comprar ser atalho, nunca obrigação (GDD 6.6).

**O que você precisa fazer no Play Console (na Fase 7, com o jogo enviado ao teste interno):** criar esses produtos com os mesmos ids que o jogo usa e adicionar sua conta como testador de licença. Eu passo a lista pronta.

## Ordem
1. 5.1 e 5.2 (itens e poções) primeiro: o jogo ganha sentido de recompensa e os chefes ficam justos.
2. Ícones no Meshy em seguida (te mostro as folhas antes de recortar).
3. 5.3 e 5.4 (equipamentos e ferreiro), com as espadas do Meshy.
4. 5.5 (lojas) e 5.6 (rotina).
5. Testes automáticos de cada sistema (como nas fases anteriores) e fotos para você aprovar em cada etapa.
