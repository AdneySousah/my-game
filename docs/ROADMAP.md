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
