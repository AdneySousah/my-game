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
