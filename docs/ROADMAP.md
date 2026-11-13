# Roadmap

| # | Fase | Resultado esperado | Créditos Meshy |
|---|---|---|---|
| 0 | Preparação | Git, pastas, projeto Godot para celular, regras (`CLAUDE.md`), controle de créditos | 0 |
| 1 | Documento de design | História, 4 cidades, 4 skills, curva 1–100, bestiário, itens, guia de estilo com prompts | ~0 (imagens conceito são grátis) |
| 2 | Protótipo cinza | Jogo rodando com formas simples: movimento, combate, 4 skills, IA, XP e level | 0 |
| 3 | Teste do Meshy | Guerreiro, 1 inimigo e ~10 objetos dentro do jogo, validando o fluxo inteiro | ~500 |
| 4 | Fatia vertical | Cidade 1, um campo, uma dungeon e um chefe, nível 1 a ~25. **Áudio** entra aqui (sistema, efeitos, música de Pradoluz; ver `docs/AUDIO.md`) | ~1.500 |
| 5 | Sistemas | Inventário, equipamentos, loja, **poções com atalhos na tela (vida, fôlego, reforço; GDD 6.5.1)**, compras reais | ~500 |
| 6 | Expansão | Cidades 2 a 5, dungeons, conteúdo até o nível 100; **3 a 4 mapas de campo por região com transição gradual de bioma** (GDD, Parte 2), começando por ampliar o Ato 1 | ~4.000 |
| 7 | Polimento e publicação | Balanceamento, áudio, desempenho, versão Android e Windows, Play Store | ~300 |
| — | Pós-lançamento | Fantasias de evento | ~60 por fantasia |

Os créditos são estimativas e serão revistos a cada fase. A regra é gerar só o que a fase atual precisa.

## Status
- [x] Fase 0 — concluída (11/11/2026)
- [x] Fase 1 — concluída (11/11/2026): GDD 1.0 (`docs/design/GDD.md`), guia de estilo (`docs/ESTILO.md`) e 6 imagens de referência aprovadas (`docs/design/referencias/`, 39 créditos).
- [x] Fase 2 — concluída (11/11/2026): protótipo cinza aprovado pelo dono, com fôlego (esquiva, corrida e skills).
- [x] Fase 3 — concluída (11/11/2026): Lio, espada, bandido e 10 peças no jogo, aprovados pelo dono (307 créditos com o ajuste da corrida). Refinos visuais ficam para depois.
- [x] Fase 4 — fatia vertical concluída (11/11/2026; plano em `docs/FASE4_PLANO.md`; 1.341 créditos)
  - [x] 4.1 Mundo e viagem (aprovado): Pradoluz, Floresta, Mina; teleporte; pontos de descanso; árvores transparentes (540 créditos)
  - [x] 4.1b Minimapa, mapa completo, rios e paredões (sem créditos)
  - [x] 4.1c Muralhas e portais + 4.2a Interface com a cara do jogo (aprovado, 210 créditos)
  - [x] 4.2b HUD com retrato: vida e XP em anel em volta do retrato do Lio, fôlego no rodapé, alerta "!" no retrato abrindo o menu do personagem (aprovado, 9 créditos)
  - [x] 4.2 Conversa e missões: código pronto (diálogo com retrato e bipes, balões, marcadores "!"/"?", rastreador, diário, estrela no minimapa, 4 missões principais e 2 secundárias, 7 NPCs do Meshy com retrato, parado e falando; 218 créditos), aprovado
  - [x] 4.3 Inimigos e chefe: arqueiro, orc, esqueleto mineiro, Golem guardião, Gorvan com 2 formas no Celeiro do Tributo, drops, final do Ato 1 (Meshy: 310 créditos), aprovado
  - [x] 4.4 Áudio: sistema de som (música, efeitos, vozes com volume), efeitos CC0 e músicas orquestrais CC-BY provisórias; troca pela ElevenLabs depois. Aprovado
  - [x] 4.6 Ajustes do teste do dono: descanso cura aos poucos e só de 10 em 10 min; inimigos contornam obstáculos; seta no chão até o objetivo da missão, distância no rastreador, toque no rastreador abre o diário. Aprovado
  - [x] 4.5 Prólogo e save: tela inicial, prólogo em 8 ilustrações com texto, save local criptografado com cópia de segurança (Meshy: 54 créditos), aprovado
- [x] Fase 5 — sistemas concluída (12/11/2026; plano em `docs/FASE5_PLANO.md`, sem visual de conjunto de armadura); testada e aprovada pelo dono
  - [x] 5.1 Itens e inventário: mochila de 60 espaços, raridade, detalhes, drops de itens, baús nos mapas, recompensas de missão em itens. Aprovado
  - [x] 5.2 Poções: 3 atalhos na tela (vida, fôlego, reforço) com quantidade e recarga, poções P/M/G e tônicos; chefes reequilibrados. Aprovado
  - [x] 5.3 Equipamentos: 9 espaços (espada, 5 de armadura, 2 pulseiras, cinto), 33 peças em 4 raridades, tela com o Lio em 3D, comparação, conjunto do Sol Alado, peças em baús, missões e chefes. Ajustes do 1º teste feitos (mão vazia sem espada, pegada, "!" no menu, teclas, créditos, molduras) e 4 espadas do Meshy na mão (Meshy: 72 créditos). Aprovado
  - [x] 5.4 Ferreiro (Tobias): fortalecer +1 a +20 com Trevo e Amuleto, quebrar/restaurar, encaixes com Broca, gemas em 5 níveis (juntar 3 → 1), criar as 32 peças, desmontar 100%/50%. Aprovado
  - [x] 5.5 Lojas: loja de ouro da Dona Celeste (comprar/vender), loja especial com dinheiro real (camada Store; loja de teste no PC; Google Play na Fase 7), Pergaminho do saber (+50% XP). Aprovado
  - [x] 5.6 Rotina e metas: 5 diárias por nível, calendário de login de 28 dias com proteção do relógio, 10 conquistas com títulos, dificuldade no Novo jogo (diminuir só na cidade). Aprovado
- [ ] Fase 7 (adiantada antes da Fase 6) — versão Android e loja do Google Play: Java 17, Android SDK 36 e modelos do Godot instalados; plugin de compras 3.3.0; chave de upload fora do projeto; pacote `com.adneysousah.herdeirodosceus`; build por `tools/build/build_android.sh`. Passo a passo do dono em `docs/PUBLICACAO.md`. Inglês mantido, sem espanhol.
  - [x] Teste interno no celular (12/11/2026): compras de teste, atalhos no topo com ícones pintados (6 créditos), balão de fala no botão de ataque, limite de 60 quadros e 3D em até 1080 linhas. Aprovado
  - [x] Ficha da loja, conteúdo do app e ícone novo (12/11/2026); teste fechado enviado para revisão
  - [ ] 12 testadores por 14 dias seguidos e pedido de produção
- [ ] Fase 6 — expansão: plano em `docs/FASE6_PLANO.md`
  - [x] 6.1 Estrada: Campos de Pradoluz, Bosque Seco, Estepe de Pedra, shader de bioma, 5 secundárias (170 créditos). Em teste
  - [x] 6.2a Figurantes: 6 moradores, cachorro, gato, vaca, pássaros, carinho e pesca (~255 créditos). Em teste
  - [~] 6.2b Ato 2 começo: Qaressa, Dunas de Ossos, Zahir, Nadira, homem-lagarto, saqueador, missão 7 (~350 créditos). Em teste
  - [~] 6.2c Ruínas de Ammar, guardião antigo, mural do céu, 1º duelo com o Severin, missão 8 (~200 créditos). Em teste na 0.1.9 (código 10)
  - [~] 6.2d Torre Afundada e a Sahra (2 formas, escudo, jarros de água que curam), missão 9 e fim do Ato 2. Em teste na 0.2.0 (código 11)
  - [~] 6.3a Ato 3 começo: Deserto Rochoso, Planalto Frio, Pinheiral Nevado e Hrimvald; Velho Osk, Brunhild (ferreira) e Bento na cidade; orc da neve, golem de gelo e morto congelado; missão 10 e 2 secundárias (~210 créditos). Em teste na 0.2.1 (código 12)
  - [~] 6.3b Picos Uivantes, Mina de Gelo Esquecida com o Guardião de Gelo, 2º duelo com o Severin (empate) e missão 11 (~66 créditos). Em teste na 0.2.2 (código 13)
  - [~] 6.3c Castelo Ermo, Brannoc em 2 formas (Gigante de Gelo, cristais que curam), cena ilustrada da morte do Bento, salto de 2 anos com o Lio adulto e Hrimvald aquecida; missão 12 fecha o Ato 3 (~260 créditos). Em teste na 0.2.3 (código 14)
  - [~] 6.4a Ato 4 começo: Vale do Degelo, Mata Úmida, Bordas do Pântano e Lys'Thaël (Árvore-Mãe murchando); Elarion (loja) e Faenor (ferreiro); cultista, homem-lagarto e morto do pântano; missão 13 e 2 secundárias (~260 créditos). Em teste na 0.2.4 (código 15)
  - [~] 6.4b Pântano das Raízes, Torre do Vigia Élfico com o Guardião de Espinhos, 3º duelo com o Severin (ele perde; cena ilustrada da dúvida) e a revelação do Bram; missão 14 (~75 créditos). Ajustes do dono: queda de quadros nas skills, botões +10%, efeitos (atordoar, lentidão, enfraquecer, veneno) e impacto visual em todos os chefes, mobs +20% de dano e mais mobs longe das cidades. Em teste na 0.2.5 (código 16)
  - [~] 6.4c Topo da Torre, Velyra em 2 formas (elfa arqueira e Dríade de Espinhos com escudo e flores que curam), efeito novo "preso" (investida e salto soltam), cena da Árvore-Mãe florescendo e missão 15; fecha o Ato 4 (~150 créditos). Em teste na 0.2.6 (código 17)
  - [~] 6.5a Ato 5 começo: Estrada Real, Arredores da Capital e Altaréa; Isolda (resistência), Aurélio (loja) e Matias (ferreiro); guarda e arqueiro da Lei e carcereiro; missão 16 e 2 secundárias (~275 créditos). Em teste na 0.2.7 (código 18)
  - [~] 6.5b Castelo do Arauto, Cassian em 2 formas (Juiz e Colosso de Armadura, Pilares da Lei), o Severin muda de lado, missão 17 (~180 créditos). Junto: forja nova (ícones, custos visuais, tamanho fixo), níveis 10/20/40/60/80/100, raridades Mítico e Celestial, criação em degraus com Insígnias de Chefe e placa para resetar masmorras. Em teste na 0.2.8 (código 19)
  - [~] 6.5c Escadaria do Céu, Cidadela Celeste, Vaelor em 3 fases (deus, Doran desmascarado, corrompido pelo Sem-Rosto), cena final, créditos e missão 18: **a história está completa**. Junto: casas por dentro (2 andares, vasos), oferta de boas-vindas de R$ 4,99, desmontar peças equipadas com confirmação, chances menores no +19/+20 e no 3º encaixe, títulos corrigidos (~470 créditos). Em teste na 0.2.9 (código 20)
  - [~] Melhorias do dono (12/11/2026), na 0.2.0: telas de carregamento com ilustração de cada lugar, efeitos visuais das 8 skills, tela de atributos nova (herói em 3D, totais, prévia do +1), ícones de efeitos ao lado do retrato, passe premium (7/14/30 dias) e 2 visuais à venda (Cavaleiro do Sol e Lâmina da Tempestade). Em teste

## Pendências para depois do jogo concluído

### Ambientação: moradores e animais (pedido do dono, 12/11/2026)
Objetivo: deixar cidades e campos mais vivos. São figurantes, sem missão.

**10 modelos no total:** 6 humanos, 1 cachorro, 1 gato, 1 vaca e 1 pássaro.

- **Humanos (6 modelos):**
  - Nas cidades maiores os mesmos modelos se repetem, com cabelo e roupa de outras cores (troca de cor por código, sem gerar modelo novo) e nomes sorteados de uma lista.
  - Comportamento:
    - andam até um ponto, param, olham para um lado e para o outro e vão para outro ponto;
    - alguns param para pescar em cantos marcados no mapa (beira de rio ou lago);
    - soltam frases curtas (balão sobre a cabeça) que dependem da hora do dia, do tempo e do humor de cada um (alegre, cansado, mal-humorado...);
    - no meio da noite entram nas casas para dormir e somem do mapa; de manhã saem de novo.
- **Cachorro, gato e vaca:**
  - Andam pelo mapa, param e sentam (ou deitam).
  - **Carinho:** perto de um animal, o botão de atacar vira "Acariciar", como o balão de falar perto dos NPCs. Com animal pequeno (cachorro, gato) o Lio se abaixa e passa a mão; com animal grande (vaca) só passa a mão em pé. O animal reage (abana o rabo, deita, muge) e aparece uma frase curta, ex.: "Quem é um bom garoto?", "Ronrona feito chaleira.", "Ela parece gostar de você... ou do seu cheiro de pão."
- **Pássaro:**
  - Voa aleatório, pousa em telhados, cercas e árvores e voa de novo quando o herói chega perto.
  - Em lugares de natureza (bosque, campo, beira de rio) fica um bando no chão que levanta voo todo junto quando o herói passa.

**Cuidados técnicos (para decidir quando chegar a hora):**
- O rig automático do Meshy só aceita humanoides (regra do projeto). Cachorro, gato, vaca e pássaro precisam de outra solução, sem esqueleto do Meshy:
  - animação por código (corpo em peças: pernas, cabeça e rabo mexendo, como já fazemos com criaturas sem esqueleto);
  - ou asas e corpo mexidos por shader, no caso do pássaro;
  - ou um pacote de animais com animação e licença livre (conferir a licença e registrar em `docs/CREDITOS.md`).
- Para o Lio: animações do Meshy de se abaixar/ajoelhar e de acariciar (~3 créditos cada) e a de pescar para os moradores.
- No celular: moradores e animais só se mexem perto do herói; os longe ficam parados ou somem, para não pesar.
- Créditos estimados: 6 humanos (~30 cada com textura e rig) mais as animações extras, uns 200–250 créditos; os animais dependem da solução escolhida.
