# Fase 4 — Fatia vertical (Ato 1: Pradoluz)

**Objetivo:** o primeiro pedaço do jogo **de verdade**, do começo ao fim. É a prova de que o jogo é divertido antes de construir as outras 4 cidades.

O jogador vai:
1. ver o **prólogo** (o nascimento do Lio, em ilustrações);
2. acordar em **Pradoluz**, conversar com a mãe, o Mestre Bram e o Bento;
3. sair pela **Floresta Sussurrante**, enfrentando bandidos e orcs, com pontos de descanso;
4. entrar na **Mina dos Corvos** (dungeon), com esqueletos mineiros e o Golem de pedra;
5. enfrentar **Gorvan, o Arauto da Colheita**, que muda de forma no meio da luta;
6. voltar à vila, que agora tem comida, e terminar o Ato 1 por volta do **nível 12**.

Tudo com **som**: música, passos, golpes, skills e a "fala" dos NPCs.

## Etapas
Cada etapa termina com algo jogável para você testar.

| # | Etapa | O que fica pronto |
|---|---|---|
| 4.1 | **Mundo e viagem** | 3 mapas (vila, floresta, mina) ligados entre si; teleporte nas Pedras de Passagem; pontos de descanso; árvores ficam transparentes quando escondem o herói |
| 4.2 | **Conversa e missões** (feito) | NPCs com diálogo em balões, "fala" em bipes, retratos; missão principal do Ato 1 e 2 missões secundárias; marcador de objetivo |
| 4.3 | **Inimigos e chefe** (feito) | Orc, bandido arqueiro, esqueleto mineiro e Golem de pedra com modelos; Gorvan com 2 formas; drop de ouro e materiais |
| 4.4 | **Áudio** | Sistema de som com volumes; efeitos de combate, das 8 skills, passos, interface; música da vila, da floresta, da mina e do chefe |
| 4.5 | **Prólogo e save** (feito) | Prólogo em ilustrações; tela inicial; salvar e continuar (save local, já criptografado) |

### Pedidos do dono após a 4.1 (11/11/2026)
| # | Etapa | O que fica pronto |
|---|---|---|
| 4.1b | **Bordas e navegação** (feito, sem créditos) | Minimapa redondo girado como a câmera, com setas para as saídas; mapa completo (tecla M ou toque no minimapa); rios animados e paredões de rocha fechando a floresta; cerca provisória em volta da vila |
| 4.1c | **Muralhas e portais** (Meshy, feito) | Muralha de pedra, torre de canto e portão da cidade para cercar as cidades; portal de pedra com luz mágica nas saídas; juncos e rochedos para as margens |
| 4.2a | **Interface com a cara do jogo** (Meshy, feito) | Moldura de janela, caixa de diálogo, botão, botão redondo (ataque/skills), moldura das barras, moldura do minimapa e os 8 ícones das skills, no estilo das imagens de referência |
| 4.2b | **HUD com retrato** (feito) | Retrato do Lio num círculo: metade de cima do anel = vida, metade de baixo = XP; nível e ouro ao lado; fôlego numa barra no rodapé, centralizada; Atributos e Skills saem da tela e viram um alerta "!" no retrato (pontos para distribuir ou skill nova), que abre o menu do personagem; o botão "+1 nível" só aparece na versão de teste |

Os 3 a 4 mapas de campo por região, com transição gradual de bioma (pedido do dono), ficam para a **Fase 6** (GDD, Parte 2); a fatia vertical segue com a Floresta Sussurrante.

Inventário, equipamentos, ferreiro e loja ficam para a **Fase 5**, como no roadmap. Nesta fase os drops só somam ouro e materiais.

## O que vamos gerar no Meshy

| Grupo | Itens | Créditos aprox. |
|---|---|---|
| **NPCs** (modelo + esqueleto + parado/falar/acenar) | Marta, Mestre Bram, Bento, Dona Celeste, Tobias, 2 aldeões | ~180 |
| **Inimigos** (modelo + esqueleto + 4 a 5 animações + arma) | Orc, bandido arqueiro (nova textura do bandido + arco), esqueleto mineiro, Golem de pedra | ~170 |
| **Chefe Gorvan** | Forma 1 (mordomo com foice) e forma 2 (Espantalho Colossal), com armas e animações | ~140 |
| **Vila** (~12 peças) | Casas (2 variações), moinho, barraca de mercado, plantação de trigo, placa, lampião, banco, ponte, Pedra de Passagem | ~220 |
| **Floresta** (~8 peças) | Pinheiro, árvore torta, tronco caído, toco, cogumelos, flores, pedras pequenas, cerca quebrada | ~150 |
| **Mina** (~10 peças) | Paredes e entrada da mina, vigas de suporte, trilhos, carrinho de mina, minério, cristal, lampião, barril de pólvora, portão | ~180 |
| **Prólogo** | ~8 ilustrações | ~50 |
| **Total** | | **~1.090** |
| Margem para refazer (~20%) | | ~220 |
| **Teto da fase** | | **~1.300** (de 2.354 disponíveis até 04/12) |

Vou gerar **por etapa**, sempre te mostrando antes de seguir, como na Fase 3.

## Etapa 4.3 — Inimigos e chefe (plano detalhado, 11/11/2026)

### Como fica a luta
- **Bandido arqueiro:** mantém distância (6 a 9 m) e atira flechas. Uma linha vermelha no chão avisa o tiro; dá para rolar para fugir.
- **Orc:** golpe pesado de clava com aviso em círculo no chão (o mesmo de hoje, agora com modelo).
- **Esqueleto mineiro:** só na mina; golpe de picareta para a frente, mais rápido que o do bandido.
- **Golem de pedra:** guardião do portão no fundo da mina (mini-chefe, barra de vida no topo da tela). Soco duplo à frente e pancada no chão em volta dele. Antes de lutar, bate no peito (aviso).
- **Gorvan, o Arauto da Colheita:** luta no **Celeiro do Tributo**, um salão novo atrás do portão da mina, cheio da comida roubada (feito com peças que já temos). A entrada fecha durante a luta.
  - **Forma 1 (mordomo com foice):** golpe de foice em arco, giro com a foice, e chama 2 bandidos uma vez.
  - **Metade da vida:** ele se transforma no **Espantalho Colossal** (pausa curta com clarão e troca de modelo).
  - **Forma 2:** maior e mais lento; giro com foice gigante, três pancadas seguidas no chão onde o Lio está, e corvos de palha (projéteis) quando o Lio fica longe.
- **Drops:** moedas de ouro saltam do inimigo e vêm até o Lio; materiais (couro de orc, osso velho, fragmento de pedra, palha dourada) somam num contador e aparecem num aviso. Eles serão usados no ferreiro da Fase 5.

### Missão e final do Ato 1
- **"O Arauto da Colheita"** (principal, começa depois de explorar a mina): derrotar o Golem → entrar no celeiro → derrotar o Gorvan → voltar para a Marta.
- Depois da vitória: a vila muda (mais comida nas barracas, NPCs com falas novas) e uma conversa final com Bram e Bento em que o Lio decide partir ("Se tem mais cinco desses, alguém precisa dar um jeito").
- O prólogo e a tela inicial continuam na 4.5.

### O que gerar no Meshy
| Asset | Passos | Créditos |
|---|---|---|
| Orc | imagem (3) + 3D (15) + esqueleto (5) + parado, golpe pesado, levar dano, morrer (12) + clava (15) | 50 |
| Bandido arqueiro | nova textura do bandido (10) + esqueleto (5) + parado, tiro com arco, levar dano com arco, morrer (12) + arco (15) | 42 |
| Esqueleto mineiro | imagem (3) + 3D (15) + esqueleto (5) + parado, golpe de machado, levar dano, morrer (12) + picareta (15) | 50 |
| Golem de pedra | imagem (3) + 3D (15) + esqueleto (5) + parado, soco duplo, pancada no chão, bater no peito, levar dano, morrer (18) | 41 |
| Gorvan, forma 1 | imagem (3) + 3D (15) + esqueleto (5) + parado, foice em arco, giro, golpe pesado, levar dano, bater no peito (18) + foice (15) | 56 |
| Gorvan, forma 2 (Espantalho Colossal) | imagem (3) + 3D (15) + esqueleto (5) + parado, foice em arco, giro, pancada no chão, morrer (15); usa a mesma foice, maior | 38 |
| **Total** | | **277** |

Margem para refazer (~20%): ~55. Com isso a Fase 4 fica em ~1.250 dos ~1.300 previstos, sobrando ~50 para o prólogo (4.5).

### Ordem
1. Código primeiro (sem créditos): ataques variados por inimigo, arqueiro, chefe com fases, barra do chefe, drops, celeiro, missão e testes, com bonecos provisórios.
2. Meshy na ordem: imagens dos 5 personagens → te mostro → modelos 3D, esqueletos, animações e armas.
3. Fotos e o robô de testes lutando contra o Gorvan; você aprova e eu envio.

## Áudio: precisa de uma decisão sua
O plano é usar a **ElevenLabs** (IA de efeitos e música, com conector para o Claude). Para vender o jogo, os sons precisam ser gerados num **plano pago** da ElevenLabs. Opções:
- **(a) Assinar a ElevenLabs** antes da etapa 4.4. Os planos e preços atuais estão no site deles. Depois é só conectar, como fizemos com o Meshy.
- **(b) Começar com sons gratuitos** (bibliotecas CC0, como a Kenney) e trocar por sons da ElevenLabs mais tarde.

A etapa 4.4 é a quarta, então dá tempo de decidir.

## Espaço no GitHub
Os modelos da Fase 3 ocuparam ~100 MB no Git LFS. Pelos limites do plano grátis do GitHub, devemos chegar perto do limite durante a Fase 4 ou 5. Antes disso, vou **reduzir as texturas para 1K** (o celular não precisa de 2K), o que deve cortar o tamanho pela metade. Se ainda assim faltar espaço, o GitHub vende pacotes de dados extras.
