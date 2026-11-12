# Decisões do projeto

Registro do que já foi decidido. Quando algo mudar, atualize aqui com a data.

## Jogo (11/11/2026)
- RPG de ação 3D low-poly, original, com história.
- Um único herói: guerreiro com 4 skills ativas, nível máximo 100.
- 4 cidades, com campos e dungeons para explorar.
- Totalmente offline. Só a compra com dinheiro real precisa de internet.
- Câmera de cima na diagonal (isométrica). No celular: joystick virtual, botão de ataque e 4 botões de skill. No PC: teclado e controle.

## Plataformas (11/11/2026)
- Android é a prioridade. Windows também, com a mesma base de código.

## Monetização (11/11/2026)
- Compras com dinheiro real pelo Google Play Billing (plugin oficial do Godot), como itens consumíveis:
  - pacotes de ouro;
  - pacotes de EXP;
  - pacotes de poções.
- Fantasias de evento (mudam o visual e dão atributos): ficam para o fim, podem sair com o jogo já publicado. O sistema de equipamentos já nasce com o espaço para elas.
- As compras são atalhos, não obrigação: o jogo inteiro precisa ser jogável sem pagar.
- No PC as compras ficam desligadas até decidirmos a loja (ex.: Steam).
- Sem servidor por enquanto. O save fica criptografado e com verificação de integridade.
- Conta de desenvolvedor do Google Play e perfil de pagamentos: já criados.

## Arte e assets (11/11/2026)
- Todos os assets 3D vêm do Meshy (plano Premium: 3.000 créditos/mês + 600 do Agent, 12 tentativas grátis por tarefa no site, API e MCP).
- Só personagens humanoides (rig automático do Meshy).
- Cenários com peças modulares; terreno feito no Godot.
- Animações da biblioteca do Meshy; as skills ganham força com efeitos visuais feitos no Godot.
- Visual uniforme: texto base de prompt fixo, imagem de referência, paleta de cores e shader estilo desenho.
- Geração aos poucos, fase por fase, com controle de créditos (`tools/meshy/ledger.py`).
- Herói e chefes: gerados preferencialmente no site (tentativas grátis). Inimigos comuns e objetos: pelo MCP.

## Ferramentas (11/11/2026)
- Godot 4.7.2 (versão padrão, GDScript) em `C:\Godot`.
- Repositório na conta pessoal do GitHub, envio por SSH, binários no Git LFS.

## Meshy (11/11/2026)
- Os créditos mensais renovam todo **dia 4**. Saldo em 11/11: 3.269 (2.919 mensais + 350 permanentes).
- Modelos: personagens com `meshy-t2.5` + textura `meshy-n1`; objetos com `meshy-t2` + `meshy-n1`.
- Personagem animado ≈ 40 créditos (modelo 15 + rig 5 + ~5 animações × 3 + imagem conceito ~6).

## Design (11/11/2026, versão 0.1, aguardando aprovação)
- Fantasia medieval clássica, sem magia para o jogador, com ruínas antigas. Tom equilibrado e com humor. Visual chibi vibrante.
- 5 cidades: fazenda (terra natal), deserto, fortaleza na neve, cidade élfica, capital.
- O deus é o pai do herói. O final é aberto para continuação.
- Nível 100 em ~30 h; história termina perto do 65.
- 8 skills, 4 equipadas; pontos de atributo; fortalecimento até +20; gemas e até 3 encaixes; desmontagem no lugar da fusão; conjuntos de armadura, armas e acessórios.
- Missões diárias (5 por dia), calendário de login, títulos por conquistas, dificuldade escolhida no início, Modo Infernal nas dungeons.
- Pets e montarias: pós-lançamento.
- Documentos: [design/GDD.md](design/GDD.md) e [ESTILO.md](ESTILO.md).

## Design — respostas de 11/11/2026
- Teleporte em todas as cidades (volta para qualquer cidade já visitada) e pontos de descanso nas áreas de aventura e nas dungeons, que servem para teleporte e para voltar depois de morrer.
- As 8 skills são liberadas até o nível 30: níveis 1, 4, 8, 12, 16, 20, 25 e 30.
- Trevo de Fortificação e Broca de Engaste em duas versões: comum (ouro/login/drops, chance de falhar nos níveis altos; Trevo comum 100% até +11, 75% no +12...) e Real (dinheiro real, 100% de sucesso).
- Penalidade "Derrotado": −5% em todos os atributos por 5 minutos.

## GDD aprovado (11/11/2026)
- GDD 1.0 aprovado. Ordem das cidades fixa, nomes aprovados (Herdeiro dos Céus, Lio...), botão de esquiva incluído.

## Arte de referência (11/11/2026)
- As 6 imagens foram aprovadas e são a referência visual oficial: [design/referencias/](design/referencias/). A do Lio (`ref_lio`, tarefa Meshy `01a1cab5-eeca-76aa-be1c-9b53fc5f0f35`) será a base do modelo 3D dele na Fase 3.

## Primeiro teste do protótipo (11/11/2026)
- O dono aprovou a velocidade do personagem, o ataque, o equilíbrio dos inimigos e as skills. Nada travou.
- Pedido: **fôlego**. A esquiva, a corrida (botão novo) e as skills gastam fôlego; o ataque básico não. Detalhes no GDD 6.3.1.

## Áudio (11/11/2026)
- Trilha, passos, sons das skills e "fala" dos NPCs entram na Fase 4. Plano em [AUDIO.md](AUDIO.md): ElevenLabs (IA com conector; uso comercial só no plano pago), bibliotecas CC0 como complemento e "fala" dos NPCs gerada pelo próprio Godot.

## Fase 3 (11/11/2026)
- Gerados: Lio (modelo, esqueleto, 14 animações), espada de aprendiz, bandido (modelo, esqueleto, 4 animações) e 10 peças de Pradoluz. Custo da fase: 298 créditos (teto era 320).
- Objetos passaram a ser feitos pelo caminho imagem → 3D (mais controle; +3 créditos por peça).
- Visual estilo desenho feito com os modos toon nativos do Godot (sem shader próprio).
- Personagens em escala 1,2 e câmera mais próxima, para leitura no celular.
- Pedido do dono (corrida): fora de combate a espada fica nas costas (osso `Spine`); em combate (3 s após atacar, usar skill ou levar dano) volta para a mão. Corrida em combate com a espada para trás (`Standard Forward Charge`) e caminhada em guarda (`Walk Fight Forward`). +9 créditos (3 animações testadas).

## Fase 4.1 (11/11/2026)
- Mapas definidos em JSON (`data/maps/`), montados pelo `GameMap`. A arena de treino virou um mapa como os outros (usada pelos testes).
- Pontos de descanso: o herói ativa ao chegar perto (cura, vira ponto de volta após a morte e destino de teleporte). O botão "Viajar" aparece quando há mais de um ponto ativado.
- Árvores, casas e paredes ficam transparentes quando escondem o herói.
- A entrada da mina veio com uma placa escrita "OLD DIGGINGS" (em inglês). Fica assim por enquanto; refazer custa 15 créditos se o dono preferir.
- Os inimigos da floresta e da mina são provisórios (bandido e orc) até a etapa 4.3.

## Interface, muralhas e portais (11/11/2026, pedido do dono)
- Interface com texturas do Meshy: janelas de madeira com cantos dourados, botões de tábua com borda de ouro, barras com moldura, aro dourado nos botões de toque, moldura ornamentada no minimapa e ícones pintados para as 8 skills.
- Cidades cercadas por muralha (pedra + paliçada) com torres nos cantos e portão nas saídas. Mapas de batalha fechados por elementos do ambiente: na floresta, rios com juncos nas margens e paredões de rochedos (com barreira invisível atrás). Neve, deserto e pântano ganham as suas bordas na Fase 6.
- Saídas de mapas de batalha marcadas por um portal de pedra com luz mágica.

## HUD com retrato e mapas de transição (11/11/2026, pedido do dono)
- HUD compacto: retrato do Lio num círculo dourado. Metade de cima do anel = vida (vermelho), metade de baixo = XP (azul). Nível no selo embaixo, vida em números e ouro ao lado. Fôlego numa barra centralizada no rodapé.
- Os botões Atributos e Skills saíram da tela. Quando há pontos para distribuir ou skill nova, aparece um "!" pulsando no retrato; tocar no retrato abre o menu do personagem (Atributos, Skills, Mapa). Teclas C, K e M continuam no PC.
- O botão "+1 nível" só existe na versão de teste (some no jogo exportado).
- Cada região terá 3 a 4 mapas de campo, com o bioma mudando aos poucos até o da próxima região (ex.: floresta → floresta rala → começando a congelar → inverno → gelo). Neve, folhas secas e musgo por shader nas peças existentes; o Meshy só para o que o shader não resolve. Detalhes no GDD, Parte 2.

## Conversa e missões (11/11/2026, etapa 4.2)
- Conversa numa caixa de pergaminho no rodapé, com o retrato de quem fala (NPCs à esquerda, Lio à direita), texto que se escreve sozinho e "voz" de bipes com tom próprio para cada personagem (sem arquivos de som). O jogo pausa durante a conversa.
- Perto de um NPC aparece o botão "Falar" (tecla E). NPCs soltam frases curtas em balão quando o herói passa perto.
- Marcadores sobre a cabeça: "!" = missão para pegar, "?" = próximo passo; dourado = principal, azul = secundária.
- Missão seguida aparece embaixo do retrato; estrela laranja no minimapa e no mapa completo (ou seta para a saída certa, quando o objetivo está em outro mapa). Diário em Missões (tecla L ou menu do retrato).
- Tipos de passo: falar, derrotar, coletar (itens que brilham no chão) e chegar a um lugar. Recompensa em XP e ouro (itens entram na Fase 5).
- Ato 1 até a mina: 4 missões principais (Marta → Bram → bandidos → Bento na floresta → mina) e 2 secundárias (Nina e o trigo escondido; o ferro do Tobias). A luta com o Gorvan entra na 4.3.

## Inimigos e chefe do Ato 1 (11/11/2026, etapa 4.3)
- Cada inimigo tem uma lista de ataques nos dados, todos com aviso vermelho no chão: círculo à frente, área em volta, onde o herói está, linha, sequência de pancadas, flecha/corvo (dá para rolar através) e chamar ajuda.
- Arqueiro mantém distância; esqueleto mineiro só na mina; Golem de pedra guarda a passagem para o Celeiro do Tributo.
- Gorvan: fala ao começar a luta (uma vez só), a entrada fecha, chama 2 bandidos abaixo de 80% de vida e vira o Espantalho Colossal na metade. Se o herói morre, o chefe volta inteiro e a arena reabre.
- Equilíbrio pensado para o nível 12 sem poções (robô de teste vence em ~45 s a 2 min; no nível 11 perde).
- Drops: moedas que voam até o herói e materiais (couro de orc, osso velho, fragmento de pedra, palha dourada) guardados para o ferreiro da Fase 5.
- Depois do Gorvan: a vila ganha comida (peças com if_flag), falas novas, e a despedida com Bram e Bento fecha o Ato 1.

## Prólogo, tela inicial e save (11/11/2026, etapa 4.5)
- O jogo abre na tela inicial (Continuar, Novo jogo, Sair no PC). Novo jogo com save existente pede confirmação antes de apagar.
- Prólogo "A noite do brilho" em 8 ilustrações com texto, câmera lenta e "Pular"; termina em "Dezenove anos depois..." e entra no jogo.
- Save local criptografado (AES do Godot) com verificação SHA-256 e cópia de segurança (o save anterior). Arquivo adulterado ou danificado é ignorado e o jogo usa a cópia.
- A chave é do jogo, não do aparelho: quem troca de celular e restaura o backup do Android mantém o progresso.
- Salva ao trocar de mapa, ao descansar, ao concluir missão, ao subir de nível, a cada 30 s e quando o app vai para o fundo ou fecha. Guarda mapa, posição, missões, marcas da história, materiais, nível, atributos, ouro, skills equipadas.

## Áudio provisório (11/11/2026, etapa 4.4)
- O dono escolheu começar com sons gratuitos e migrar para a ElevenLabs depois (prioridade da troca: as músicas e os sons das skills e do Gorvan).
- Efeitos CC0: RPG Sound Pack (artisticdude), 80 CC0 RPG SFX (rubberduck), sons RPG e de interface da Kenney.
- Músicas orquestrais CC-BY 3.0 de Jonathan Shaw (RPG Orchestral Essentials): título, prólogo, vila, floresta, mina, chefe e vitória. O crédito aparece em Opções > Créditos e em docs/CREDITOS.md.
- Sons tocados por id (data/audio/audio.json): trocar por arquivos da ElevenLabs não mexe no código.
- Opções (menu do retrato e tela inicial): volume de música, efeitos e vozes, salvo no aparelho.

## Ajustes depois do teste do dono (11/11/2026, etapa 4.6)
- Pontos de descanso: curam aos poucos (3 s parado neles) e depois esperam 10 minutos (tempo real, salvo no save) para curar de novo. Ativação, teleporte e renascer continuam iguais. A espera aparece sobre a fogueira/pedra. Motivo: não dava para ficar indo curar durante o chefe.
- Inimigos andam pelo caminho livre (malha de navegação gerada quando o mapa carrega) e contornam casas, árvores, pedras e rios.
- Missões: seta laranja no chão ao redor do herói aponta para o objetivo (ou para a saída do mapa certo); o rastreador mostra a distância ou "em <mapa>"; tocar no rastreador abre o diário; a missão recém-aceita vira a seguida.
- Chefes não morrem antes da próxima forma (um golpe forte perto da metade faz o Gorvan virar Espantalho, não pular a forma).
- Poções (vida, fôlego, reforço) com atalhos na tela entram na Fase 5 (GDD 6.5.1). "MP" no nosso jogo é o fôlego.

## Texturas e espaço no Git (11/11/2026)
- O dono prefere manter a qualidade: texturas continuam em 2K, sem limite no jogo exportado.
- Economia sem perda: animações novas vêm só com o esqueleto (≈90 KB por arquivo em vez de ≈3 MB). Os arquivos antigos ficam como estão (trocá-los não libera o espaço já usado no histórico).
- Se o GitHub ficar sem espaço: comprar pacote de dados do Git LFS ou usar a ferramenta opcional `glb_shrink.gd`.

## Itens, mochila e poções (11/11/2026, etapas 5.1 e 5.2)
- Itens ficam em `data/items/items.json` (nome, descrição, tipo, raridade, pilha, preço, efeito). Raridades: comum (branco), raro (azul), épico (roxo), lendário (dourado).
- Mochila de 60 espaços; itens iguais se empilham. Abre pelo menu do retrato ou pela tecla B (era I, que também é a skill 2). Os 4 materiais antigos viraram itens (saves antigos são convertidos).
- Poções de vida (30/50/80% em 2 s) e de fôlego (40/70/100% em 1,5 s), em tamanhos pequena, média e grande. Tônicos de força (+20% ataque), pedra (+25% defesa) e vento (+15% velocidade) por 90 s.
- Três atalhos na tela, acima da barra de fôlego: vida, fôlego e reforço. Mostram quantas sobram e a recarga de 8 s (cada atalho tem a sua). No PC: teclas 5, 6 e 7 (ou Z, X e V). Se a poção escolhida acabar, o atalho usa outra do mesmo tipo. Na mochila, "Pôr no atalho" escolhe qual poção vai em cada atalho.
- Baús nos mapas (2 na floresta, 2 na mina, 1 no celeiro): abrem uma vez por save, dão ouro e itens. Cubo provisório até o modelo do Meshy.
- Inimigos deixam poções e materiais; Golem deixa Broca, Gorvan deixa Trevo. Missões dão poções como recompensa (a missão final dá um Amuleto).
- Ícones: 4 folhas de 4x4 do Meshy (64 ícones: poções e itens especiais, gemas e materiais, equipamentos em 4 raridades), recortadas no Godot. Aprovados pelo dono (54 créditos com o baú).
- Baú: modelo do Meshy em uma peça; o jogo corta na linha da tampa para ela abrir.
- Chefes reequilibrados para a luta com poções: Golem 2500 de vida, Gorvan 3700 (Espantalho 3700). Sem poções, o Gorvan só cai no nível 12–13 por pouco; com as poções que o jogo dá até ali, a luta fica confortável no nível 11.

## Equipamentos (11/11/2026, etapa 5.3)
- 9 espaços: espada, elmo, peitoral, luvas, calça, botas, 2 pulseiras e cinto. Tela "Equipamento" (tecla G, menu do retrato ou botão na mochila) com o Lio em 3D (arrastar gira), os espaços em volta, detalhes da peça e as peças da mochila que servem naquele espaço.
- Cada peça é única na mochila: guarda +nível, encaixes (sorteados ao ganhar: 0 a 3, chances do GDD 6.5), gemas e se já foi usada (para a desmontagem da 5.4).
- 33 peças do Ato 1 em `data/items/items.json`: espada de aprendiz (todo herói novo começa com ela) e 8 peças em cada raridade. Nível mínimo: comum 1, raro 4, épico 8, lendário 11.
- Bônus por espaço: espada = ataque; elmo, peitoral e calça = defesa e vida; luvas = defesa e velocidade de ataque; botas = defesa e esquiva; pulseiras = ataque e crítico; cinto = vida e fôlego.
- O +nível já vale nas contas (+4% por nível até +10, +6% até +15, +10% até +20); o fortalecimento em si vem na 5.4.
- Conjunto do Sol Alado (5 peças de armadura lendárias): 3 peças = +150 de vida, 4 = +25 de defesa, 5 = +25% de dano crítico. Peças de conjunto não caem de inimigos; vêm do ferreiro (5.4).
- Onde se ganha: baús (peças comuns; o do celeiro dá uma pulseira rara), missões (espada de ferro, colete, calça, pulseira, cinto raro; o Tobias dá a espada de aço), inimigos comuns (3 a 4% de chance de peça comum), Golem (1 peça rara) e Gorvan (2 peças raras).
- Equilíbrio: com as peças que o jogo dá até lá, a luta contra o Gorvan no nível 11 fica um pouco mais fácil (vida mínima 37% → 46%, 44 s → 37 s). Mantido assim: é a recompensa de explorar.
- Espadas do Meshy (72 créditos, feitas a partir dos ícones aprovados): ferro (comum), aço azul (rara), rúnica (épica) e Sol Alado (lendária). Cada uma aparece na mão quando equipada; as peças de armadura não mudam o visual (só os conjuntos, na Fase 6).

## Ajustes depois do teste da 5.3 (11/11/2026)
- Sem espada equipada, a mão fica vazia (antes continuava aparecendo a de aprendiz).
- Mão na espada: o esqueleto do Meshy não tem ossos dos dedos (24 ossos, a mão é uma peça só), então nenhuma animação fecha a mão. O cabo agora passa pelo meio dos dedos (e não pela palma), e assim os dedos cobrem o cabo como numa mão fechada. Para dedos que fecham de verdade, o Lio teria que ser refeito no Meshy com as mãos fechadas (~70 créditos); fica como opção para quando fizermos os visuais de conjunto (Fase 6).
- Menu do retrato: cada item que pede atenção ganha um "!" vermelho (atributos para distribuir, skill nova, peça nova que dá para usar). A peça deixa de ser "nova" ao abrir a tela de Equipamento.
- Teclas: Mochila B (era I, que também é a skill 2), Equipamento G (era K, igual a Skills).
- Créditos em Opções: o texto rola dentro de uma caixa; o painel não passa mais da tela.
- Molduras: o conteúdo dos painéis começa dentro da moldura entalhada (margem 60). Todo painel é centralizado e, se a janela for pequena, encolhe para caber inteiro.

## Ferreiro (11/11/2026, etapa 5.4)
- A forja abre quando se fala com o Tobias (depois da fala do dia a dia; conversas de missão vêm antes). Quatro abas: Fortalecer, Encaixes e gemas, Criar e Desmontar. Regras e custos em `data/smith/smith.json`.
- Fortalecer +1 a +20 com as chances do GDD 6.5 (100% → 5%) e do Trevo (Trevo Real = sempre). Até +10, falhar só gasta o custo; de +11 a +15 a peça quebra (sem bônus até restaurar); de +16 a +20 ela some. O Amuleto evita as duas coisas. Trevo e Amuleto são gastos na tentativa. Funciona em peças equipadas ou na mochila.
- O GDD não dizia qual material o fortalecimento gasta: escolhemos o **Lingote de aço** (cai de orcs e esqueletos, Golem e Gorvan, e de um baú da mina; depois também na loja). Custo em ouro sobe com o +nível e com a raridade.
- Restaurar peça quebrada: ouro (60 por +nível) e 3 Lingotes.
- Encaixes: Broca comum abre o 1º/2º/3º com 100%/50%/25%; Broca Real sempre. A broca é gasta mesmo se falhar.
- Gemas em 5 níveis (I a V) para os 5 tipos do GDD: Rubi ataque, Safira vida, Esmeralda crítico, Topázio recarga, Ametista defesa. **Três iguais viram uma do nível seguinte** no ferreiro (o GDD não dizia como subir de nível; essa é a forma mais comum no gênero). Tirar uma gema custa 50 de ouro e ela volta para a mochila. Gemas caem de inimigos (nível I), chefes (nível II) e baús.
- Criar: todas as 32 peças (inclusive as lendárias do Sol Alado, que só saem daqui). Custo por raridade, com os materiais do Ato 1; os encaixes são sorteados (0 a 3).
- Desmontar: só peças na mochila. Nunca usada = devolve todos os materiais da receita; já usada = metade. Gemas encaixadas voltam. Não dá para desmontar a espada de aprendiz.
- Novos drops de materiais: palha dourada (bandidos e arqueiros, 5%), lingote (orcs e esqueletos, 12%), fragmento de pedra (esqueletos, 8%).
- Os valores de ouro são provisórios: serão calibrados junto com a economia das lojas (5.5).

## Lojas (11/11/2026, etapa 5.5)
- Loja de ouro da Dona Celeste: abre depois da fala dela (como o Tobias). Vende poções (P/M/G), os 3 tônicos, Lingote de aço, Trevo, Broca, Amuleto e as peças comuns e raras (sem conjunto), como no GDD 6.6. Lista e preços em `data/shop/shop.json`.
- Vender: qualquer item da mochila pelo "price" do item; equipamento vale +15% por +nível. Não se vende a espada de aprendiz nem peça equipada. Quantidade com −/+/+10.
- Loja especial (dinheiro real) com 7 produtos. **Preços aprovados pelo dono em 12/11/2026:** Saco de ouro (5.000) R$ 4,90 · Baú de ouro (30.000) R$ 24,90 · Pergaminho do saber (+50% XP por 1 h) R$ 3,90 · Kit de poções R$ 4,90 · Trevo Real R$ 6,90 · Broca Real R$ 4,90 · Amuleto de Proteção R$ 3,90. Ids e preços em `data/shop/store.json`; no Play Console (Fase 7) os produtos são criados com esses mesmos ids e preços. Pergaminho do saber = +50% de XP dos inimigos por 1 hora em tempo real (soma se comprar outro). Kit de poções = 10 vida média, 10 fôlego médio e 3 tônicos.
- Camada `Store` (autoload): no Android usa o plugin Godot Google Play Billing (instalado na Fase 7, junto com a exportação); na versão de teste do PC há uma "loja de teste" que simula a compra sem cobrar; na versão final do PC a loja especial some.
- Segurança da compra: o item é entregue e o jogo salva antes de a compra ser "consumida" no Google Play. Compras pagas com o jogo fechado (ou na tela inicial) são entregues quando o jogo abre. Itens comprados chegam mesmo com a mochila cheia.

## Rotina e dificuldade (11/11/2026, etapa 5.6)
- Tela "Rotina" (tecla R ou menu do retrato, com "!" quando há prêmio): abas Diárias, Login e Conquistas. Regras em `data/routine/routine.json`.
- Missões diárias: 5 por dia, sorteadas pelo nível entre 11 modelos do Ato 1 (derrotar inimigos, juntar materiais, beber poções, fortalecer, comprar, criar). Iguais o dia todo; renovam à meia-noite do aparelho. Prêmio: 12% do XP do nível, ouro (40 + 12 por nível) e 2 materiais.
- Calendário de login de 28 dias (GDD 6.7): dias 6/13/20/27 Broca, 7/14/21/28 Amuleto, o 28º também Trevo Real, 5.000 de ouro e 3 poções grandes; os outros dias dão ouro, poções, lingotes ou gemas. Um prêmio por dia de jogo (não precisa ser seguido); depois do 28º recomeça.
- Proteção do relógio: o jogo guarda a maior data já vista; se o relógio voltar mais de 1 hora, diárias e login ficam bloqueados até a data voltar.
- Conquistas: 10 no Ato 1, cada uma libera um título com bônus (ex.: Caçador de Orcs +5 de ataque, Fim do Tributo +8 de ataque e +80 de vida). Um título em uso por vez; aparece no menu do retrato.
- Dificuldade (GDD 6.10): escolhida no Novo jogo. Fácil = inimigos −25% de vida e dano, penalidade de morte pela metade; Difícil = inimigos +40%, +25% de XP e de chance de itens. Em Opções dá para diminuir, só numa cidade (Pradoluz), nunca aumentar. Saves antigos ficam no Normal.
- O Modo Infernal das dungeons fica para a Fase 6, como no plano.
