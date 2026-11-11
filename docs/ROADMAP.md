# Roadmap

| # | Fase | Resultado esperado | Créditos Meshy |
|---|---|---|---|
| 0 | Preparação | Git, pastas, projeto Godot para celular, regras (`CLAUDE.md`), controle de créditos | 0 |
| 1 | Documento de design | História, 4 cidades, 4 skills, curva 1–100, bestiário, itens, guia de estilo com prompts | ~0 (imagens conceito são grátis) |
| 2 | Protótipo cinza | Jogo rodando com formas simples: movimento, combate, 4 skills, IA, XP e level | 0 |
| 3 | Teste do Meshy | Guerreiro, 1 inimigo e ~10 objetos dentro do jogo, validando o fluxo inteiro | ~500 |
| 4 | Fatia vertical | Cidade 1, um campo, uma dungeon e um chefe, nível 1 a ~25. **Áudio** entra aqui (sistema, efeitos, música de Pradoluz; ver `docs/AUDIO.md`) | ~1.500 |
| 5 | Sistemas | Inventário, equipamentos, loja, NPCs, quests, diálogos, save, compras reais | ~500 |
| 6 | Expansão | Cidades 2 a 5, dungeons, conteúdo até o nível 100; **3 a 4 mapas de campo por região com transição gradual de bioma** (GDD, Parte 2), começando por ampliar o Ato 1 | ~4.000 |
| 7 | Polimento e publicação | Balanceamento, áudio, desempenho, versão Android e Windows, Play Store | ~300 |
| — | Pós-lançamento | Fantasias de evento | ~60 por fantasia |

Os créditos são estimativas e serão revistos a cada fase. A regra é gerar só o que a fase atual precisa.

## Status
- [x] Fase 0 — concluída (11/11/2026)
- [x] Fase 1 — concluída (11/11/2026): GDD 1.0 (`docs/design/GDD.md`), guia de estilo (`docs/ESTILO.md`) e 6 imagens de referência aprovadas (`docs/design/referencias/`, 39 créditos).
- [x] Fase 2 — concluída (11/11/2026): protótipo cinza aprovado pelo dono, com fôlego (esquiva, corrida e skills).
- [x] Fase 3 — concluída (11/11/2026): Lio, espada, bandido e 10 peças no jogo, aprovados pelo dono (307 créditos com o ajuste da corrida). Refinos visuais ficam para depois.
- [ ] Fase 4 — fatia vertical (plano em `docs/FASE4_PLANO.md`, aprovado)
  - [x] 4.1 Mundo e viagem (aprovado): Pradoluz, Floresta, Mina; teleporte; pontos de descanso; árvores transparentes (540 créditos)
  - [x] 4.1b Minimapa, mapa completo, rios e paredões (sem créditos)
  - [x] 4.1c Muralhas e portais + 4.2a Interface com a cara do jogo (aprovado, 210 créditos)
  - [x] 4.2b HUD com retrato: vida e XP em anel em volta do retrato do Lio, fôlego no rodapé, alerta "!" no retrato abrindo o menu do personagem (aprovado, 9 créditos)
  - [x] 4.2 Conversa e missões: código pronto (diálogo com retrato e bipes, balões, marcadores "!"/"?", rastreador, diário, estrela no minimapa, 4 missões principais e 2 secundárias, 7 NPCs do Meshy com retrato, parado e falando; 218 créditos), aprovado
