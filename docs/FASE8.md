# Fase 8 — Novas mecânicas (pedido do dono, 13/11/2026)

O jogo já tem combate, chefes, ferreiro, pós-jogo e rotina. A Fase 8 deixa ele mais gostoso de jogar todo dia. O companheiro fica para depois (o dono pediu).

Tudo é feito por dados em `data/` como o resto do jogo. Cada parte tem seus testes no `test_runner` e fotos de conferência antes de ir para o dono.

## Ordem de produção

| # | Parte | O que entra | Meshy (estimado) |
|---|---|---|---|
| A | Combate | Defesa e aparar, monstro tonto com estrelinhas, Despertar com história | 42 cr (feito) |
| B | Covis do Ferreiro Andarilho | NPC novo em cada cidade, 5 covis de chefe, 5 conjuntos com combos, licenças | ~90 cr |
| C | Runas e elementos | 1 runa por skill, fogo/gelo/raio/sangue/luz, fraquezas dos monstros | ~15 cr |
| D | Pesca e fogueira | Pescar nos lagos e rios, peixes por lugar e hora, cozinhar comidas com bônus | ~55 cr |
| E | Bestiário e Maestria | Ficha de cada monstro com bônus por abates; pontos depois do nível 100 | ~10 cr |
| F | Casa do herói | Casa em Pradoluz com baú, troféus, armas expostas e cama (bônus de XP) | ~25 cr |
| G | Eventos do mundo | Horda noturna, caravana, chefe errante, chuva de estrelas | ~10 cr |
| H | Fenda sem fim | Andares aleatórios, bênçãos a cada 5 andares, recorde | ~30 cr |

**Total estimado: ~260 créditos, ~340 com folga para refazer o que não ficar bom.** Saldo em 13/11: **962 créditos**. Não precisa recarregar.

---

## A. Combate

### Defesa e aparar (sem escudo)
- **Decisão:** o Lio continua com **uma espada só**, sem escudo. Ganha um **botão de Defesa** e defende com a própria lâmina. Escudo mudaria todas as animações de golpe e os visuais.
- **Segurar Defesa:** o Lio fica em guarda, o dano de frente cai 70% e ele gasta fôlego a cada golpe que segura. Sem fôlego, a guarda quebra e ele fica um instante sem reação.
- **Apertar no tempo certo (aparar):** até 0,25 s antes do golpe chegar.
  - O inimigo é **empurrado para trás, desequilibrado**, e fica **tonto com estrelinhas girando na cabeça**: 2 s nos monstros comuns e 1 s nos chefes. Tonto, ele leva +30% de dano.
  - O Lio ganha MP e enche a barra do Despertar.
  - Tem brilho, faísca e um som próprio.
- **Animações:**
  - O Lio ganha a de guarda e a de aparar.
  - Todos os inimigos com esqueleto usam o mesmo par: uma de **desequilíbrio** (empurrado para trás) e uma de **tontura**. Como todos têm o mesmo esqueleto do Meshy, uma animação serve para todos, como os moradores já fazem.
  - Os monstros sem esqueleto (lodo, espíritos) balançam por código.
- **O que dá para aparar:**
  - golpes de frente, inclusive os dos chefes: aparar e segurar;
  - investidas: só segurar;
  - golpes em área (círculo, chão marcado, chuva de golpes), flechas e magias: só desviando.

### Despertar (a fúria)
- **História:** ao vencer a Sahra (2ª cidade), a cena "O Despertar do Herdeiro" mostra a luz dourada do nascimento de Lio voltando.
- **Efeitos:** cabelo dourado e brilhante, aura de luz dourada com faíscas e **+50% em todos os status por 12 s**.
- **Difícil de conseguir:** a luz enche devagar lutando, mais ao aparar e ao vencer chefes, e esvazia fora de luta. Em luta normal, cerca de 1 vez a cada 3–4 minutos.
- **Sem botão próprio:** com a luz cheia, segurar **Atacar por 3 s** desperta. A borda do botão Atacar mostra:
  - a luz enchendo (dourada, por dentro);
  - o segurar (vermelha, por fora);
  - o tempo que resta do Despertar (vermelha, esvaziando).

### HUD compacto
- **Correr e Esquiva:** continuam onde estavam.
- **Defesa:** em cima da 4ª skill.
- **Abrindo espaço:** minimapa menor e no topo, relógio menor.
- **Conferência:** o teste confere que nenhum botão encosta em outro nem no minimapa.

---

## B. Covis do Ferreiro Andarilho

### O ferreiro
- O **Ferreiro Andarilho** é um NPC novo, com o mesmo modelo nas 5 cidades.
- Ele forja os **equipamentos de chefe**, que dão **combos**, e abre o **covil do chefe da região**.

### Covis
- Cada covil é uma arena pequena com o chefe da região e alguns ajudantes.

| Cidade | Covil | Nível do conjunto |
|---|---|---|
| Pradoluz | Covil do Gorvan | 10 |
| Qaressa | Covil da Sahra | 25 |
| Hrimvald | Covil do Brannoc | 40 |
| Lysthael | Covil da Velyra | 55 |
| Altarea | Covil do Vaelor | 60 |

- **Dias:** os covis abrem **segunda, quarta, sexta e domingo**.
- **Entradas:** 10 por dia, somando todos os covis. Passou disso, cada entrada gasta 1 **Licença do Covil**.
- **Prêmios:** o chefe do covil **não solta peça pronta**. Solta:
  - **Fragmentos do chefe** (sempre, 2 a 4), usados para forjar a peça **rara (azul)**;
  - **Essência do chefe** (1 a cada 2 vitórias, em média), usada para promover a peça a **épica**.

### Receitas no Ferreiro Andarilho
- **Peça rara:** fragmentos + ouro. A arma pede 12 fragmentos, as outras peças 8 cada.
- **Promover a épica:** a peça rara forjada + **10 Essências do chefe** + ouro.
- **Conjunto completo:** 8 peças (arma, elmo, peitoral, luvas, calça, botas, pulseira e cinto).
- **Arma do conjunto:** a arma do próprio chefe (a foice do Gorvan, o khopesh da Sahra, o machado do Brannoc, a lâmina de espinhos da Velyra e a espada do Vaelor), ajustada na mão do Lio.

### Combos (bônus de conjunto)
Os combos são feitos para o guerreiro e ligados às skills dele. Vestindo 2, 4, 6 e 8 peças do mesmo chefe:

| Conjunto | 2 peças | 4 peças | 6 peças | 8 peças |
|---|---|---|---|---|
| **Colheita Rubra** (Gorvan) | +8% ataque | Golpe comum tem 15% de chance de ceifar em volta | Matar um inimigo cura 3% da vida | Corte Giratório puxa os inimigos e dura +50% |
| **Tempestade de Areia** (Sahra) | +6% velocidade de ataque | Todo 4º golpe comum solta uma onda de areia | Esquiva deixa um redemoinho que deixa lento | Investida deixa rastro de areia que cega (inimigos erram) |
| **Coroa de Gelo** (Brannoc) | +10% defesa | Aparar perfeito congela o inimigo 1,5 s | Tomar dano diminui a recarga das skills | Golpe Sísmico vira avalanche de gelo (+30% de dano) |
| **Coração de Espinhos** (Velyra) | +8% vida máxima | Devolve 20% do dano corpo a corpo recebido | Críticos fazem sangrar | Salto Devastador deixa um campo de espinhos |
| **Juramento Celeste** (Vaelor) | +5% em todos os status | Barra do Despertar enche 30% mais rápido | No Despertar, golpes soltam raios de luz | Julgamento chama mais 3 espadas de luz |

- Na versão **épica**, os mesmos combos ficam mais fortes (+50% nos números).
- Peças de chefes diferentes não somam o mesmo combo, mas dá para misturar, por exemplo 4 de um com 4 de outro.

### Loja do Google Play
- **Produto novo:** `licenca_covil_10`, com 10 Licenças do Covil, por **R$ 3,99** (consumível).

---

## C. Runas e elementos
- **Encaixe:** cada skill equipada ganha 1 encaixe de runa.
- **Runas:** caem de chefes, do quadro de missões e da Fenda.

| Runa | Efeito |
|---|---|
| **Fogo** | Deixa o chão queimando |
| **Gelo** | Deixa lento e, às vezes, congela |
| **Raio** | Salta para mais 2 inimigos |
| **Sangue** | Cura uma parte do dano |
| **Luz** | Mais dano em chefes e em mortos-vivos |
| **Eco** | A skill repete com metade da força |

- **Níveis:** cada runa tem 3 níveis. 3 runas iguais viram 1 do nível seguinte, no Ferreiro.
- **Elementos:** cada monstro tem fraqueza e resistência em `enemies.json`.
  - Exemplos: mortos de gelo fracos a fogo; criaturas do deserto fracas a gelo; cultistas fracos a luz.
  - No acerto aparece **"Fraco!"** em amarelo ou **"Resiste"** em cinza.
  - O bestiário mostra a fraqueza depois de 50 abates.

## D. Pesca e fogueira
- **Pescar:**
  - perto de lago ou rio, o botão de ataque vira **"Pescar"** (como o "Acariciar");
  - o Lio usa a vara de pesca, que já existe no jogo;
  - a boia afunda e o jogador aperta no tempo certo;
  - depois vem uma barra de tensão: segura para puxar e solta se ficar vermelha.
- **Peixes:** cerca de 10 tipos. Dependem do lugar (rio, lago, pântano, gelo) e da hora; alguns só saem de noite e um é lendário e raro. Dá para vender ou cozinhar.
- **Fogueira:** nas cidades e ao lado das pedras de descanso.
  - Peixe com ingrediente (ervas e carnes que caem dos vasos e dos monstros) vira comida.
  - Cada comida dá um bônus de 10 min, como +ataque, regeneração de MP ou +fôlego.
  - Vale 1 comida por vez.

## E. Bestiário e Maestria
- **Bestiário:**
  - uma ficha por monstro, com foto 3D, texto curto e onde aparece;
  - aos 50, 200 e 1000 abates dá +2%, +4% e +6% de dano contra ele;
  - aos 50 abates mostra a fraqueza.
- **Maestria:**
  - depois do nível 100, a XP continua enchendo uma barra;
  - cada barra cheia dá 1 ponto;
  - os pontos vão em 4 ramos (Ataque, Defesa, Vida, Utilidade), com bônus pequenos e sem limite.

## F. Casa do herói
- **Compra:** a casa fica em Pradoluz e é comprada com ouro. Usa os interiores que já existem.
- **Baú:** guarda +40 espaços.
- **Parede de troféus:** os Procurados vencidos e os chefes dos covis.
- **Suporte de armas:** mostra as armas lendárias que o herói tem.
- **Cama:** dormir dá **"Descansado"**, +10% de XP por 30 min (1 vez por dia).

## G. Eventos do mundo
Acontecem de vez em quando nos campos, com aviso no topo da tela e no máximo 1 por vez:
- **Horda noturna:** de noite. Ondas de monstros, e o baú do fim é bom.
- **Caravana:** escoltar um comerciante até a próxima cidade.
- **Chefe errante:** um monstro grande que anda pelo mapa por 10 min.
- **Chuva de estrelas:** de noite. Pedrinhas brilhantes caem e viram material raro.

## H. Fenda sem fim
- **Abertura:** a partir do nível 30, por um portal em Pradoluz.
- **Andares:**
  - arenas sorteadas com o visual dos mapas que já existem;
  - os monstros ficam mais fortes a cada andar;
  - a cada 5 andares, o jogador escolhe 1 de 3 **bênçãos** que valem até sair (ex.: "skills custam metade do MP", "matar cura 5%", "+1 golpe no combo");
  - a cada 10 andares, um chefe.
- **Recorde:** fica guardado e aparece na tela de rotina.
- **Prêmios:** os melhores (runas e essências) contam só nas 3 primeiras descidas do dia. Depois disso dá para continuar jogando pelo recorde.

## Meshy — o que será gerado

| O que | Para quê | Créditos |
|---|---|---|
| Animações do Lio: guarda, aparar, desequilíbrio, tontura, despertar e ajoelhar | Combate, fogueira, inimigos (as de desequilíbrio e tontura servem para todos) | ~20 |
| Ferreiro Andarilho (modelo, rig, 2–3 animações) | NPC dos covis | ~35 |
| Ícones: 40 peças dos conjuntos (3 folhas) | Tela da mochila e do ferreiro | ~27 |
| Ícones: fragmentos, essências, licença, runas, peixes e comidas (2 folhas) | Itens novos | ~18 |
| Fogueira com panela | Cozinhar | ~20 |
| Peças da casa: baú grande, suporte de armas e cama | Casa do herói | ~25 |
| Portal da Fenda | Entrada da Fenda | ~20 |
| Arte da tela de carregamento: covil e Fenda | Carregamento | ~12 |
| Ícones das bênçãos, do bestiário e da maestria (1 folha) | Interface | ~9 |
| Folga para refazer | — | ~80 |

Nada entra em `assets/` sem o dono aprovar o visual.
