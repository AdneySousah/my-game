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
| 4.3 | **Inimigos e chefe** | Orc, bandido arqueiro, esqueleto mineiro e Golem de pedra com modelos; Gorvan com 2 formas; drop de ouro e materiais |
| 4.4 | **Áudio** | Sistema de som com volumes; efeitos de combate, das 8 skills, passos, interface; música da vila, da floresta, da mina e do chefe |
| 4.5 | **Prólogo e save** | Prólogo em ilustrações; tela inicial; salvar e continuar (save local, já criptografado) |

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

## Áudio: precisa de uma decisão sua
O plano é usar a **ElevenLabs** (IA de efeitos e música, com conector para o Claude). Para vender o jogo, os sons precisam ser gerados num **plano pago** da ElevenLabs. Opções:
- **(a) Assinar a ElevenLabs** antes da etapa 4.4. Os planos e preços atuais estão no site deles. Depois é só conectar, como fizemos com o Meshy.
- **(b) Começar com sons gratuitos** (bibliotecas CC0, como a Kenney) e trocar por sons da ElevenLabs mais tarde.

A etapa 4.4 é a quarta, então dá tempo de decidir.

## Espaço no GitHub
Os modelos da Fase 3 ocuparam ~100 MB no Git LFS. Pelos limites do plano grátis do GitHub, devemos chegar perto do limite durante a Fase 4 ou 5. Antes disso, vou **reduzir as texturas para 1K** (o celular não precisa de 2K), o que deve cortar o tamanho pela metade. Se ainda assim faltar espaço, o GitHub vende pacotes de dados extras.
