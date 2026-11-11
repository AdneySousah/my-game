# Documento de Design (GDD) — versão 0.1

Base: as suas respostas em [BRIEFING.md](BRIEFING.md). O que foi ideia minha está marcado com **✱**. Pode trocar qualquer coisa.

As perguntas que ainda dependem de você estão no fim, em **"Decisões pendentes"**.

---

# Parte 1 — Visão geral

| | |
|---|---|
| **Nome (proposta ✱)** | **Herdeiro dos Céus** (em inglês: *Skyborn Heir*) |
| **Gênero** | RPG de ação 3D, câmera isométrica, um herói |
| **Era** | Fantasia medieval clássica, sem magia para o jogador, com ruínas antigas |
| **Tom** | Equilibrado e com humor. Mundo de esperança, mesmo sob opressão |
| **Visual** | Low-poly, estilo chibi, cores vibrantes |
| **Plataformas** | Android (principal) e Windows |
| **Duração** | História principal ≈ 12–14 h (termina perto do nível 65). Nível 100 ≈ 30 h |
| **Referência de sensação** | A emoção de evoluir de "ninguém" para "o mais forte" num mundo perigoso |

**Outros nomes que considerei ✱:** *Lâmina Sem Deuses* (*Godless Blade*) e *O Filho do Céu Partido*. "Herdeiro dos Céus" já antecipa a reviravolta (ele é filho do deus) sem estragar a surpresa. Antes de fechar, vamos checar se o nome está livre na Play Store.

---

# Parte 2 — Mundo

## O mundo de Varenthia ✱
Um continente de campos, desertos, montanhas geladas e florestas antigas. Há séculos não existem deuses. Os reinos viviam em paz, mas pobres, até que **há 19 anos** surgiu no céu **Vaelor, o Soberano Alado**. Ele se declarou deus e nomeou **cinco Arautos**, um para cada grande cidade.

Desde então, cada cidade vive sob a "proteção" do seu Arauto, que controla **o recurso de que ela mais precisa**. Ninguém passa fome nem frio por completo, porque o povo tem que continuar trabalhando. Mas ninguém tem o bastante para ser livre. A obediência é recompensada com rações, e a desobediência é castigada com escassez.

**As ruínas antigas** espalhadas pelo continente são restos de uma civilização que, segundo as lendas, "subiu ao céu". Elas funcionam como dungeons e escondem os melhores materiais do jogo e pistas sobre a origem dos deuses.

**Sem magia:** só os deuses e os Arautos têm poderes sobrenaturais. Os humanos lutam com aço, técnica e coragem. A única exceção é Lio, que nasceu com uma força que ninguém explica.

## A ideia dos recursos controlados
Gostei muito da sua ideia, e ela virou a base do mundo. Cada Arauto controla uma necessidade básica, e libertar a cidade devolve esse recurso ao povo. Isso também conecta as missões secundárias: elas mostram como cada pessoa sofre com a escassez.

---

# Parte 3 — Personagens

## Lio — o herói ✱ (nome sugerido)
- **19 anos**, de **Pradoluz**, uma vila de fazendeiros. Não é a capital, como você pediu.
- **Visual:** cabelo curto e espetado, **loiro dourado**, olhos cor de âmbar, sorriso convencido. Começa com **trapos de aprendiz**: túnica de linho remendada, cinto de corda, calça de pano e botas gastas.
- **Arma:** uma espada no começo, com a opção de **duas espadas** mais tarde. A biblioteca do Meshy tem animações para duas espadas, então é viável.
- **Personalidade:** piadista, impulsivo, coração enorme. Faz piada até nas piores horas, e isso irrita os vilões.
- **Quer:** ser um dos heróis mais fortes do mundo.
- **Descobre:** que força sozinha não basta, que o mundo é perigoso e que ser forte serve para libertar as pessoas, não para mandar nelas.
- **Envelhecimento ✱:** um **salto de 2 anos** depois da morte do Bento (Ato 3). Lio passa de 19 para 21 anos, fica mais alto e mais sério no visual, mas continua piadista. O modelo do herói muda nesse momento.

Outros nomes possíveis: **Ari**, **Teo**.

## Vaelor, o Soberano Alado — o deus (e pai)
- **Visual:** homem de cabelos brancos e longos, **asas** enormes e uma **lança**. Nunca anda: **flutua**, batendo as asas.
- **Nome humano:** **Doran**, fazendeiro de Pradoluz, pai de Lio.
- **Motivação:** controlar as cidades pela força e pelo medo. Ele acredita que só o controle total evita o caos, e que "um povo livre se destrói sozinho".
- **O medo dele:** Lio é o único ser capaz de superá-lo.

## Marta ✱ — a mãe
Criou Lio sozinha em Pradoluz. Acredita que o marido foi devorado por lobos na noite do parto, porque só encontraram um dedo dele na neve. Ela é o porto seguro de Lio e o coração do primeiro ato.

## Mestre Bram ✱ — o mentor
Velho cavaleiro aposentado, caolho e sarcástico. Mora em Pradoluz e treina Lio "porque ninguém mais aguenta esse moleque". Conheceu Doran e guarda um segredo: o dedo encontrado tinha um corte limpo de faca, não de dente. Ele conta isso a Lio no Ato 4.

## Bento ✱ — o companheiro de viagem (não luta)
Ex-cozinheiro da capital, gordinho, tagarela e medroso, mas de coração enorme. Viaja com Lio desde o Ato 1. Junto com Lio, forma a dupla cômica do jogo.
- **Destino:** no **Ato 3**, entra na frente do golpe do Arauto do Frio para salvar Lio e morre. É a virada emocional do jogo e o gatilho do salto de 2 anos.

## Severin Vale ✱ — o rival
Cavaleiro da Ordem Celeste: sério, disciplinado, cabelo escuro, armadura pesada, **espadão de duas mãos**. É o oposto de Lio em tudo.
- **Ideologia:** acredita que os deuses trouxeram ordem e equilíbrio, e que a liberdade de Lio levaria o mundo ao caos.
- **Arco:**
  - **Ato 2:** vence Lio (luta que o jogador não pode ganhar).
  - **Ato 3:** empate.
  - **Ato 4:** perde e vê a crueldade da Arauta Velyra. Começa a duvidar.
  - **Ato 5:** segura os portões da capital para Lio subir até Vaelor.

## O Sem-Rosto ✱ — a ameaça escondida
O "ser divino" que encontrou Doran e mostrou a ele o que ele poderia ter. Ele corrompeu Doran e lhe deu poder. Fica nas sombras o jogo todo. No final ele **escapa**, e isso deixa o gancho para a continuação e as DLCs.

## Comerciantes e ferreiros
Cada cidade tem **um comerciante** (com loja de ouro) e **um ferreiro**. O ferreiro cria equipamentos, faz o fortalecimento, coloca gemas, abre encaixes, desmonta itens e restaura equipamento quebrado. A Parte 6 detalha esses sistemas.

| Cidade | Comerciante ✱ | Ferreiro ✱ |
|---|---|---|
| Pradoluz | Dona Celeste (armazém da vila) | Tobias, o ferreiro gago |
| Qaressa | Zahir, o regateador | Nadira, forjadora do oásis |
| Hrimvald | Velho Osk | Brunhild, a martelo |
| Lys'Thaël | Elarion | Faenor, entalhador de lâminas |
| Altaréa | Casa Moreau (loja nobre) | Mestre Aurélio, forja real |

---

# Parte 4 — As 5 cidades

Você pediu 5 cidades, e o jogo comporta. Cada cidade tem: um **Arauto** (chefe com duas formas), um **recurso controlado**, **áreas de exploração** e **dungeons**.

| # | Cidade ✱ | Tema | Arauto ✱ | Recurso controlado | Exploração | Dungeons | Níveis |
|---|---|---|---|---|---|---|---|
| 1 | **Pradoluz** | Vila de fazenda (terra natal) | **Gorvan, Arauto da Colheita** | Comida: leva 3/4 da colheita como "tributo divino" | Floresta Sussurrante | Mina dos Corvos (mina abandonada) | 1–12 |
| 2 | **Qaressa** | Cidade no deserto, entre dunas e um oásis | **Sahra, Arauta da Sede** | Água: lacrou os poços e vende água | Dunas de Ossos | Ruínas de Ammar (ruínas antigas), Torre Afundada | 12–28 |
| 3 | **Hrimvald** | Fortaleza na neve | **Brannoc, Arauto do Frio** | Calor: guarda toda a lenha e o carvão | Picos Uivantes | Mina de Gelo Esquecida, Castelo Ermo | 28–42 |
| 4 | **Lys'Thaël** | Cidade élfica nas árvores | **Velyra, Arauta do Silêncio** | Vida: proibiu os cantos e drena a Árvore-Mãe, e a floresta murcha | Pântano das Raízes | Torre do Vigia Élfico | 42–55 |
| 5 | **Altaréa** | Capital | **Cassian, Arauto da Lei** | Liberdade: toque de recolher, decretos, trabalho forçado | Arredores da Capital | Castelo do Arauto, **Escadaria do Céu → Cidadela Celeste** (final) | 55–65 |

## Os Arautos e as duas formas
Como você pediu, os Arautos são pessoas comuns com poderes diferentes, e são metamorfos. No combate, mudam de forma, mas continuam humanoides (exigência do rig do Meshy).

| Arauto | Forma 1 | Forma 2 (metade da vida) |
|---|---|---|
| Gorvan | Mordomo gordo e risonho, com uma foice | **Espantalho Colossal**: corpo de palha e madeira, foice gigante |
| Sahra | Mercadora elegante, com lâminas curvas | **Guerreira de Areia**: corpo de areia viva, que se desfaz e reaparece |
| Brannoc | Velho senhor da fortaleza, com um machado | **Gigante de Gelo**: armadura de gelo, golpes que congelam o chão |
| Velyra | Elfa graciosa, com um arco de galho | **Dríade de Espinhos**: corpo de casca e espinhos, raízes que prendem |
| Cassian | Juiz de toga, com um martelo de julgamento | **Colosso de Armadura**: armadura gigante e vazia, movida pela "lei" |

## O chefe final: Vaelor (3 fases)
1. **Lança:** flutua, investe com a lança e cria ventos com as asas.
2. **Asas de luz:** voa alto e manda chuvas de penas cortantes. Lio precisa usar as ruínas da cidadela.
3. **Corrompido:** as asas ficam negras, porque o Sem-Rosto toma o controle. É a fase mais difícil e a mais emocional.

## Viagem e mapa
Mundo semiaberto. As cidades são ligadas por estradas e áreas de exploração. A ordem principal segue a história, mas cada região tem áreas e dungeons opcionais.
- **Pedras de Passagem (teleporte):** todas as cidades têm uma. Depois de visitada, dá para voltar a qualquer cidade pelo teleporte.
- **Pontos de descanso nas áreas de aventura:** cada campo e cada área com monstros tem pontos de descanso (checkpoints) a cada trecho, para a caminhada nunca ficar longa demais. Eles servem para:
  - voltar a jogar dali depois de morrer;
  - teleportar para lá também, depois de ativados.
- **Dungeons:** um ponto na entrada e outro no meio (antes do chefe) ✱.

---

# Parte 5 — História

## Prólogo — "A noite do brilho"
- **Cena 1:** noite de inverno em Pradoluz. Marta dá à luz, e **o bebê brilha** com uma luz dourada que ilumina a vila inteira.
- **Cena 2:** Doran olha o filho, depois a casa pobre, e entra em pânico ("como vou criar *isso*?"). Ele foge pela neve. Corta o próprio dedo e o deixa entre pegadas de lobo, para pensarem que foi devorado.
- **Cena 3:** no meio da tempestade, uma figura sem rosto aparece para Doran e mostra visões de um mundo inteiro aos pés dele. "Você nunca mais vai ter medo."
- **Cena 4:** meses depois, um homem alado surge nos céus de Varenthia. No alto de uma torre, ele olha para o sul, em direção a Pradoluz, **preocupado**.
- Corte para **19 anos depois**.

**Como fazer as cenas ✱:** painéis ilustrados no estilo de quadrinho, gerados como imagem no Meshy (≈ 3 a 9 créditos cada), com texto e leve movimento de câmera. É barato e combina com o estilo chibi. Os diálogos durante o jogo usam os próprios modelos 3D com retratos dos personagens.

## Ato 1 — Pradoluz (nível 1–12)
- Lio treina com Bram e faz piada com tudo. A vila passa fome por causa do tributo de Gorvan.
- **Bento** chega fugido da capital, depois de ser expulso da cozinha real, e vira o "sócio" de Lio.
- Lio enfrenta bandidos e orcs na Floresta Sussurrante e explora a Mina dos Corvos.
- **Chefe:** Gorvan. A vila volta a comer. Lio decide partir: "Se tem mais cinco desses, alguém precisa dar um jeito."

## Ato 2 — Qaressa (nível 12–28)
- O deserto e a cidade, onde a água é vendida a peso de ouro.
- **Primeiro encontro com Severin:** Lio perde feio. Humilhado, descobre que o mundo é maior do que ele imaginava.
- Nas Ruínas de Ammar, o primeiro mural mostra "homens que subiram ao céu".
- **Chefe:** Sahra. Os poços são reabertos.

## Ato 3 — Hrimvald (nível 28–42)
- Fortaleza gelada, com o povo morrendo de frio. Lio e Bento organizam a resistência.
- **Segundo duelo com Severin:** empate.
- **Chefe:** Brannoc. Na luta, **Bento entra na frente do golpe e morre**.
- **Salto de 2 anos ✱:** Lio treina sozinho nas montanhas. Volta mais forte e mais sério, mas ainda faz piada, agora "pelo Bento".

## Ato 4 — Lys'Thaël (nível 42–55)
- A floresta élfica murchando em silêncio.
- **Terceiro duelo:** Severin perde e vê Velyra quase matar crianças élficas por cantarem. **Ele começa a duvidar.**
- **Bram revela** o segredo do dedo: corte de faca. Doran pode estar vivo.
- **Chefe:** Velyra. A Árvore-Mãe volta a florescer.

## Ato 5 — Altaréa (nível 55–65)
- A capital sob a lei de ferro de Cassian. Revolta nas ruas.
- **Chefe:** Cassian. **Severin se junta a Lio** e segura os portões da cidade.
- **Escadaria do Céu → Cidadela Celeste:** luta contra Vaelor.
- **Reviravolta:** no meio da luta, Vaelor mostra a mão sem um dedo, e Lio entende que **o deus é o pai dele**.
- **Final:** Lio vence. Doran, livre da corrupção por um instante, pede perdão. O Sem-Rosto arranca o que resta do poder dele e **escapa para além do céu**.
- **Final aberto:** as cidades estão livres, mas "algo maior olha para Varenthia". Gancho para continuação e DLCs.

## Pós-jogo (nível 65–100)
- Dungeons no **Modo Infernal** (veja a Parte 6).
- Farm de conjuntos lendários, fortalecimento até +20, títulos e conquistas.
- Missões diárias e calendário de login continuam.

## Missões secundárias
Poucas e caprichadas, como você pediu: **4 a 6 por cidade**, cada uma com uma história curta sobre como aquela pessoa sofre com o recurso controlado. Exemplos ✱:
- **Pradoluz:** a menina que esconde trigo para a avó doente.
- **Hrimvald:** o velho que queima os próprios móveis para aquecer os netos.

---

# Parte 6 — Sistemas

## 6.1 Progressão e XP
- Nível máximo **100**. A história termina perto do **nível 65**.
- Tempo estimado (jogando no ritmo normal, com missões):

| Nível | Tempo para subir 1 nível | Tempo total |
|---|---|---|
| 10 | ~5 min | ~0,8 h |
| 20 | ~7 min | ~1,8 h |
| 30 | ~10 min | ~3,2 h |
| 40 | ~13 min | ~5,1 h |
| 50 | ~17 min | ~7,6 h |
| 65 | ~23 min | ~12,6 h (fim da história) |
| 80 | ~29 min | ~19 h |
| 100 | ~39 min | **~30 h** |

- **XP para subir de nível (proposta):**

| Nível | XP para o próximo | XP de um inimigo comum do nível |
|---|---|---|
| 1 | 240 | 10 |
| 5 | 320 | 12 |
| 10 | 490 | 16 |
| 20 | 1.200 | 28 |
| 30 | 2.800 | 47 |
| 40 | 6.300 | 81 |
| 50 | 14.000 | 138 |
| 60 | 29.000 | 235 |
| 65 | 42.000 | 308 |
| 70 | 60.000 | 402 |
| 80 | 120.000 | 687 |
| 90 | 240.000 | 1.173 |
| 99 | 440.000 | 1.900 |

- Inimigos muito abaixo do seu nível dão pouco XP (−10% por nível de diferença, mínimo 10%). Isso evita "farmar fácil".
- As tabelas completas ficam em arquivos de dados e serão ajustadas nos testes.

## 6.2 Atributos
A cada nível, o jogador ganha **5 pontos** para distribuir em 4 atributos ✱. Além disso, o herói ganha automaticamente **+20 de vida, +2 de ataque e +1 de defesa** por nível.

| Atributo | O que faz (por ponto) |
|---|---|
| **Força** | +2 de ataque; +0,3% de dano crítico |
| **Vitalidade** | +15 de vida; +1 de defesa |
| **Agilidade** | +0,3% de velocidade de ataque; +0,1% de chance de crítico; +0,1% de esquiva |
| **Foco** | −0,15% de tempo de recarga das skills (máximo −30%); +0,2% de dano das skills |

- **Por que 5 pontos:** chegam a ~495 pontos no nível 100. É o bastante para criar estilos diferentes, como o "tanque" (Vitalidade), o "crítico" (Agilidade + Força) e o "skills" (Foco).
- **Redistribuir pontos:** item "Pergaminho do Recomeço", ganho em missões e vendido na loja ✱.

## 6.3 Skills (8 opções, 4 equipadas)
Sem escudo, como você pediu. Todas usam animações que **existem na biblioteca do Meshy**.

| # | Skill ✱ | Efeito principal | Animação do Meshy |
|---|---|---|---|
| 1 | **Corte Giratório** | Dano em área ao redor | Double Blade Spin / Axe Spin Attack |
| 2 | **Investida** | Avança e **atordoa** (stun) por 1 s | Thrust Slash |
| 3 | **Golpe Sísmico** | Bate no chão: dano em cone e **lentidão** | Charged Ground Slam |
| 4 | **Brado de Guerra** | +25% de ataque por 8 s; inimigos próximos causam −15% de dano | Chest Pound Taunt |
| 5 | **Quebra-Guarda** | Golpe pesado: **quebra defesa** (−30% por 6 s) | Charged Slash |
| 6 | **Onda de Corte** | Lança uma onda de pressão em linha que joga inimigos para o alto | Charged Upward Slash |
| 7 | **Julgamento** | Dano enorme em um alvo; +50% em inimigos com menos de 30% de vida | Sword Judgment |
| 8 | **Salto Devastador** | Salta até uma área e **atordoa** todos ali | Jump Attack |

- **Ataque básico:** combo de 3 golpes (Triple Combo Attack). Com duas espadas: Double Combo Attack.
- **Esquiva ✱:** um botão extra de rolamento (Roll Dodge), com recarga curta. Recomendo muito: é o que dá "sensação" ao combate no celular.
- **Liberação:** todas as 8 skills estão liberadas até o **nível 30**:

| Nível | Skill liberada | Por que nessa ordem ✱ |
|---|---|---|
| 1 | Corte Giratório | Primeira skill: dano em área, ótima para aprender |
| 4 | Investida | Primeiro controle (stun) e mobilidade |
| 8 | Golpe Sísmico | Primeira lentidão |
| 12 | Quebra-Guarda | Chega junto com os inimigos com mais defesa do deserto. Os 4 botões ficam cheios |
| 16 | Brado de Guerra | Primeira skill de reforço; o jogador começa a escolher o que equipar |
| 20 | Onda de Corte | Primeiro ataque à distância |
| 25 | Salto Devastador | Stun em área, para grupos grandes |
| 30 | Julgamento | A mais forte em um alvo só, para os chefes da metade do jogo |
- **Evolução:** **1 ponto de skill por nível** (+ recompensas de missões). Cada skill vai até o **nível 15**. Nos níveis **5, 10 e 15**, ganha um efeito extra. Exemplo do Corte Giratório: nível 5 gira 2 vezes; nível 10 puxa os inimigos; nível 15 deixa um rastro que causa dano.
- Até o fim da história (~65), dá para evoluir bem umas 5 skills. No nível 100, quase todas. As escolhas pesam durante a história, e no pós-jogo dá para testar combinações.

## 6.4 Equipamentos

**Espaços de equipamento:**
- **Armas:** espada principal + espada secundária (só no estilo de duas espadas).
- **Armadura (5 peças):** elmo, peitoral, luvas, calça e botas.
- **Acessórios (3 peças):** 2 pulseiras e 1 cinto.
- **Fantasia:** espaço reservado para o pós-lançamento.

**Estilos de arma ✱:**
- **Uma espada:** golpes mais fortes (+20% de dano por golpe) e +10% de dano crítico.
- **Duas espadas:** golpes mais rápidos (+35% de velocidade de ataque), com menos dano por golpe.

**Raridades:** Comum (branco), Raro (azul), Épico (roxo) e Lendário (dourado).

**Conjuntos:**
- **Armadura:** bônus com 3, 4 e 5 peças do mesmo conjunto.
- **Armas:** conjunto de 1 espada ou de 2 espadas.
- **Acessórios:** as 3 peças juntas dão uma **habilidade passiva** (ex.: "a cada 10 golpes, o próximo é crítico").
- Peças de conjunto são **Épicas ou Lendárias** e só saem do **ferreiro**, feitas com materiais de inimigos e de dungeons.

**Visual ✱:**
- **Armas:** sempre aparecem no personagem, porque são modelos separados presos à mão.
- **Armadura:** o visual muda **quando 3 ou mais peças do mesmo conjunto** estão equipadas. Cada conjunto é um modelo completo do herói, e fazer visual por peça avulsa seria caro demais em créditos.

## 6.5 Ferreiro: criação, fortalecimento, gemas e desmontagem

**Criação:** receitas que usam materiais de inimigos do mapa + materiais raros de dungeons + ouro.

**Encaixes:** saem aleatórios na criação, de 0 a 3 por peça ✱:

| Encaixes | Chance |
|---|---|
| 0 | 40% |
| 1 | 35% |
| 2 | 20% |
| 3 | 5% |

- Um Lendário pode sair sem encaixe, como você pediu.
- A **Broca de Engaste** tenta abrir um encaixe, até o limite de 3. Há duas versões:

| Encaixe a abrir | Broca comum (loja de ouro, login, drops) | Broca Real (loja com dinheiro real) |
|---|---|---|
| 1º | 100% | 100% |
| 2º | 50% ✱ | 100% |
| 3º | 25% ✱ | 100% |

  Se a Broca comum falhar, ela é gasta e o equipamento não muda.
- **Gemas ✱:** Rubi (ataque), Safira (vida), Esmeralda (crítico), Topázio (recarga), Ametista (defesa). Têm 5 níveis de qualidade.

**Fortalecimento de +1 a +20:**

| Faixa | Chance de sucesso por tentativa | Se falhar |
|---|---|---|
| +1 a +10 | 100% → 55% (−5% por nível) | Perde só os materiais |
| +11 a +15 | 50% → 30% | O equipamento **quebra**: não pode ser usado até ser **restaurado** no ferreiro (ouro + material) |
| +16 a +20 | 25% → 5% | O equipamento **some**, a não ser que esteja usando o **Amuleto de Proteção** |

- **Trevo de Fortificação:** usado na tentativa, troca a chance normal pela chance do trevo. Há duas versões:

| Fortalecer para | Sem trevo | Trevo comum (loja de ouro, login, drops) | Trevo Real (loja com dinheiro real) |
|---|---|---|---|
| +1 a +10 | 100% → 55% | 100% | 100% |
| +11 | 50% | 100% | 100% |
| +12 | 45% | 75% | 100% |
| +13 | 40% | 60% ✱ | 100% |
| +14 | 35% | 50% ✱ | 100% |
| +15 | 30% | 45% ✱ | 100% |
| +16 | 25% | 35% ✱ | 100% |
| +17 | 20% | 30% ✱ | 100% |
| +18 | 15% | 25% ✱ | 100% |
| +19 | 10% | 20% ✱ | 100% |
| +20 | 5% | 15% ✱ | 100% |

  Os valores de +11 e +12 são os seus. Do +13 em diante segui a mesma queda, sempre acima da chance normal.
- **Amuleto de Proteção:** se a tentativa falhar, o equipamento não quebra nem some. Vem do login (7º dia), da loja de ouro e da loja com dinheiro real.
- **Bônus de cada nível:** +4% nos atributos da peça (de +1 a +10), +6% (de +11 a +15) e +10% (de +16 a +20). Uma peça +20 tem **+120%** nos atributos.

**Desmontagem (no lugar da fusão):**
- Item **nunca equipado:** devolve **100%** dos materiais.
- Item **que já foi equipado:** devolve **50%**.

## 6.6 Economia e lojas

**Loja de ouro (comerciante de cada cidade):** equipamentos Comuns e Raros (sem conjunto), kits de poção, materiais de fortalecimento, **Trevo comum**, **Broca comum** e **Amuleto de Proteção**.

**Loja com dinheiro real (Google Play):** pacotes de ouro, pacotes de EXP (ex.: +50% de XP por 1 hora), pacotes de poções, **Trevo Real** (sucesso garantido no fortalecimento), **Broca Real** (encaixe garantido) e Amuleto de Proteção. As fantasias entram depois. Os preços serão definidos na Fase 5.

**Regra:** as versões comuns (Trevo e Broca) podem ser conseguidas jogando, mas têm chance de falhar nos níveis altos. As versões Reais garantem o sucesso. O jogo inteiro continua jogável sem pagar.

**Amostra grátis ✱:** o 28º dia do calendário de login dá **1 Trevo Real**, para o jogador sentir a diferença.

## 6.7 Missões diárias e login
- **5 missões diárias**, sorteadas de acordo com o seu nível (ex.: "derrote 30 homens-lagarto", "entregue 5 cristais", "vença uma dungeon"). Dão XP, ouro e materiais de criação.
- **Calendário de login de 28 dias ✱:** 6º, 13º, 20º e 27º dias → **Broca comum**. 7º, 14º, 21º e 28º dias → **Amuleto de Proteção**. O 28º dia ainda dá **1 Trevo Real** e um prêmio grande.
- **Funcionamento offline ✱:** o jogo usa o relógio do aparelho e bloqueia ganhos se detectar que a data foi voltada.

## 6.8 Conquistas e títulos
- Conquistas como "Derrote 1.000 orcs", "Chegue a +15" ou "Termine a Mina dos Corvos no Infernal" dão **títulos**.
- Você equipa **1 título por vez** e ganha o bônus dele (ex.: "Caçador de Orcs": +5% de dano em orcs).

## 6.9 Morte
- **Perde 10% do ouro** que carrega e **5% do XP** do nível atual. Nunca perde nível.
- Ganha o status **"Derrotado"**: **−5% em todos os atributos** por 5 minutos.
- Volta para o último ponto de descanso ativado (no campo ou na dungeon) ou para a última cidade.

## 6.10 Dificuldade
- Escolhida no início do jogo: **Fácil** (inimigos −25% de vida e dano; penalidade de morte pela metade), **Normal** e **Difícil** (inimigos +40%; +25% de XP e de drops).
- Dá para diminuir a dificuldade a qualquer momento nas cidades, mas não aumentar ✱.
- **Modo Infernal das dungeons:** libera depois de vencer a dungeon no modo normal. Inimigos com **+10 níveis**, **vida ×3** e **dano ×2**. Só nele caem os materiais dos conjuntos lendários.

## 6.11 Inimigos (só humanoides)
Para economizar créditos, cada inimigo base ganha versões com outra textura (Retexture) em outras regiões.

| Região | Inimigos |
|---|---|
| Pradoluz | Bandido, Bandido arqueiro, Orc, Esqueleto mineiro, Golem de pedra (chefe da mina) |
| Qaressa | Homem-lagarto, Esqueleto antigo, Bandido do deserto (outra textura) |
| Hrimvald | Morto-vivo congelado, Golem de gelo (outra textura), Orc da neve (outra textura) |
| Lys'Thaël | Cultista, Homem-lagarto do pântano (outra textura), Morto-vivo do pântano (outra textura) |
| Altaréa | Cavaleiro corrompido, Cultista de alto escalão (outra textura), Golem de guerra (outra textura) |

## 6.12 Futuro ("DLC de projeto")
- **Pets e montarias:** ficam para depois do lançamento, como você sugeriu.
  - **Atenção:** o rig automático do Meshy é **só para humanoides**, então cavalos e lobos não funcionam direto. Quando chegarmos lá, avaliamos montarias mecânicas ou espirituais animadas por código, ou outra ferramenta de rig.
- **Fantasias de evento.**
- **Continuação da história:** o Sem-Rosto.

---

# Parte 7 — Estimativa de créditos do Meshy (jogo completo)

Com os preços reais da API, cada personagem sai mais barato do que eu tinha estimado antes. Usando o modelo de topologia inteligente, um personagem animado custa ≈ 40 créditos, e não 60.

| Grupo | Quantidade | Créditos aprox. |
|---|---|---|
| Herói: modelo inicial + conjuntos de armadura + modelo depois do salto | ~12 modelos | ~800 |
| Inimigos base | ~10 | ~400 |
| Variações de inimigos (outra textura) | ~12 | ~360 |
| Arautos (2 formas) + Vaelor (3 fases) + Severin | ~14 | ~650 |
| NPCs (mãe, Bram, Bento, comerciantes, ferreiros, povo) | ~22 | ~550 |
| Armas (espadas por raridade e conjunto) | ~30 | ~450 |
| Objetos e peças de cenário (5 regiões) | ~180 | ~2.700 |
| Ilustrações das cenas | ~60 | ~360 |
| **Total** | | **≈ 6.300** (≈ 2 meses e meio do seu plano, espalhados pelas fases) |

---

# Decisões pendentes (preciso de você)

**Já respondidas:**
- Teleporte em todas as cidades, mais pontos de descanso nas áreas de aventura.
- Todas as skills liberadas até o nível 30.
- Trevo e Broca em versão comum e Real.
- Penalidade de morte de −5%.

**Ainda abertas:**

5. **Ordem das cidades.** Proposta ✱: a ordem principal é fixa (Pradoluz → Qaressa → Hrimvald → Lys'Thaël → Altaréa), porque a história depende dela (o Bento morre em Hrimvald). A liberdade vem das áreas e dungeons opcionais de cada região. Pode ser?
6. **Nomes.** Aprova **Herdeiro dos Céus**, **Lio**, as cidades e os personagens? Pode trocar qualquer um.
7. **Botão de esquiva** (rolamento). Entra?
