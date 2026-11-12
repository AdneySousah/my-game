# Fase 6 — Expansão (Atos 2 a 5 e pós-jogo)

**Objetivo:** levar o jogo do fim do Ato 1 (nível ~12) até o final da história (nível ~65) e o pós-jogo (até o nível 100), com as 4 cidades que faltam, os campos entre elas, as dungeons, os Arautos, o Severin e o Vaelor. Base: GDD, Partes 2 a 6.

## Onde estamos (12/11/2026)
- **Pronto:** Ato 1 inteiro (Pradoluz, Floresta Sussurrante, Mina dos Corvos, Celeiro do Gorvan), 6 missões principais e 2 secundárias, 8 skills, inventário, equipamentos, ferreiro, lojas, rotina, save, versão Android e loja do Google Play.
- **Peças de cenário:** 46 (vila, floresta, mina). **Inimigos:** bandido, arqueiro, orc, esqueleto mineiro, Golem, Gorvan (2 formas).
- **Créditos do Meshy:** 1.867 gastos no projeto. **833** disponíveis até o ciclo renovar (por volta de **04/12**, +3.000, com reserva de 300).

## Como gastar pouco (regras da fase)
1. **Terreno, trilhas, cor do chão, névoa e luz:** feitos no Godot, sem créditos.
2. **Neve, folhas secas e musgo por shader** nas peças que já existem: a mesma árvore serve para "cheia", "seca" e "nevada".
3. **Inimigos de outra região = nova textura** (Retexture) de um inimigo que já tem esqueleto e animações (~30 créditos em vez de ~50).
4. **Peças modulares por cidade:** ~12 peças de construção por cidade, combinadas de vários jeitos.
5. **Gerar por etapa e mostrar antes de seguir**, como nas fases anteriores. Nenhum asset entra no jogo sem aprovação.

## Etapas
Cada etapa termina com algo jogável para você testar no celular (teste interno).

| # | Etapa | O que fica pronto | Créditos aprox. | Quando |
|---|---|---|---|---|
| 6.1 | **Fechar o Ato 1 e abrir a estrada** | Shader de bioma, Campos de Pradoluz, Bosque seco e Estepe de pedra, mais 2 a 3 missões secundárias em Pradoluz, inimigos da estrada | ~250 | **agora** (cabe nos 833) |
| 6.2 | **Ato 2: Qaressa** (nível 12–28) | Cidade do deserto, Dunas de Ossos e mais 3 campos até o frio, Ruínas de Ammar, Torre Afundada, Sahra (2 formas), 1º duelo com o Severin, homem-lagarto e esqueleto antigo | ~1.000 | dezembro |
| 6.3 | **Ato 3: Hrimvald** (nível 28–42) | Fortaleza na neve, Picos Uivantes e campos até o pântano, Mina de Gelo, Castelo Ermo, Brannoc, morte do Bento (ilustrações), **salto de 2 anos** com o Lio mais velho | ~1.000 | dezembro/janeiro |
| 6.4 | **Ato 4: Lys'Thaël** (nível 42–55) | Cidade élfica nas árvores, Pântano das Raízes e campos até a capital, Torre do Vigia Élfico, Velyra, revelação do Bram | ~850 | janeiro |
| 6.5 | **Ato 5: Altaréa e o final** (nível 55–65) | Capital, Castelo do Arauto, Cassian, Escadaria do Céu, Cidadela Celeste, **Vaelor em 3 fases**, final e créditos | ~1.050 | janeiro/fevereiro |
| 6.6 | **Pós-jogo** (nível 65–100) | Modo Infernal nas dungeons, conjuntos lendários com visual próprio no Lio, títulos e conquistas novas | ~250 | fevereiro |
| | **Total** | | **~4.400** | ~2 ciclos e meio do plano |

O GDD estimava ~4.000 para esta fase. A diferença vem do salto de 2 anos (Lio novo) e dos visuais dos conjuntos, que foram empurrados da Fase 5 para cá.

## Etapa 6.1 — Fechar o Ato 1 e abrir a estrada (plano detalhado)

### O caminho, como no GDD
`Pradoluz → Campos de Pradoluz → Floresta Sussurrante → (Mina e Celeiro) → Bosque seco → Estepe de pedra → Dunas de Ossos (Ato 2, fechado por enquanto)`

| Mapa | Níveis | Como é | Peças |
|---|---|---|---|
| **Campos de Pradoluz** (novo) | 1–3 | Plantações, cercas, feno, espantalhos e um sítio abandonado; os primeiros bandidos. A saída da vila passa a dar aqui, e daqui segue para a floresta | Já existem (vila) |
| Floresta Sussurrante | 3–8 | Como hoje (as zonas de nível 1 a 3 vão para os Campos) | Já existem |
| **Bosque seco** (novo) | 12–15 | Folhas amarelas, grama rala, árvores secas, acampamento de bandidos da estrada | Shader + ~4 peças novas |
| **Estepe de pedra** (novo) | 15–18 | Capim seco, pedras de arenito, arbustos secos, carroças quebradas, o deserto aparecendo no horizonte | ~4 peças novas |

- O Bosque seco só abre **depois do Gorvan** (fim do Ato 1), com a barreira dourada que já existe.
- No fim da Estepe fica o portal para as **Dunas de Ossos**, fechado com o aviso "Em breve" até o Ato 2.
- Cada mapa novo: bordas naturais (rio, paredão, cerca de pedras), pontos de descanso a cada trecho, minimapa, baús e drops.

### Código, sem créditos
- **Shader de bioma:** cada mapa diz quanto de "seco", "neve" e "musgo" aplicar nas peças (ex.: Bosque seco = 60% seco). Serve para os 16 campos da fase.
- **Cor do chão em degradê** entre os mapas de um trecho.
- **Portal "Em breve"** e barreira depois do Gorvan.
- **Missões secundárias de Pradoluz:** hoje são 2; o GDD pede 4 a 6. Mais 2 ou 3 curtas com NPCs que já existem (ex.: "a menina que esconde trigo para a avó", do GDD), com textos em português e inglês.
- **Robô de testes** passando pelos mapas novos, e fotos de cada mapa.

### O que gerar no Meshy
| Asset | Créditos |
|---|---|
| Árvore seca sem folhas, arbusto seco, capim alto seco, pedras de arenito (2 variações), carroça quebrada, tenda de acampamento, placa de estrada | ~8 peças × ~18 = ~145 |
| **Bandido da estrada** (nova textura do bandido + esqueleto + 4 animações) | ~30 |
| **Orc saqueador** (nova textura do orc + esqueleto + 4 animações) | ~30 |
| Margem para refazer (~20%) | ~45 |
| **Total 6.1** | **~250** |

Sobram ~580 dos 833 atuais. Com eles começo as **imagens de conceito do Ato 2** (Qaressa, Sahra, Severin, homem-lagarto; ~6 créditos cada) para você aprovar antes de o ciclo renovar. Assim dezembro já começa direto nos modelos 3D.

### Ordem
1. Código: shader de bioma, os 3 mapas montados com as peças que já existem (no lugar das novas), portais, missões e testes.
2. Meshy: imagens das 8 peças e dos 2 inimigos → você aprova → modelos 3D e animações.
3. Fotos dos mapas e versão nova no teste interno para você jogar.

## Riscos e cuidados
- **Tamanho do jogo:** hoje o arquivo para a Play Store tem ~276 MB. Com 4 cidades a mais, pode passar de 1 GB. A cada ato eu meço e aviso; se precisar, reduzo as texturas de 2K para 1K (hoje mantemos 2K por decisão sua) ou uso o envio de partes sob demanda do Google Play.
- **Espaço no GitHub:** o Git LFS já usa ~575 MB. Se faltar, a saída é o pacote de dados do GitHub ou a ferramenta `glb_shrink.gd` (já decidido em 11/11).
- **Testadores do Google Play:** cada versão nova enviada ao teste fechado passa por revisão; versões do dia a dia vão para o teste interno.
- **Música:** os sons gratuitos continuam provisórios. A troca pela ElevenLabs (plano pago) fica para a Fase 7, como decidido.

## Decisões que preciso de você
1. **Aprovar a etapa 6.1** como está (~250 créditos agora).
2. **Ordem dos mapas do Ato 1:** colocar os **Campos de Pradoluz entre a vila e a floresta**, como no GDD (recomendado), ou deixá-los como área extra numa saída nova da vila, sem mexer no caminho atual.
