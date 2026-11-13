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

## Dedos e pegada da espada (12/11/2026)
- O Lio ganhou 30 ossos nos dedos (3 por dedo, nas duas mãos), colocados no Blender 4.5 sem gastar créditos do Meshy. Os 24 ossos originais ficaram iguais (conferido: mesma posição e mesma ligação com a malha), então todas as animações do Meshy continuam valendo. Os nomes seguem o padrão humanoide (`RightIndexProximal`...), o que permite usar animações de outras fontes (ex.: Mixamo) no futuro.
- A mão fecha por código (`HandPose`): com a espada na mão, a direita fica na pose "grip"; sem espada ou com ela nas costas, as duas mãos ficam em "relaxed". As poses (graus por junta) ficam em `characters.json` → `hand_poses`.
- A espada agora passa por dentro do punho fechado, atravessando a palma, e a lâmina sai do lado do polegar, como numa pegada de verdade. Antes o cabo passava entre os dedos abertos. Com isso, o ângulo da lâmina nos golpes ficou mais fiel às animações (ex.: na estocada a lâmina aponta para a frente) e a lâmina fica mais baixa na guarda de combate.
- Inimigos e NPCs não têm ossos nos dedos e não mudam.
- Original (antes dos dedos) guardado no git; a versão nova também fica em `assets/_inbox/hero_lio_fingers/`.

## Animações refeitas: corrida, fogueira, bandido e arqueiro (12/11/2026)
- Meshy: 30 créditos (4 corridas e 3 de sentar para o Lio; 3 tiros de arco para o arqueiro). Ajustes feitos no Blender por script (`tools/blender/`).
- **Corrida do Lio:** trocada pela "Run 03" do Meshy (cotovelos dobrados e braços balançando). As outras opções testadas: Run 02, Run Fast 3 e Run Fast (essa última inclinada demais, parece um sprint).
- **Fogueira:** parado dentro do círculo de uma fogueira (fora de combate), o Lio senta no chão de pernas cruzadas virado para o fogo e levanta quando volta a andar. O Meshy não tem "sentar no chão" com transição (as transições são de cadeira), então a descida e a subida são uma mistura suave de 0,7 s entre ficar em pé e sentado. Na pedra de passagem ele não senta.
- **Bandido de espada:** ganhou os ossos dos dedos e a mesma pegada do Lio (mão fechada, cabo atravessando a palma).
- **Arqueiro:** o tiro antigo estava quebrado nesse personagem (curvado, olhando para o chão, arco para baixo). O novo junta duas animações do Meshy (puxar a flecha e soltar, 1,7 s) e foi girado 90° no Blender, porque o Meshy mira para o lado esquerdo. A mão esquerda fecha no arco, com a corda virada para o arqueiro; a direita fica na pose "draw" e segura uma flecha do momento em que pega até soltar. A flecha voa no momento em que ele solta (1,15 s do clipe).
- A corda do arco não estica (ela faz parte do modelo do arco, que é uma peça só).

## Vento, grama e dia/noite (12/11/2026)
- **Vento:** árvores, pinheiros, arbustos, flores, juncos e o trigo balançam (shader `assets/shaders/toon_wind.gdshader`, mesmo visual "desenho" das outras peças). A base fica parada e a copa anda; o vento vem em ondas que atravessam o mapa e em rajadas. Quanto cada planta balança: campo `wind` em `data/world/props.json`.
- **Grama:** tufos de grama baixos nos campos abertos (Pradoluz, floresta e arena), longe das trilhas e dos rios, balançando com o mesmo vento. Tudo num desenho só (leve no celular). Quantidade e cores: campo `grass` do mapa.
- **Linhas de vento:** de vez em quando passam linhas brancas finas perto do herói, ondulando (algumas fazem um laço), na direção do vento.
- **Dia e noite:** um dia inteiro dura 60 minutos reais (escurece aos poucos por ~30 min e clareia por ~30 min). A luz muda sem saltos: manhã dourada, meio-dia como o mapa foi feito, entardecer laranja/rosado e noite azul (escura, mas dá para jogar). O sol (e de noite a lua) muda de posição, então as sombras giram. Lampiões acendem mais à noite; fogueiras ficam iguais. A hora fica salva no jogo e um jogo novo começa às 9h. Tudo em `data/world/daynight.json`.
- Celeiro e mina são lugares fechados (`"indoor": true` no mapa): sem dia/noite e sem vento.
- **Relógio:** ao lado do minimapa, um mostrador de 24 horas (sol em cima = meio-dia, lua embaixo = meia-noite) com o céu da hora dentro, um ponteiro e a hora escrita embaixo.
- Nas versões de teste, **F3** adianta 3 horas (para ver a noite sem esperar).

## Orc e arqueiro (12/11/2026)
- **Orc:** ganhou os ossos dos dedos; a mão fecha na clava e o cabo atravessa o punho (antes a clava ficava de lado). O golpe é de marreta, com as duas mãos juntas perto da base do cabo: a animação do Meshy deixa as mãos a ~1 m uma da outra, então os dois braços são dobrados por código (`TwoHandIK`) até os punhos se encontrarem no cabo, e a cabeça da clava fica na ponta, depois da mão de cima. Fora do golpe ele carrega a clava só na direita. Configuração: `two_hand` na arma (`spacing` = distância entre os punhos, `meet` = onde as mãos se encontram, `base` = onde fica a mão de baixo no cabo); serve para qualquer arma de duas mãos.
- **Orc parado depois do golpe:** entre um golpe e outro ele esperava 2,6 s na pose de "parado tranquilo", por isso parecia travado. Agora espera 1,6 s numa postura de luta (agachado com a clava apontada para o herói, a mesma postura de combate do Lio).
- **Arqueiro:**
  - Quando se afasta do herói para ter distância, anda de costas (a caminhada tocada ao contrário), sem gastar créditos. Se quiser algo ainda mais real, o Meshy tem "Walk Backward with Bow" (3 créditos).
  - Depois de cada flecha ele rola para o lado, um pouco para longe do herói (~3 m), com o mesmo rolamento do Lio. Distância: `dodge_after` no ataque em `data/enemies/enemies.json`.
  - O tiro carrega 0,5 s mais rápido: o aviso no chão dura 0,3 s (antes 0,8 s) e a animação de puxar a corda foi acelerada para caber nesse tempo.

## Esqueleto da mina (12/11/2026)
- **Ataque que não aparecia:** o golpe usava só 0,8 s de uma animação de 7,7 s, tocado devagar dentro do tempo do aviso (0,45 s). Na tela só dava para ver o fim do movimento, com a picareta parada. Agora o aviso dura 0,6 s e a animação vai 1,6x mais rápida: ele ergue a picareta acima da cabeça e desce numa picaretada à frente, terminando com a ponta para baixo, no momento do dano.
- **Pegada:** ganhou os ossos dos dedos; a mão fecha no cabo e o cabo sai do punho inclinado para a frente, como se segura uma picareta (o golpe é de uma mão só, então a outra fica livre).
- Ferramenta: `character_preview` aceita `ataque!:tempo:aviso` para ver o golpe de um inimigo exatamente como no jogo.

## Gorvan, Espantalho e as regras dos chefes finais (12/11/2026)
- **Foice na mão (Gorvan e Espantalho):** os dois ganharam os ossos dos dedos (Blender, sem créditos do Meshy; os 24 ossos originais iguais). A foice antes ficava solta, longe da mão e de lado; agora o cabo atravessa o punho fechado, uns 40% acima da ponta de baixo. Nos golpes (ceifar, girar, golpe pesado e a pancada no chão do Espantalho) ele segura com as duas mãos: a de baixo perto do fim do cabo e a de cima ~45 cm acima (`two_hand` com `other_at`, para armas presas por `hold_point`).
- O dano dos golpes agora cai no momento em que a foice bate: golpe pesado do Gorvan aos 1,55 s (antes 1,3 s, com a foice ainda no alto) e a pancada do Espantalho aos 1,68 s, quando a lâmina finca no chão à frente (a animação é cortada logo depois, antes de a foice virar para trás).
- **Troca de forma (50% de vida) virou uma cena de ~4,4 s**, sem dano no chefe:
  1. O Gorvan fala primeiro ("Levanta, colheita! Teu senhor tem fome!"), com o jogo parado.
  2. Ruge e empurra o herói para trás (sem dano); a câmera se aproxima e olha para ele.
  3. Fica dourado dentro de um redemoinho de palha, e o trigo brota pela arena.
  4. Gira e encolhe dentro do redemoinho; o Espantalho cresce de dentro dele e cai com uma pancada no chão (tremor de tela).
  5. O escudo dourado fecha em volta dele, e o Lio comenta o que está vendo (escudo e trigo), para o jogador entender a regra nova.
- **Regra para todo chefe final (Arauto) — vale para os próximos:**
  - **Escudo de quebra** na forma verdadeira: enquanto o escudo está de pé, os golpes gastam o escudo e a vida não desce (números amarelos). Quando quebra: aviso "Escudo quebrado! Ataque agora!", o chefe fica atordoado 2,5 s e leva dano por 10 s; depois o escudo volta inteiro. Na barra do chefe o escudo aparece como uma faixa clara por cima da vida. Configuração: `shield` em `data/enemies/enemies.json` (`amount` = escudo em fração da vida máxima, `broken_time`, `stun`).
  - **Arena a favor do chefe** quando ele mostra a forma verdadeira: o ambiente muda de acordo com o tema dele. No Espantalho, 5 moitas de trigo brotam no celeiro; quando ele passa por cima de uma, recupera **15% da vida** e a moita seca (volta em 40 s). Abaixo de 80% de vida ele vai atrás do trigo de propósito (por até 5 s, depois desiste por 8 s). O herói **corta** a moita atacando ou usando skill perto dela — é a resposta do jogador. Configuração: `power_ground` na forma (`heal`, `regrow`, `seek_below`...) e `power_spots` no chefe do mapa (onde nascem). Próximos Arautos: trocar o trigo pelo que combinar com cada um (ex.: poças, brasas, gelo), sempre com uma forma de o jogador negar a vantagem.
  - A fala da troca de forma fica dividida: `transform_line` (o chefe, no começo) e `reborn_line` (o herói, no fim).
- **Equilíbrio** (robô do `boss_sim`, com poções e peças): antes a luta no nível 12 levava ~48 s; agora 60–135 s, sem mortes, vida mínima ~33–50%. O tempo depende de quantas vezes ele come o trigo (0 a 4 no teste); o robô não corta trigo de propósito, então quem joga e corta o trigo termina mais rápido. A primeira forma (Gorvan) ficou igual, sem escudo.
- Ferramenta nova: `tests/transform_capture.tscn` tira fotos da cena de troca de forma, do escudo, da quebra e da cura no trigo.

## Tela de skills nova (12/11/2026)
- Pedido do dono: em vez de uma lista com botões "1 2 3 4" em cada skill, a tela mostra as 8 skills como os ícones redondos (os mesmos dos botões de ataque), 4 por linha, com um "+" dourado no canto. As trancadas aparecem escuras, com cadeado e o nível em que abrem.
- Tocando numa skill, aparece embaixo a descrição (nome, o que faz, fôlego e recarga) e os 4 botões com o ícone do que está em cada um; tocar num deles coloca a skill ali (se ela já estava em outro botão, as duas trocam de lugar). O número dourado no canto do ícone mostra em qual botão cada skill está.
- Peça reutilizável: `SkillIconView` (ícone redondo com moldura, "+", número, cadeado e brilho de escolhido). Fotos: `hud_capture` agora termina na tela de skills.

## Fase 6.1: estrada, bioma e curva de progressão (12/11/2026)
- Caminho do Ato 1 como no GDD: Pradoluz → Campos de Pradoluz (1–3) → Floresta (3–8) → Mina e Celeiro; depois do Gorvan, Bosque Seco (12–15) → Estepe de Pedra (15–18) → Dunas de Ossos ("Em breve" até o Ato 2).
- Bioma por shader: cada mapa tem `"biome": {"dry", "snow", "moss"}` (0 a 1) e as peças de cenário mudam de cor (folhas secas, neve por cima, musgo na pedra). Personagens nunca mudam. Mapas sem bioma continuam com o material de antes.
- Inimigo de outra região com Retexture mantendo o UV original: só a textura muda (`characters.json`: `"base"` + `"texture"`), então esqueleto, animações, dedos e pegada são os do original já aprovado (10 créditos em vez de ~50).
- **Regra do XP das missões (pedido do dono de checar a curva):** em cada faixa de níveis, as missões dão ~40% do XP e os inimigos ~60%. O Ato 1 já passa disso (missões ≈ 94% do XP de 1→12), então missões novas no Ato 1 pagam em ouro e itens, não em XP. Na estrada (12→18) as 3 secundárias (Bram, Tobias, Bento) somam 1.950 de 4.460 XP (~44%).
- Toda animação de personagem novo ou alterado é conferida com fotos (ações e mão na arma) antes de mostrar; o que não ficar bom vai para o Blender.

## Fase 6.2d e melhorias do dono (12/11/2026)
- **Torre Afundada** (níveis 25–28), a leste das Ruínas (abre com `act2_ruins`). Jarros de água roubada, poços lacrados e a torre meio enterrada no fundo. O pátio do norte é a arena da Sahra.
- **Sahra, Arauta da Sede:** a primeira forma é a mercadora com a espada curva. Ela corta, faz combo, avança em linha, joga facas de areia (projétil `look: "sand"`) e chama 2 homens-lagarto abaixo de 80% de vida.
  - **Forma verdadeira:** a Guerreira de Areia, com soco, pancada em círculo, colunas de areia (barragem) e o **mergulho na areia** (ataque com `"blink"`): ela afunda, aparece atrás do herói e bate.
  - **Arena a favor:** 5 jarros de água brotam. Cada um cura 15% da vida dela, e o herói quebra os jarros atacando perto. As cores da cena de troca de forma vêm de `transform_fx`, na primeira forma.
  - **Equilíbrio** (`boss_sim sahra 28` com peças e poções): 99 s, sem mortes, vida mínima de 36%, o escudo quebrou 5 vezes e ela se curou 2 vezes.
- **Missão 9 "A Arauta da Sede"** fecha o Ato 2 (`act2_done`): os poços de Qaressa voltam a ter água.
- **Telas de carregamento** (pedido do dono): ilustração de cada lugar no estilo do prólogo, com o nome, uma dica e uma barra.
  - Aparece ao entrar no jogo (Continuar e depois do prólogo) e a cada troca de mapa.
  - Fica pelo menos 1,3 s na tela para dar tempo de ver.
  - O jogo fica parado durante o carregamento.
- **Efeitos das skills:** cada uma das 8 tem efeito próprio, feito por código e leve para o celular. Também há o rastro da espada e a aura do Brado de Guerra.
- **Tela de atributos nova:** ocupa a tela quase inteira.
  - Mostra o herói em 3D (gira sozinho ou arrastando), o total de cada status com a parte que vem dos equipamentos, e uma barra por atributo com "+" e "!".
  - O "!" mostra o antes → depois de +1 ponto.
- **Ícones de efeito** ao lado do retrato, embaixo do ouro: passe premium, bônus de XP, Brado de Guerra, poções, "Derrotado" e efeitos negativos. Cada ícone mostra o tempo que falta, e tocar nele mostra o nome. O texto antigo de "Derrotado" saiu.
- **Passe premium** (preços do dono): R$ 15 por 7 dias, R$ 20 por 14 dias e R$ 25 por 30 dias.
  - Dá XP x2 (inimigos e missões), ouro x2 (inimigos e baús) e +10% em todos os atributos (força, vitalidade, agilidade e foco).
  - Comprar de novo soma os dias. O tempo é real e corre com o jogo fechado.
- **Visuais (skins):** Cavaleiro do Sol e Lâmina da Tempestade, cada um com roupa, cabelo e espada próprios. O preço de R$ 9,90 cada foi escolhido por mim, e dá para mudar no Play Console.
  - São modelos novos com o mesmo esqueleto do herói (usam todas as animações dele) e ganharam os ossos dos dedos.
  - A espada do visual aparece no lugar da espada equipada, mas os números continuam sendo os da arma equipada.
  - O visual vestido fica salvo. Para trocar: Vestir/Tirar na loja especial, ou o botão "Visual" na tela de equipamentos.

## Fase 6.3a: a estrada do frio e Hrimvald (12/11/2026)
- **Caminho, como no GDD:** Dunas de Ossos (saída oeste, abre com `act2_done`) → Deserto Rochoso (28–31) → Planalto Frio (31–34, primeiras manchas de neve) → Pinheiral Nevado (34–37) → **Hrimvald**. A neve vem do shader de bioma (`snow` de 0,35 no planalto, 0,9 no pinheiral e 1 na cidade), aplicado sobre as peças que já existiam (pinheiros, rochas, muralha).
- **Hrimvald:** fortaleza de casas nórdicas e torres de madeira. A lenha toda está trancada numa jaula no meio da praça, e os braseiros estão frios.
  - Moradores: Velho Osk (queima os próprios móveis para aquecer os netos, como no GDD), Brunhild (ferreira) e Bento, que deixa Pradoluz e vai com o Lio depois do Ato 2.
  - Os 6 figurantes recoloridos também estão lá.
- **Inimigos novos:**
  - morto congelado: modelo novo, usa as animações do esqueleto e uma espada velha;
  - orc da neve e golem de gelo: Retexture com o UV original, então mantêm esqueleto e animações.
  - Materiais novos: pele de orc da neve e cristal de gelo eterno.
- **Missões:**
  - **10 "Rumo ao frio"**: Nadira → chegar a Hrimvald → Osk → 6 mortos congelados no Pinheiral → Osk. Termina com `act3_hrimvald`.
  - Secundária **"Os móveis do Osk"**: 4 feixes de galhos no Pinheiral. Dá só ouro e itens, sem XP.
  - Secundária **"Carvão roubado"**: 8 orcs da neve no Planalto, a pedido da Brunhild.
- **Próximo (6.3b e 6.3c):** Picos Uivantes, Mina de Gelo Esquecida, 2º duelo com o Severin (empate), Castelo Ermo, Brannoc em 2 formas (Gigante de Gelo, com chão que congela), a morte do Bento (ilustrações) e o salto de 2 anos com o Lio mais velho.

## Fase 6.3b: Picos Uivantes, Mina de Gelo e o 2º duelo (12/11/2026)
- **Picos Uivantes** (37–40): ficam ao norte de Hrimvald. A saída norte da cidade abre com `act3_hrimvald`. São cristas de rocha gelada (peça nova `env_rocha_gelo`) com cristais de gelo que brilham.
  - O caminho termina numa crista fechada por rochas, onde o Severin espera.
- **2º duelo com o Severin (empate)**, `severin_2`:
  - a luta para quando ele chega a 50% de vida ou o herói a 25%;
  - ele está mais rápido e ganhou um avanço em linha;
  - na fala final, ele admite o empate e começa a hesitar sobre os Arautos;
  - a flag `severin_duel_2` abre a entrada da mina.
- **Mina de Gelo Esquecida** (39–42): masmorra com os mesmos corredores da Mina dos Corvos, congelada.
  - Tem cristais de gelo, os inimigos do frio e o **Guardião de Gelo** no fundo: o golem de gelo em tamanho de chefe. Ele chama 2 mortos congelados abaixo de 60% de vida.
  - No `boss_sim` (nível 42, com peças épicas e poções) o robô venceu em 51 s com vida mínima de 53%; depois disso a vida do Guardião subiu de 2.200 para 2.600.
  - A saída do fundo vai para o Castelo Ermo e fica fechada até a 6.3c (`castelo_open`).
- **Missão 11 "A mina debaixo da montanha"**: Brunhild → Picos → duelo → Guardião → Bento.
  - Termina com `act3_mine`.
  - O Bento decide ir junto ao castelo: é a preparação para a cena do Ato 3.

## Fase 6.3c: Castelo Ermo, Brannoc, Bento e o salto de 2 anos (12/11/2026)
- **Castelo Ermo** (42–44): chega-se pelo túnel do fundo da Mina de Gelo, que abre com `act3_mine`. Tem um pátio externo com a guarda gelada e o pátio do trono como arena.
- **Brannoc, Arauto do Frio:**
  - forma 1: velho senhor com machado de duas mãos; corta, gira, avança e chama 2 orcs da neve;
  - forma 2: **Gigante de Gelo**, com soco, pancada em círculo e espinhos de gelo (barragem);
  - escudo de quebra, e a **arena a favor** são 5 cristais de gelo que curam 15% (o herói quebra os cristais);
  - no `boss_sim` (nível 44, peças épicas e poções): 91 s, sem mortes, vida mínima de 39%, 4 quebras de escudo.
- **Cena do Bento** (pedido do GDD): quando o Gigante cai, toca uma cena ilustrada de 4 painéis no estilo do prólogo (`StoryOverlay`, configurada em `data/story.json`):
  1. o Bento entra na frente do golpe;
  2. a despedida, em que ele pede para o Lio guardar o cachecol;
  3. Hrimvald com as chaminés acesas e o túmulo na colina;
  4. o treino sozinho nas montanhas;
  - termina com "Dois anos depois...".
  - Como funciona: o chefe tem `after_story`/`after_flag`/`after_map` em enemies.json, que liga a flag `time_skip` e leva o herói de volta a Hrimvald.
- **Salto de 2 anos:**
  - com `time_skip`, o Lio usa o modelo `hero_lio_adulto`: um pouco mais alto, cicatriz na bochecha, cabelo preso e o cachecol vermelho do Bento. Usa as mesmas animações;
  - o retrato do Lio muda no HUD e nos diálogos (`portrait_after` no npcs.json);
  - as skins compradas continuam com o rosto jovem; quando uma está vestida, ela tem prioridade.
- **Hrimvald depois:** braseiros e fogueira acesos, a jaula de lenha some, o túmulo do Bento aparece na colina e o Bento sai da cidade. O Osk e a Brunhild ganham falas novas.
- **Missão 12 "O Arauto do Frio"** fecha o Ato 3 (`act3_done`). O Osk conta do mensageiro dos elfos de Lys'Thaël, gancho do Ato 4.

## Fase 6.4a: a estrada para Lys'Thaël (12/11/2026)
- **Caminho, como no GDD:** Picos Uivantes (saída leste, abre com `act3_done`) → Vale do Degelo (44–46, neve derretendo, riachos e flores) → Mata Úmida (46–48, musgo, cogumelos que brilham) → Bordas do Pântano (48–50, água parada e mangues) → **Lys'Thaël**.
  - O bioma passa de `snow` para `moss`.
- **Lys'Thaël:** cidade élfica com casas nas árvores, cerca de galhos vivos e lanternas de cristal. No centro fica a **Árvore-Mãe murchando**. Moram lá o Elarion (loja com peças épicas e poções) e o Faenor (ferreiro).
  - O portão norte, para o Pântano das Raízes, abre com `act4_lysthael`.
- **Inimigos:**
  - **cultista do silêncio** (modelo novo, com as animações do bandido): luta de perto e joga orbes sombrios à distância (projétil `look: "orb"`);
  - homem-lagarto do pântano e morto do pântano: Retexture, mantêm esqueleto e animações.
  - Materiais novos: escama do pântano e seiva amarga.
- **Missões:**
  - **13 "A floresta em silêncio"**: chegar a Lys'Thaël → Elarion → 8 cultistas nas Bordas → Faenor, que conta da Velyra na Torre do Vigia.
  - Secundárias: **"Os cantos escondidos"** (4 partituras na Mata Úmida, para o Elarion; só ouro e itens) e **"Lâmina de raiz"** (8 mortos do pântano, para o Faenor).
- **Próximo:**
  - 6.4b: Pântano das Raízes, Torre do Vigia Élfico, 3º duelo com o Severin (ele perde e começa a duvidar) e a revelação do Bram;
  - 6.4c: Velyra em 2 formas (Dríade de Espinhos, raízes que prendem) e a Árvore-Mãe florescendo.

## Ajustes do dono depois da 0.2.4 (12/11/2026)
- **Queda de quadros ao soltar skill:** era o 1º uso de cada efeito, que compilava shaders e criava malhas na hora. Agora `SkillVfx.prewarm` toca todos os efeitos (skills, impactos de chefe, projéteis) bem pequenos atrás da tela de carregamento de cada mapa.
- **Botões maiores:** skills, correr e esquiva +10% (raio 46 → 51 e 40 → 44). O botão de atacar ficou igual.
- **Todo chefe tem um efeito** nos golpes (`status` do ataque em enemies.json):
  - atordoar (`stun`): não anda nem ataca;
  - lentidão (`slow`): perde parte da velocidade;
  - enfraquecer (`weaken`): causa menos dano;
  - veneno (`poison`): perde % da vida por segundo.
  - Aparecem como ícone vermelho na barra de efeitos e com texto sobre o herói.
  - O teste confere que todo chefe (fora os duelos) tem pelo menos um.
- **Efeito visual nos golpes dos chefes:** golpes de área e em linha agora têm onda de choque, rachaduras e pedras na cor do chefe (`SkillVfx.boss_impact`). Antes o golem só piscava um disco.
- **Mobs +20% de dano** em campos e masmorras: `mob_atk_mult: 1.2` em `scaling_per_level`. Não vale para chefes.
- **Mais mobs depois das cidades:** `enemy_density` em progression.json multiplica o máximo de cada zona.
  - O 1º campo depois de cada cidade fica igual.
  - Os campos seguintes ganham +50%, e as masmorras +30–40%. As zonas também ficam 2 m maiores.
- **Simulação de equilíbrio:** com os efeitos, a luta do Brannoc (nível 44) varia entre 110 e 200 s (antes ~90 s). A vida mínima continua em 36–39%, sem mortes. O "enfraquecer" ficou em −15% por 3 s (Gorvan −20%) para não pesar demais.

## Fase 6.4b: o Pântano das Raízes e a Torre do Vigia (12/11/2026)
- **Pântano das Raízes** (50–53), ao norte de Lys'Thaël:
  - raízes gigantes saindo da água, cogumelos e juncos;
  - lagartos, mortos do pântano e cultistas.
  - Uma parede de raízes com portão fecha a clareira diante da Torre do Vigia, onde o Severin espera.
- **3º duelo com o Severin** (nível 54):
  - desta vez ele perde (para em 8% da vida);
  - depois, a cena ilustrada "severin_doubt": a Velyra ameaça crianças élficas, o Lio as protege e o Severin, de joelhos, começa a duvidar.
  - O `duel` ganhou `end_story` (cena depois da fala final) e `after_story_dialogue` (fala depois da cena).
- **Torre do Vigia Élfico** (53–55): masmorra fechada, com cerca élfica, lanternas e raízes.
  - No alto, o **Guardião de Espinhos**: um golem de madeira escura com rachaduras roxas. É Retexture do golem, usa as mesmas animações.
  - Golpes:
    - soco com veneno;
    - pancada que atordoa;
    - raízes que brotam do chão e deixam lento;
    - abaixo de 60% da vida, chama 2 cultistas.
  - Simulação: nível 55, vence em ~93 s, vida mínima 39%.
  - A saída para o topo (Velyra) abre com `act4_tower`.
- **Missão 14 "O vigia e o segredo":**
  1. Faenor;
  2. entrar no pântano;
  3. duelo com o Severin;
  4. Guardião de Espinhos;
  5. Bram, que veio até Lys'Thaël (aparece com `severin_duel_3` e sai de Pradoluz). Ele conta que o dedo do pai na neve tinha um corte limpo de faca: o Doran pode estar vivo.
- **Próximo:** 6.4c, a Velyra em 2 formas (Dríade de Espinhos, raízes que prendem) no topo da torre e a Árvore-Mãe florescendo.

## Fase 6.4c: a Velyra e a Árvore-Mãe florescendo (12/11/2026)
- **Topo da Torre** (nível 56): plataforma octogonal a céu aberto, com cerca élfica, lanternas e raízes negras. Por fora, anéis de árvores do pântano lá embaixo. A saída abre com `act4_tower` (fim da missão 14).
- **Velyra, Arauta do Silêncio** (forma 1): elfa arqueira com um arco de galho vivo.
  - Usa as animações do arqueiro e a conjuração da Sahra, o que economizou créditos de animação.
  - Mantém distância (`keep_distance`).
  - Golpes:
    - flecha com veneno;
    - chuva de flechas que deixa lento;
    - linha de cipós que prende;
    - chute;
    - chama 2 cultistas abaixo de 80% da vida.
  - O 1º modelo tinha cabelo longo solto, e o esqueleto automático do Meshy prendia o cabelo aos braços (esticava quando ela levantava os braços). Tentei corrigir os pesos no Blender sem sucesso; refiz com o cabelo preso num coque trançado e a capa curta nos ombros (mais 23 créditos).
  - **Regra para os próximos personagens:** nada de cabelo longo solto ou capa comprida perto dos braços.
- **Dríade de Espinhos** (forma verdadeira, 50% da vida): gigante de casca e espinhos com rachaduras roxas. Usa as animações do Gigante de Gelo.
  - Golpes:
    - chicotada com veneno;
    - pancada que atordoa;
    - raízes que brotam do chão e prendem;
    - "agarrar": um círculo grande sob o herói que prende por 2,2 s.
  - Segue a regra dos Arautos:
    - escudo de quebra;
    - **flores de espinho** brotam na arena e curam 10% da vida quando ela passa por cima;
    - o herói corta as flores atacando perto delas.
- **Efeito novo "preso" (`root`):** o herói não anda nem rola, mas ainda ataca e usa skills. A **investida e o salto soltam na hora**: é a resposta do jogador às raízes. Aparece na barra de efeitos ("Preso pelas raízes"). O Lio explica as duas regras na fala depois da troca de forma.
- **Depois da luta:** cena ilustrada "velyra" (3 painéis: a Dríade se desfaz, a Árvore-Mãe floresce, Lys'Thaël canta de novo) e volta a Lys'Thaël (`lysthael_bloom`).
  - A Árvore-Mãe murcha some (`unless_flag: velyra_defeated`), e no lugar dela aparece a florida, com luz rosa.
- **Missão 15 "A Arauta do Silêncio":**
  1. subir ao topo da torre;
  2. derrotar a Velyra;
  3. falar com o Elarion sob a Árvore-Mãe, que conta do mensageiro de Altaréa (gancho do Ato 5, Cassian).
  - Liga `act4_done`.
- **Equilíbrio** (robô do `boss_sim`, nível 56, com poções e peças épicas): vence em 150–190 s, vida mínima 37–39%, sem mortes. No começo a luta passava de 5 min (as flores curavam 15% e o robô não as corta). Ficou assim:
  - cura: 10%;
  - espera de 12 s antes de procurar outra flor;
  - vida: 3000 (Velyra) e 3300 (Dríade).
- **Nomes que sumiam:** o gerador de falas é dono das chaves `NPC_`, e os nomes postos à mão no strings.csv (Sahra, Osk, Brunhild, Brannoc, Elarion, Faenor) eram apagados a cada rodada. Por isso a caixa de fala mostrava o código no lugar do nome. Agora ficam no `gen_act1_text.py`, e um teste confere que todo personagem tem nome.
- `add_fingers.py`: plano B para mãos em que um dedo não recebe vértices (usa o dedo vizinho).

## Fase 6.5a: a estrada para Altaréa e a capital (12/11/2026)
- **Ato 5 em 3 etapas:**
  - 6.5a (esta): estrada e capital;
  - 6.5b: Castelo do Arauto, Cassian em 2 formas e o Severin do lado do Lio;
  - 6.5c: Escadaria do Céu, Cidadela Celeste, Vaelor e o final.
- **Caminho:** o portão leste de Lys'Thaël (abre com `act4_done`) leva à **Estrada Real** (56–58, trigo, moinho, estandartes da Lei). Dela se chega aos **Arredores da Capital** (58–60, sítios fechados, postos de controle, decretos nos postes) e depois a **Altaréa**.
- **Altaréa:** capital branca dentro de muralhas.
  - Casas brancas de telhado azul e casas altas de enxaimel.
  - Na praça, a fonte com a estátua do juiz (o Cassian); estandartes e quadros de decretos por toda parte.
  - Uma barricada da resistência num canto.
  - Moram lá:
    - **Isolda**: líder da resistência, quem dá a missão;
    - **Aurélio**: loja, com o melhor do jogo até aqui (épicos, trevo e broca reais);
    - **Matias**: ferreiro.
  - O portão norte, para o Castelo do Arauto, abre com `act5_castle` (6.5b).
- **Inimigos novos:**
  - **guarda da Lei**: modelo novo com as animações do bandido e uma espada comum;
  - **arqueiro da Lei**: modelo novo com as animações e o arco do arqueiro;
  - **carcereiro**: Retexture do orc; a pancada com corrente deixa lento.
  - Materiais novos: **Selo da Lei** e **corrente de ferro**.
  - Os Arredores são o 2º mapa depois de uma cidade, então têm 50% mais mobs.
- **Missões:**
  - **16 "A Lei de Ferro"**: Estrada Real → 8 guardas nos Arredores → Altaréa → Isolda (o irmão dela está preso nas minas do castelo). Liga `act5_city`.
  - Secundárias:
    - **"Decretos rasgados"** (5 decretos nos Arredores, para o Aurélio);
    - **"Correntes partidas"** (6 carcereiros, para o Matias).
- **Mais nomes que sumiam:** os materiais pele da neve, cristal de gelo, escama do pântano e seiva amarga apareciam como código; agora ficam no gerador. O teste de nomes passou a conferir NPCs, itens, inimigos e missões.

## Forja, níveis dos equipamentos e masmorras (pedido do dono, 12/11/2026)
- **Janela da forja:**
  - tamanho fixo em todas as abas (antes encolhia ao abrir um encaixe e cada aba tinha um tamanho);
  - abas curtas com ícone: Fortalecer, Gemas, Criar, Desmontar;
  - custos como ícones com "tenho/preciso" embaixo (ouro, lingote, materiais e a peça de base); o que falta fica **cinza** e com o número em vermelho;
  - na criação, a lista inteira fica cinza no que ainda não dá para fazer;
  - Trevo e Amuleto viram "Usar (34)" com o ícone; a broca mostra o ícone e quantas você tem;
  - desmontar mostra os ícones do que você recebe;
  - título só "Forja", porque agora há vários ferreiros.
- **Nível para usar** (antes 1/4/8/11):

  | Raridade | Cor | Nível |
  |---|---|---|
  | Comum | branco | 10 |
  | Raro | azul | 20 |
  | Épico | roxo | 40 |
  | Lendário | dourado | 60 |
  | **Mítico** (novo, "da Chama Rubra") | vermelho | 80 |
  | **Celestial** (novo, "do Herdeiro Celeste") | ciano | 100 |

  - As duas raridades novas têm 8 peças cada (atributos do lendário ×1,6 e ×2,4), ícones e espada 3D próprios. Só saem da forja.
- **Criação em degraus:**
  - criar uma peça rara gasta a peça comum do mesmo tipo; a épica gasta a rara, e assim até a celestial;
  - a peça de base precisa estar na mochila, sem estar equipada; vai a de menor "+", e as gemas dela voltam para a mochila;
  - do épico para cima, cada peça pede também **10 Insígnias de Chefe**;
  - desmontar devolve os materiais (e as insígnias), mas não a peça de baixo.
- **Insígnia de Chefe:** cai do chefe final de cada masmorra:

  | Chefe | Insígnias |
  |---|---|
  | Golem | 2 |
  | Gorvan | 3 |
  | Sahra | 4 |
  | Guardião de Gelo | 4 |
  | Brannoc | 5 |
  | Guardião de Espinhos | 5 |
  | Velyra | 6 |
  | Cassian | 7 |

- **Placa "Resetar masmorra"** na entrada das 8 masmorras com chefe:
  - aparece quando o chefe já foi derrotado;
  - apertar traz o chefe de volta (`Session.dungeon_resets`, salvo no save);
  - o reset é sempre manual;
  - na repetição não tocam a fala de abertura, as falas da troca de forma nem a cena ilustrada, e o herói não é levado para outro mapa;
  - duelos (Severin) não têm placa.
- **Equilíbrio com as regras novas:** o robô do boss_sim usa a melhor raridade que o nível permite. A Sahra no nível 28 (só peças raras) continua vencível: 110 s, vida mínima 36%.

## Fase 6.5b: o Castelo do Arauto e o Cassian (12/11/2026)
- **Castelo do Arauto** (60–63): o portão norte de Altaréa abre na missão 17 (`act5_castle`). Usa a planta do Castelo Ermo em pedra branca e ouro: trono da Lei, estandartes, braseiros, guardas, arqueiros e carcereiros.
- **O Severin muda de lado:** espera no portão do castelo, conta que não dorme desde o pântano e segura o portão para o Lio passar ("Bem-vindo ao lado certo").
- **Cassian, Arauto da Lei** (forma 1): juiz de toga com um martelo de julgamento. Usa as animações de duas mãos do Brannoc.
  - Golpes:
    - veredito (enfraquece);
    - rodopio do martelo;
    - sentença em linha (atordoa);
    - chama 2 guardas.
- **Colosso de Armadura** (forma verdadeira): armadura vazia movida pela lei. Usa as animações do Gigante de Gelo.
  - Golpes:
    - soco (enfraquece);
    - pancada (atordoa);
    - correntes que prendem;
    - édito (deixa lento).
  - Regra dos Arautos: escudo de quebra e **Pilares da Lei**, que o curam em 10%; o herói os quebra atacando.
- **Simulação** (nível 63, peças lendárias): vence em 130–230 s, vida mínima 38%, sem mortes. A vida foi de 3400 para 2800 nas duas formas.
- **Depois:** cena ilustrada "cassian" (o Colosso cai e o Severin segura o portão; Altaréa rasga os decretos; a escada de luz até a Cidadela Celeste) e volta para Altaréa.
- **Missão 17 "O portão e o juiz":**
  1. Isolda (o plano);
  2. Severin no portão;
  3. 6 carcereiros (libertar os presos);
  4. Cassian;
  5. Isolda (o irmão livre e a escada no céu).
  - Liga `act5_stairs`.
- **Próximo:** 6.5c, Escadaria do Céu, Cidadela Celeste, Vaelor em 3 fases e o final.

## Correções do dono, casas por dentro e oferta de boas-vindas (12–13/11/2026)
- **Títulos das conquistas** apareciam como código ("TITLE_FIEL"...). Eram mais 10 textos que o gerador de falas apagava; agora ficam nele. O teste de nomes passou a varrer também a rotina, as lojas e a loja especial.
- **Forja:**
  - o desmontar mostra também as peças **equipadas** (marca verde, "Equipado"); ao desmontar uma delas o jogo pergunta "Tem certeza?" antes;
  - chances menores para gastar mais: +19 em 5% e +20 em 3% (eram 10% e 5%); o 3º encaixe com a Broca comum em 5% (era 25%). A Broca Real continua sempre dando certo.
- **Loja dos comerciantes** sem a aba "Especial": a loja especial fica só no botão do topo.
- **Casas por dentro:**
  - as residências das cidades ficaram 20% maiores;
  - perto de uma casa aparece o botão **"Entrar"**;
  - casa de 1 andar: cozinha, sala e quarto juntos (`interior_casa`);
  - casa de 2 andares: cozinha e sala embaixo (`interior_terreo`), escada para o quarto em cima (`interior_cima`);
  - **vasos** dão poções ou moedas (pouca quantidade, pela faixa de nível) e enchem de novo em 30 minutos, separados por casa (`data/world/houses.json`);
  - a saída volta para a rua, no ponto onde o herói entrou (`Session.house_return`);
  - entrar e sair usa o escurecer rápido, sem tela de carregamento.
  - Móveis novos do Meshy: cama, mesa, fogão, armário, estante, sofá, tapete, escada, vaso e parede de madeira.
- **Oferta de boas-vindas:** produto novo `premium_7d_oferta` (passe premium de 7 dias por R$ 4,99).
  - Só para quem nunca comprou: some depois de qualquer compra (marcador `store_bought`).
  - Aparece num banner quando o jogo abre pela tela inicial (nunca nos testes) e no topo da loja especial.
  - Lista completa dos produtos com os textos reais para o Play Console: `docs/loja/produtos_play.md`.

## Fase 6.5c: a Escadaria do Céu, o Vaelor e o final (13/11/2026)
- **Caminho:** um portal atrás do trono do Castelo do Arauto (abre com `cassian_defeated`) leva à **Escadaria do Céu** (63–64, degraus de luz entre nuvens, sentinelas e vigias celestes). De lá se sobe à **Cidadela Celeste** (65), uma plataforma de nuvens.
- **Vaelor em 3 fases** (as formas agora podem trocar mais de uma vez; as falas de cada troca ficam na forma nova, em enemies.json):
  1. **Vaelor, Senhor dos Céus:** deus de máscara dourada com a espada do sol. Usa as animações do Brannoc.
  2. **Vaelor Desmascarado** (66% da vida): a máscara cai e aparece o rosto do **Doran**, a mão sem um dedo. O Lio entende que o deus é o pai dele. O Doran pede que ele fuja; o Lio não foge.
  3. **Vaelor Corrompido** (33%): o Sem-Rosto toma o corpo. Gigante de armadura negra e roxa, com as animações do Gigante de Gelo. Escudo de quebra, **cristais do vazio** que o curam e raízes do vazio que prendem.
- **Final:** cena ilustrada (5 painéis):
  1. a máscara cai;
  2. o Doran abraça o filho e pede perdão;
  3. o Sem-Rosto arranca o resto do poder e foge por uma fenda além do céu;
  4. as cinco cidades livres;
  5. em Pradoluz, algo enorme abre os olhos entre as estrelas.
  - Depois vêm os **créditos** (`CreditsRoll`, dá para pular tocando) e a volta a Pradoluz.
  - A missão 18 termina falando com a Marta e liga `game_complete`. O jogo continua: masmorras, forja, rotina.
- **Simulação** (nível 65, peças lendárias): vence em ~160 s, vida mínima 37%, sem mortes. A vida foi de 3000 para 2700.
- **Pós-jogo** (Fase 6.6): feito na 0.3.0, ver abaixo.

## Fase 6.6: pós-jogo (13/11/2026)
- **Modo Infernal:** depois do final (`game_complete`), cada masmorra com chefe ganha uma segunda placa, vermelha, "Modo Infernal", ao lado da "Resetar masmorra".
  - O chefe volta num nível alto: Golem 60, Gorvan 62, Sahra 66, Guardião do Gelo 72, Brannoc 76, Guardião de Espinhos 82, Velyra 86, Cassian 92 e Vaelor 100 (`progression.json` → `infernal.levels`).
  - Os monstros do mapa sobem a mesma diferença de nível e ficam vermelhos, como o chefe.
  - Prêmios: os drops do chefe e dos monstros saem 2 vezes (inclusive as Insígnias), o ouro dobra, e cai a **Essência Infernal** (o chefe dá de 1 a 6, conforme a masmorra; cada monstro tem 6% de chance de dar 1).
  - O modo acaba quando o chefe cai; para outra rodada, é só usar a placa de novo.
- **Essência Infernal** na forja: as peças míticas pedem 4 e as celestiais 8 (além das 10 Insígnias). Assim as duas últimas raridades ficam para o pós-jogo, que é quando o herói chega aos níveis 80 e 100.
- **Conjuntos:** além do Sol Alado (lendário), as 5 peças de armadura míticas formam a **Chama Rubra** (ataque, crítico e dano das skills) e as celestiais o **Herdeiro Celeste** (vida, defesa, ataque, crítico e recarga).
- **Visual do conjunto:** com as 5 peças de um conjunto, o Lio veste a armadura dele (3 modelos novos do Meshy, com o mesmo esqueleto e as animações do herói). Um visual comprado continua tendo prioridade; tirando uma peça, ele volta à roupa normal.
- **17 conquistas novas:** os chefes Sahra, Brannoc, Velyra, Cassian e Vaelor, terminar o jogo, níveis 40/65/80/100, 1/10/30 chefes no Modo Infernal, o Vaelor nível 100, criar uma peça mítica e uma celestial, e chegar ao +20. Cada uma dá um título com bônus.
- Fotos: `res://tests/postgame_capture.tscn -- <pasta>`.

## Fase 6.7: correções do teste no celular e conteúdo diário (13/11/2026)
O dono jogou até o primeiro Arauto (o Espantalho) e pediu estas mudanças.
- **Bugs corrigidos:**
  - **Missão dos orcs (Bento):** o acampamento marcado às vezes só sorteava bandidos. Agora as zonas perto de uma caçada mantêm pelo menos 2 monstros do tipo pedido (aparecem do lado longe do herói), e a seta aponta para o mais perto (`QuestLog.wanted_kills`, `EnemyZone._keep_quest_targets`).
  - **Não dava para sair da casa:** a parede invisível da frente ficava antes da saída. Agora a frente tem uma mureta com uma abertura de porta.
  - **Joystick travado depois da fala do Arauto:** o dedo era solto enquanto o joystick estava escondido. Agora ele solta sozinho quando some.
  - **Espantalho travado / andando parado:** um monstro que quer andar mas quase não sai do lugar contorna o obstáculo por um instante; a animação de andar segue a velocidade de verdade.
- **Casas por dentro:** chão de tábuas (shader `wood_floor`), paredes com o dobro da altura e nada em volta (fundo escuro). Campo `room` e `height` nas paredes do mapa.
- **Bordas das cidades** (campo `town_edge`): mata fechada fora dos muros (MultiMesh, sem colisão, longe das saídas e trilhas), chão mais escuro por baixo, sem grama fora dos muros e algumas árvores por dentro, junto do muro. Pradoluz, Qaressa (palmeiras), Hrimvald (pinheiros), Lysthael e Altaréa.
- **Corrida:** o botão Correr usa a animação de corrida de verdade (`Lean_Forward_Sprint`, já existia) e ficou mais lenta: 1,35× em vez de 1,6×.
- **Vasos:** não pegam mais só de passar por cima. Aparece "Pegar", o Lio se abaixa, e o vaso continua lá (um brilho dourado mostra os que têm algo).
- **Itens recebidos:** lista com o ícone, a quantidade e o nome na cor da raridade, embaixo dos atalhos do topo (`LootFeed`).
- **MP:** as skills gastam **MP** (`mp_cost` em skills.json), não fôlego. O fôlego fica para a esquiva e a corrida.
  - 100 de MP, +2 por nível e +2 por ponto de Foco; recupera 3/s, e cada golpe básico que acerta devolve 3.
  - Barra azul ao lado da verde.
  - Poções de MP pequena, média e grande. Nos baús, prêmios, vasos e drops elas substituíram as de fôlego; as de fôlego continuam nas lojas.
  - Simulação com MP: Gorvan (nível 12) 96 s, Brannoc (44) 166 s, Velyra (56) 159 s, sem mortes, vida mínima 33–39%.
- **Atalhos de poção:** são 3 e qualquer poção vai em qualquer um ("Atalho: 1 2 3" na mochila), como nas skills. Pensado para a colheita de ervas de depois. Saves antigos ficam com vida, MP e o tônico que tinham.
- **Dificuldade não dá mais XP nem itens:** o Difícil só deixa os inimigos mais fortes.
- **Drops:** equipamento épico e lendário não cai mais, porque eles são feitos na forja. No lugar, cai uma peça rara e as Insígnias de Chefe que a forja pede (10 por épica, 20 por lendária). Os baús com peças épicas ficaram com uma rara + 10 Insígnias.
- **Poções no começo:** as chances de cair poção dos monstros iniciais caíram pela metade, e as dos outros monstros em 25%.
- **Missões na lateral:** até 3 ao mesmo tempo (a seguida primeiro), cada uma com "Seguir", e um cabeçalho "Missões (n)" que esconde ou mostra a lista (`QuestTracker`). A janela de missões ficou grande, com rolagem, e as concluídas foram para uma coluna à direita.
- **Viagem:** a janela mostra o mapa-múndi ilustrado (Meshy) com um botão em cada mapa que tem ponto ativado; com dois pontos, abre uma listinha. "Você está aqui" marca o mapa atual (`data/world/world_map.json`).
- **Imagens novas (Meshy, 21 créditos):**
  - banner da oferta (o Lio fazendo força com o braço);
  - o mapa-múndi;
  - as 4 cartas da escolha de dificuldade;
  - uma folha de ícones: poções de MP, quadro, procurado, troféu e caveira, e ervas guardadas para depois.
- **Dificuldade Extrema:** inimigos 80% mais fortes, perder custa 50% mais e **o mundo não espera**. Os monstros de todo o mundo têm pelo menos o "nível do mundo", que sobe com o tempo jogado na metade do ritmo médio do herói (a curva do `gen_xp.py`). Exemplos: 2 h → nível 13, 4 h → 22, 8 h → 35, 15 h → 50. Quem demora encontra até as áreas do começo mais fortes. Um aviso aparece quando o nível do mundo sobe.
- **Placa de dificuldade na frente de cada masmorra** (no mapa de onde se entra): Normal, Desafio (vida +50%, dano +30%, drops +50%, ouro +40%) ou Pesadelo (vida ×2,2, dano +70%, drops ×2, ouro +80%). Fica guardada por masmorra (`boards.json` → `tiers`).
- **Quadro de missões na frente de cada masmorra:** 3 missões por dia em cada quadro, uma de cada vez. As opções são derrotar 15 monstros lá, derrotar 8 de um tipo (muda a cada dia) ou derrotar o chefe de novo (ele volta ao aceitar). O prêmio é ouro (30 × o nível da masmorra) e 1 item extra (poção, Trevo, Broca, Insígnias ou gema).
- **Procurado em cada cidade:** um chefe do mundo por dia, num dos campos da região da cidade, em lugar sorteado. Por exemplo, o de Pradoluz fica na Floresta ou nos Campos.
  - São versões pintadas e mais fortes de chefes (vida ×3, dano +25%, escudo de quebra), sempre 3 níveis acima do herói:
    - Colosso Musgoso;
    - Rainha Rubra das Dunas;
    - Titã do Gelo Eterno;
    - Fera dos Espinhos Antigos;
    - Juiz Sem Nome.
  - "Seguir" no cartaz faz a seta levar até ele.
  - Prêmio: 120 × o nível em ouro, 6 Insígnias, 2 gemas, Trevo e Broca (e 2 Essências Infernais depois do final).
  - 4 conquistas novas: Procurados 1 e 10, quadros 10 e 50.
- **Lagos e rios (pedido do dono, 13/11):** a água agora é uma faixa curva e suave (Catmull-Rom), com pontas arredondadas, margem molhada que se mistura ao chão e um shader novo (`water.gdshader`): fundo azul no meio, raso turquesa nas bordas, linha de espuma, ondinhas e brilhos. Cada rio pode ter cor própria (`deep`/`shallow`; pântano verde-escuro, vale gelado mais claro).
  - **Vida na água** (`PondLife`, tudo animado por código): vitórias-régias boiando, sapos sobre elas que pulam de vez em quando e mergulham quando o herói chega perto, e peixes que saltam da água perto do herói, com respingo.
  - Mapas de neve têm só peixes.
  - Modelos novos do Meshy: peixe, vitória-régia e sapo (54 créditos).
  - Fotos: `res://tests/pond_capture.tscn -- <pasta> [mapa ...]`.
- **Áudio com o ElevenLabs:** plano em `docs/AUDIO.md`.
- **Ajustes do HUD (dono, 13/11, versão 0.3.2):**
  - o MP divide o anel do retrato com a vida (vida à esquerda, MP à direita) e o número do MP fica embaixo do da vida (a barra azul de baixo saiu);
  - o fundo cinza dos ícones novos foi removido;
  - a corrida levanta a cabeça e endireita o tronco (`tweak` na ação `sprint`, aplicado por `PoseTweak`);
  - o menu do personagem ficou em duas colunas, com **Salvar** e **Sair para o menu** (que pede um segundo toque e salva antes de sair).

## Áudio do ElevenLabs (13/11/2026, versão 0.3.3)
- **Gerado no plano Creator:** 22 músicas (2 versões cada) e 57 efeitos (com variações), 62.834 créditos no total. Estilo aprovado pelo dono no primeiro lote (Pradoluz, luta, passos, golpes, pássaros, floresta).
  - Por enquanto entrou a **versão 1 de cada música**; o dono pode trocar qualquer uma (`python -X utf8 tools/audio/eleven.py aprovar <id> 2`).
  - Os efeitos entram com todas as variações, que tocam sorteadas.
- **Música por lugar:**
  - cada cidade tem a sua, calma (Pradoluz, Qaressa, Hrimvald, Lysthael, Altaréa), e as casas uma de caixinha de música;
  - 5 de exploração por tipo de campo;
  - 3 de ação para masmorras e Ruínas (mina, ruínas/torres, castelos);
  - uma para o céu, outra para chefe e a "arauto" para as formas verdadeiras dos Arautos, o Vaelor e os Procurados (campo `music` em enemies.json);
  - vitória e derrota.
- **Música de luta:** nos campos abertos, quando um monstro persegue o herói a até 20 m, entra a `luta_campo`. Ela volta para a do mapa 4 s depois da luta. Cidades, casas e masmorras não trocam (`no_combat_music`).
- **Ambiente:** som contínuo e baixo por mapa (`map_ambience`): floresta, campo, deserto, neve, pântano, mina, cidade, e lareira nas casas.
  - Sons soltos tocam de vez em quando perto do herói (pássaros na floresta e nos campos, sapos no pântano), com intervalo de 6 a 24 s e nunca durante uma luta.
  - Nos lagos, só 30% dos pulos dos sapos coaxam.
- **Sem poluição sonora:** cada efeito tem um `gap` (tempo mínimo até tocar de novo): passos 0,12 s, golpes 0,04–0,06 s, dano de monstro 0,15 s, pássaro 3 s, sapo 1,5 s. Os ambientes ficam entre −6 e −16 dB.
- **Passos por chão:** grama, pedra/madeira (casas, masmorras, céu), areia (deserto) e neve.
- **Monstros:** dano e morte com som próprio por tipo (`enemy_sfx`):
  - humanos e orcs;
  - esqueletos e mortos (ossos);
  - golens e guardiões (pedra);
  - lagartos e cultistas;
  - mortos do pântano;
  - celestes (cristal quebrando).
- **Herói:** som de morte, a música de derrota até reaparecer, beber poção, e escudo do chefe quebrando.
- **Bichos:** o carinho no cachorro, no gato e na vaca tem o som de cada um.
- **Créditos:** as músicas do Jonathan Shaw (CC-BY) saíram. O crédito agora é do ElevenLabs, e os efeitos CC0 que sobraram (skills) continuam creditados. A tela final do vídeo promocional (`tests/promo_video.gd`, da outra sessão) ainda mostra o crédito antigo e precisa ser trocada.

## Mochilas extras e visuais (13/11/2026, versão 0.3.4)
- **Mochilas extras:**
  - Dá para vestir até **6** na tela da mochila (linha "Mochilas: x/6" com 6 encaixes; tocar num encaixe tira a mochila, se tudo ainda couber).
  - **Mochila de Couro** (marrom, +10 espaços): vendida por **3.000 de ouro** nos 4 comerciantes.
  - **Mochila Real** (roxa e dourada, +30 espaços): **R$ 1,99** na loja especial (`mochila_30`).
  - A mochila base continua com 60 espaços.
- **Visual na tela de equipamentos:** o encaixe "Visual" mostra o que está vestido. Tocar abre a lista dos visuais comprados (com o retrato de cada um) e "Sem visual". A loja especial continua vendendo; a troca agora fica aqui.
- **Retratos por visual:** o retrato do HUD e o das falas do Lio mudam com o visual (campo `portrait` do visual em characters.json). Retratos novos do Sol, da Tempestade e do Anjo.
- **Visual Anjo Dourado** (`skin_anjo`, R$ 19,90; o dono subiu o preço em 13/11):
  - armadura dourada e branca, com a Lâmina Solar;
  - **asas separadas** (um modelo de asa do Meshy, espelhado), presas ao peito e batendo por código, douradas e brilhantes; batem mais rápido em movimento (`AngelWings`);
  - **flutua no lugar de andar:** fica uns 30 cm acima do chão, balançando, e inclina para a frente ao se mover (`float` no visual).
  - Custo no Meshy: ~74 créditos, somando modelo, esqueleto, asa, retratos e ícones.
- Fotos: `res://tests/looks_capture.tscn -- <pasta>`.
- **Ajustes do anjo e da virada (dono, 13/11, versão 0.3.5):**
  - nas telas de equipamento e atributos o anjo não flutua, para não sair cortado (`float_in_place`);
  - pose de voo: ação `float` só do anjo (`extra_actions`), com uma perna dobrada para trás, a outra esticada para baixo e os pés apontados;
  - **virada de direção suave:** o herói gira até a direção do controle em vez de virar de uma vez (`TURN_RATE`), e inclina um pouco para dentro da curva.

## Desempenho e qualidade gráfica (13/11/2026, versão 0.3.6)
O dono e um amigo viram quedas de quadros em celulares mais antigos.
- **Gráficos: Baixo / Médio / Alto** nas Opções. Na primeira vez o jogo escolhe pelo celular: menos de 3,5 GB de memória ou menos de 6 núcleos fica no Baixo (e começa em 30 quadros por segundo); até 5,5 GB, Médio; acima, Alto. No PC sempre começa no Alto.

  | Nível | Resolução 3D | Sombras | Grama | Mata das cidades | Objetos soltos longe |
  |---|---|---|---|---|---|
  | Baixo | 720 linhas | desligadas | 30% | 45% | somem a 38 m |
  | Médio | 900 linhas | 1024 | 65% | 75% | somem a 55 m |
  | Alto | 1080 linhas | 2048 | 100% | 100% | sempre |

  A resolução e as sombras mudam na hora; a grama e a mata, no próximo mapa (`Game.QUALITY`, `Game.q()`).
- **Monstros longe descansam:** um monstro parado a mais de 28 m do herói (fora da tela) para de animar e só pensa 4 vezes por segundo. Os ajustes dos dedos guardam os ossos e param quando a pose já chegou.
- **Medição no PC** (`res://tests/perf_bench.tscn`):
  - Pradoluz: 130 quadros por segundo no Alto, 188 no Baixo;
  - Floresta (23 monstros): 126 → 158 no Baixo.
  - Num celular os números são bem menores, mas a proporção de ganho é parecida.

## Fase 8A — Defesa, aparar e Despertar (13/11/2026)
Pedido do dono: novas mecânicas (plano completo em `docs/FASE8.md`). A parte A é o combate.
- **Sem escudo:** o Lio continua com uma espada só e ganha o botão **Defesa**. Escudo mudaria todas as animações e os visuais.
  - **Segurar:** golpe de frente perde 70% do dano e gasta 12 de fôlego. Sem fôlego, a guarda quebra e ele fica tonto 0,8 s.
  - **Apertar até 0,3 s antes do golpe (aparar):** o golpe não pega, o herói ganha 15 de MP e o inimigo é empurrado para trás. Depois o inimigo fica tonto, com estrelinhas na cabeça e o corpo balançando: 2 s nos comuns, 1 s nos chefes. Tonto, leva +30% de dano.
  - **O que dá para aparar:** golpes de frente (inclusive dos chefes). Investidas só dá para segurar. Golpes em área (círculo, chão marcado, chuva) só esquivando. `"unblockable": true` num ataque tira a defesa.
- **Animações:** 18 créditos (Block3 para guarda e aparar, Hit_Reaction_1 para o desequilíbrio, Charged_Spell_Cast para o Despertar e Kneel para a fogueira).
  - O desequilíbrio e a tontura servem para **todos os inimigos com esqueleto**. Ficam em `characters.json` → `_shared_reactions` (mesmo esqueleto do Meshy), sem gerar animação por monstro.
- **Despertar (mudado pelo dono no mesmo dia):**
  - **História:** a cena ilustrada "O Despertar do Herdeiro" (4 painéis, 24 créditos) toca ao vencer a Sahra, Arauto da 2ª cidade. Na tempestade de areia, volta a mesma luz dourada da noite em que Lio nasceu. A Sahra reconhece a luz do Soberano no céu, o que prepara a reviravolta de Vaelor ser o pai dele.
  - **Liberação:** flag `despertar`. Saves que já tinham vencido a Sahra (`sahra_defeated`) também liberam.
  - **Sem botão próprio:** a luz enche lutando (pouco com golpes, +10 ao aparar, +40 ao vencer chefe; fora de luta esvazia aos poucos). Cheia, **segurar Atacar por 3 s** desperta.
  - **A borda do botão Atacar mostra tudo:**
    - dourada por dentro enquanto a luz enche;
    - vermelha por fora enquanto segura;
    - vermelha esvaziando com o tempo que resta.
  - **Efeito:** cabelo dourado com brilho (shader `awaken_hair`, só acima do pescoço e sem a pele), aura dourada (`AwakenAura`) e **+50% em todos os status por 12 s**.
- **HUD mais compacto (pedido do dono):**
  - Correr e Esquiva voltam para o lugar de antes.
  - **Defesa** fica em cima da 4ª skill.
  - O minimapa diminuiu (moldura de 260 para 200 px) e subiu para o topo, e o relógio diminuiu (74 para 52 px).
  - O teste confere que nenhum botão de toque encosta em outro nem no minimapa.
- **Gerador de textos** (`gen_act1_text.py`): duplicava as falas das cenas a cada vez que rodava e apagava as chaves `OPT_` feitas à mão, como "Gráficos". Agora só troca as chaves dele e tira as repetidas.
- **Sons novos** do ElevenLabs: aparar, defesa, despertar e tontura.
- **Teclado:** Q = Defesa; segurar J (Atacar) 3 s = Despertar.

## Fase 8B — Covis do Ferreiro Andarilho (13/11/2026)
Pedido do dono: um ferreiro andarilho que faz equipamentos de chefe com combos, a partir de materiais que caem em masmorras próprias.
- **Ferreiro Andarilho:**
  - NPC novo, ao lado do ferreiro de cada uma das 5 cidades (`service: "covil"`).
  - Modelo, retrato e as mesmas animações dos moradores.
  - Abre a janela `CovilPanel`.
- **Covis:**
  - Uma arena por cidade, com o visual do mapa do chefe: Pradoluz/Gorvan, Qaressa/Sahra, Hrimvald/Brannoc, Lysthael/Velyra, Altarea/Vaelor.
  - O chefe sempre está lá e luta sem as falas da história, com alguns ajudantes. A entrada fecha durante a luta e a saída volta para a cidade.
  - Abrem só depois de vencer aquele chefe na história.
- **Dias e entradas:**
  - Abrem segunda, quarta, sexta e domingo, pelo relógio do aparelho.
  - **10 entradas grátis por dia**, somando todos os covis.
  - Depois disso, cada entrada gasta 1 **Licença do Covil**, item vendido na loja especial: `licenca_covil_10`, 10 licenças por R$ 3,99.
- **Prêmio do chefe do covil:**
  - 2 a 4 **fragmentos** daquele chefe e, em metade das vitórias, 1 **essência**. Em vez dos drops da história, para não inflar as Insígnias.
  - Ouro e XP normais.
- **Forja:**
  - **Peça rara:** 8 fragmentos (a arma pede 12) + ouro (30 × nível).
  - **Épica:** a rara + 10 essências + ouro (90 × nível). A épica herda o +nível, os encaixes e as gemas da rara.
  - **Nível das peças:** o do mapa (10, 25, 40, 55 e 60).
  - **Atributos:** saem da peça épica de nível 40 de cada encaixe, ajustada ao nível; a épica tem 25% a mais que a rara.
- **Conjuntos:** 8 peças cada (arma, elmo, peitoral, luvas, calça, botas, pulseira e cinto).
  - **Armas:** a dos chefes (foice, khopesh, machado, espada de Vaelor) e a **Lâmina de Espinhos**, nova, para a Velyra. As pegadas foram conferidas em fotos.
  - **Combos com 2, 4, 6 e 8 peças**, feitos para o guerreiro (`HeroCombos`; números em `items.json` → `sets` → `effects`):
    - **Colheita Rubra:** +8% ataque · ceifar em volta (15%) · matar cura 3% · Corte Giratório puxa e +40%.
    - **Tempestade de Areia:** +6% velocidade de ataque · onda de areia a cada 4º golpe · esquiva deixa redemoinho que deixa lento · Investida +35% e deixa lento.
    - **Coroa de Gelo:** +10% defesa · aparar congela mais 1,5 s · tomar dano tira 0,5 s das recargas · Golpe Sísmico +30% e deixa lento.
    - **Coração de Espinhos:** +8% vida · devolve 20% do dano corpo a corpo · críticos fazem sangrar · Salto Devastador +35% e deixa lento.
    - **Juramento Celeste:** +5% em tudo · luz do Despertar enche 30% mais rápido · no Despertar, golpes soltam raios de luz · Julgamento chama mais 3 colunas e +40%.
  - **Combos épicos:** quanto mais peças épicas do conjunto, mais fortes, até +50%.
- **Gerador:** tudo sai de `tools/content/gen_covis.py`: itens, conjuntos, mapas `covil_*`, `data/world/covis.json` e as chaves `CV_*`.
- **Meshy:** 89 créditos.
  - Ferreiro: conceito, 3D, rig, animações e retrato.
  - 4 folhas de ícones: as 80 peças, os materiais e a licença, mais as 6 runas e os 7 peixes que já ficam guardados para as partes C e D.
  - A Lâmina de Espinhos.
- **Correções no caminho:**
  - O ferreiro antigo não usa as peças de chefe nas receitas dele.
  - A tela de equipamento mostra os combos e conta 8 peças por conjunto.

## Fase 8C — Runas e elementos (13/11/2026)
- **Encaixe:** cada skill tem 1 encaixe de runa, mesmo fora dos botões. Fica na própria tela de skills: o encaixe, a descrição da runa e as runas da mochila. Tocar numa runa encaixa e a que estava volta para a mochila. "Tirar runa" também devolve. Salvo em `Session.skill_runes`.
- **6 runas, cada uma em 3 níveis (I, II, III):**

| Runa | Efeito | Elemento |
|---|---|---|
| Fogo | Chão queimando na frente do herói (`RuneFire`) | fogo |
| Gelo | Deixa lento e às vezes congela por 1 s (chefes não congelam) | gelo |
| Raio | Salta para mais 2, 3 ou 4 inimigos | raio |
| Sangue | Cura uma parte do dano causado | — |
| Luz | Mais dano em chefes e mortos-vivos | luz |
| Eco | A skill acerta de novo com parte do dano | — |

- **Fusão:** 3 runas iguais viram 1 do nível seguinte, com o botão "Fundir 3" embaixo de cada runa.
- **Elementos:**
  - cada um dos 44 inimigos tem `weak` e `resist`, por região: gelo e mortos fracos a fogo, deserto fraco a gelo, mortos-vivos e cultistas fracos a luz, guardas da lei e celestes fracos a raio;
  - na fraqueza: ×1,5 e "Fraco!" amarelo;
  - na resistência: ×0,6 e "Resiste" cinza.
- **Golpes extras sem repetição sem fim:** os golpes extras das runas e dos combos não dão MP, não enchem a luz do Despertar e não disparam outros efeitos (`deal_damage(..., proc = true)`).
- **Quedas (1 runa nível I, às vezes II):**

| Origem | Chance |
|---|---|
| Procurado | 100% |
| Chefe da história | 60% |
| Chefe de covil | 30% |
| Missão do quadro | 30% |
| Monstro comum | 0,4% |

- **Gerador:** tudo sai de `tools/content/gen_runes.py`: itens, `data/skills/runes.json`, elementos dos inimigos e chaves `RN_*`.
- **Meshy:** nenhum crédito novo; os ícones vieram na folha da parte B.

## Fase 8D — Pesca e fogueira (13/11/2026)
- **Onde pescar:** perto de rio ou lago (até 2,2 m da margem) e fora de luta. O Atacar vira **Pescar**, com a figura de um peixe. Mapas com água: Pradoluz, Floresta, Qaressa, Dunas, Bordas do Pântano, Pântano e Vale do Degelo.
- **Como pesca (`Fishing`):**
  - O Lio senta na margem com a vara, como os moradores (a vara presa ao corpo serve para qualquer visual), e guarda a espada.
  - A boia cai na água com a linha saindo da ponta da vara.
  - Depois de 2,5 a 6 s a boia afunda e aparece um "!": é tocar Atacar em até 1 s para fisgar.
  - Para puxar, segura-se Atacar: a barra verde enche e a vermelha (tensão) sobe, com puxões do peixe. Solta-se para baixar a tensão; tensão cheia arrebenta a linha.
  - Andar ou rolar desiste.
- **Peixes:**

| Peixe | Onde e quando |
|---|---|
| Tilápia | rio, lago e oásis |
| Truta | rio e gelo |
| Carpa | lago e oásis |
| Bagre | pântano |
| Peixe-Lua | só de noite (19h–6h) |
| Peixe de Gelo | gelo |
| Peixe-Sol | lendário, 1,5% de dia em qualquer água |

  - Peixes mais raros brigam mais e demoram mais para puxar.
- **Fogueira:** em toda pedra de descanso tipo fogueira, o Atacar vira **Cozinhar** e abre a `CookPanel`.
  - Cada receita mostra a comida, o bônus, os ingredientes como figura com tem/precisa e uma panela para cozinhar.
  - "Comer" funciona ali e também na mochila.
  - **Uma comida por vez**, que vale 10 min (o Banquete do Sol, 20 min); a nova troca a anterior.
  - O bônus aparece na barra de efeitos e fica salvo.
- **9 comidas:**
  - **Peixe Assado:** qualquer peixe comum → +8% vida.
  - **Espeto de Carne:** +8% ataque.
  - **Sopa de Cogumelos:** +30% recuperação de MP.
  - **Ensopado de Peixe:** +10% defesa e +5% vida.
  - **Truta com Ervas:** +20% fôlego.
  - **Bagre Picante:** +6% crítico.
  - **Peixe-Lua Glaceado:** +15% dano de skill.
  - **Sopa Gelada:** +15% defesa.
  - **Banquete do Sol:** +10% em tudo.
- **Ingredientes (erva, carne, cogumelo):** caem de monstros (orcs e lagartos dão carne; bandidos e cultistas, erva; esqueletos e mortos, cogumelo) e são vendidos pelos 4 comerciantes.
- **Gerador:** tudo sai de `tools/content/gen_fishing.py`: itens, `data/world/fishing.json`, drops e loja (entradas marcadas com `gen`) e chaves `FS_*`.
- **Meshy:** 6 créditos, uma folha com ingredientes, panela e comidas, mais livro, estrela e chave para as partes E e F.
- **Testes:** `test_runner` ganhou `-- --only=<nome>`, que roda um teste só.

## Correção: Golens repetidos na mina (13/11/2026)
- **Sintoma (relato do dono):** na luta com o Golem apareceram 4 Golens.
- **Causa:** as zonas de monstros repõem o alvo das missões de "derrote X" perto do ponto da missão (regra da caçada aos orcs). Elas não sabiam que o Golem é chefe do mapa (fica fora da zona) e criavam outro a cada 1,5 s. O mesmo valia para todas as missões de chefe.
- **Correção:** a zona nunca cria chefes nem duelos e nunca passa de 2 do tipo pedido. Há um teste para isso (`_boss_zone_test`).

## Fase 8E — Bestiário e Maestria (13/11/2026)
- **Bestiário:**
  - O menu do retrato ganhou o botão "Bestiário". São 35 fichas; as formas dos chefes contam para o chefe.
  - **Lista:** à esquerda, com estrelas dos marcos; quem ainda não foi derrotado aparece como "???".
  - **Ficha:** o monstro girando em 3D (sombra preta enquanto desconhecido), o texto da família, onde aparece (tirado dos mapas pelo gerador), quantos foram derrotados, o bônus e o próximo marco.
  - **Fraqueza e resistência:** aparecem a partir do 1º marco.
  - **Marcos:** 50/200/1000 derrotas (chefes: 1/5/20), que dão +2/4/6% de dano contra aquele monstro.
- **Maestria:**
  - **Pontos:** no nível máximo, a XP passa a encher a barra da Maestria. Cada barra (a XP do último nível) vale 1 ponto.
  - **Ramos:** Ataque (+1% ataque), Defesa (+1% defesa), Vida (+1% vida) e Precisão (+0,4% crítico) por ponto, sem limite.
  - **Aviso:** o botão "Maestria" do menu ganha "!" quando há ponto para gastar.
- **Dados:** `data/world/bestiary.json` sai de `tools/content/gen_bestiary.py`, com as chaves `BS_*`. O progresso fica em `Session.kills`, `mastery_xp`, `mastery_points` e `mastery_spent`.
- **Meshy:** sem créditos novos; os ícones vieram na folha da parte D.

## Fase 8F — Casa do herói (13/11/2026)
- **Compra:** a casa média de Pradoluz perto do centro (marcada com `"home": true` no mapa) fica "À venda: 15000 de ouro". Perto dela aparece "Ver a casa", que abre a janela com o que tem dentro e o botão Comprar. Depois de comprada, a placa vira "Minha casa" e o botão vira "Entrar".
- **Cômodo:** mapa `casa_heroi`, do mesmo tamanho da casa térrea. As paredes da direita e da frente ficam baixas, porque a câmera olha desse lado; assim a cama e o baú não somem atrás da parede.
- **Baú:** 40 espaços próprios (`Session.home_chest`). Na janela, a mochila fica à esquerda e o baú à direita; tocar num item passa a pilha inteira, ou o que couber, para o outro lado. Peças de equipamento guardam o +nível e as gemas.
- **Cama:** dormir 1 vez por dia (dia real) cura tudo, acorda às 7 h e dá **"Descansado"**: +10% de XP (monstros e missões) por 30 min de jogo, com ícone "Zz" ao lado do retrato.
- **Suporte de armas:** modelo novo do Meshy. Mostra até 5 armas do herói, sem repetir e das melhores para as piores: a da mão, as da mochila e as do baú. As espadas ficam de ponta para baixo.
- **Troféus:** 10 pedestais de pedra com aro dourado. Na fila de trás ficam os 5 Procurados e na da frente os 5 chefes dos Covis. Cada um vencido vira uma estatueta dourada do próprio monstro; os que faltam mostram "?". O nome e quantas vezes foi vencido aparecem só no pedestal mais perto do herói.
- **Dados:** `data/world/home.json` (preço, baú, cama, suporte, troféus) e `data/maps/casa_heroi.json` (bloco `home` com as posições). Lógica em `Home`, móveis em `HomeDecor` e janelas `StoragePanel` e `HomeBuyPanel`.
- **Meshy:** `prp_suporte_armas`, 18 créditos (imagem 3 + modelo 15). O baú usa o `prp_bau` e a cama o `prp_cama`, que já existiam.

## Fase 8G — Eventos do mundo (13/11/2026)
- **Quando:** só nos campos (fora de cidades, casas, masmorras e covis), no máximo 1 por vez e a partir do nível 3. A cada 45 s de jogo num campo há 18% de chance de começar um, depois de 1 min no mapa e 7 min sem evento. Horda e chuva de estrelas só acontecem de noite (19 h às 5 h). Sair do mapa encerra o evento. Testes e ferramentas que abrem o `Main` direto nunca sorteiam.
- **Aviso:** a frase do evento aparece no meio da tela. Embaixo do minimapa fica uma faixa com o ícone, o texto curto e uma barra de progresso, no mesmo estilo da lista de missões.
- **Horda noturna:** 3 ondas (4, 6 e 8 monstros do próprio mapa, 1 nível acima das zonas) vêm de todos os lados. Depois da última, aparece um baú com ouro, 2 gemas, Trevo, poções e 60% de chance de runa. Afastar-se 30 m desiste.
- **Caravana:** um comerciante puxando uma carroça percorre a estrada maior do mapa, saindo da ponta mais perto do herói. Ele só anda com o herói a até 9 m e sem inimigos vivos, e há 2 emboscadas (a 30% e a 65% do caminho). No fim paga ouro e poções, com 30% de chance de runa. São 7 min de limite.
- **Chefe errante:** um monstro do mapa 1,7x maior, roxo, com 12x de vida e 1,5x de ataque e nome "<monstro> Errante". Ele percorre as zonas do mapa por 10 min e tem barra de chefe. Vencê-lo dá 15x o ouro, 10x a XP, 3 Insígnias de Chefe e uma runa.
- **Chuva de estrelas:** por 90 s caem 14 fragmentos brilhantes perto do herói, que ficam 40 s no chão. Passar por cima pega um **Fragmento Estelar**. Na mochila, **"Fundir (10)"** transforma 10 fragmentos numa runa aleatória de nível I.
- **Dados:** `data/world/events.json`. Lógica em `WorldEvents` (no `Main`) e nos eventos `HordeEvent`, `CaravanEvent`, `ErrantEvent` e `StarEvent` (`scripts/world/events/`). A faixa é a `EventBar`. O monstro errante usa `Enemy.make_errant` e `roam_points`.
- **Meshy:** 1 folha de ícones (6 créditos) com o fragmento, os 4 eventos e, já prontos para a parte H, 10 ícones de bênçãos e o portal da Fenda.
