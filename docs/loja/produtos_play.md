# Produtos da loja (Google Play Console)

Cadastre cada produto em **Monetizar → Produtos → Produtos no app** com o **ID exatamente igual** ao da tabela. O nome e a descrição abaixo são os textos que o jogo mostra; use os mesmos no Play Console. Todos são do tipo **gerenciado (consumível)**: o jogo entrega e consome a compra.

O arquivo do jogo (`data/shop/store.json`) guarda só chaves de tradução (`STORE_...`); os textos reais ficam em `data/i18n/strings.csv`. Esta lista foi montada a partir deles em 12/11/2026.

| ID | Nome | Descrição | Preço |
|---|---|---|---|
| `premium_7d_oferta` | Oferta de boas-vindas: passe premium 7 dias | Só na primeira compra! Experiência em dobro, ouro em dobro e +10% em todos os atributos por 7 dias. | R$ 4,99 |
| `premium_7d` | Passe premium — 7 dias | Experiência em dobro, ouro dos inimigos e baús em dobro e +10% em todos os atributos. Comprar de novo soma os dias. | R$ 15,00 |
| `premium_14d` | Passe premium — 14 dias | Experiência em dobro, ouro dos inimigos e baús em dobro e +10% em todos os atributos. Comprar de novo soma os dias. | R$ 20,00 |
| `premium_30d` | Passe premium — 30 dias | Experiência em dobro, ouro dos inimigos e baús em dobro e +10% em todos os atributos. Comprar de novo soma os dias. | R$ 25,00 |
| `skin_sol` | Visual: Cavaleiro do Sol | Armadura branca e dourada, cabelo novo e a Lâmina Solar. Só muda a aparência; fica guardado para sempre. | R$ 9,90 |
| `skin_tempestade` | Visual: Lâmina da Tempestade | Couro azul com raios, cabelo prateado e a Lâmina da Tempestade. Só muda a aparência; fica guardado para sempre. | R$ 9,90 |
| `skin_anjo` | Visual: Anjo Dourado | Armadura dourada que brilha, asas que batem de verdade e o Lio flutuando no lugar de andar. Só muda a aparência; fica guardado para sempre. | R$ 19,90 |
| `ouro_5000` | Saco de ouro | 5.000 de ouro. | R$ 4,90 |
| `ouro_30000` | Baú de ouro | 30.000 de ouro (20% a mais). | R$ 24,90 |
| `xp_boost_1h` | Pergaminho do saber | +50% de XP dos inimigos por 1 hora (o tempo corre mesmo com o jogo fechado). | R$ 3,90 |
| `kit_pocoes` | Kit de poções | 10 de vida média, 10 de fôlego médio e 3 tônicos. | R$ 4,90 |
| `trevo_real` | Trevo Real | O fortalecimento dá certo sempre. | R$ 6,90 |
| `broca_real` | Broca Real | Abre um encaixe sempre (até 3). | R$ 4,90 |
| `amuleto` | Amuleto de Proteção | Se o fortalecimento falhar, o equipamento não quebra nem some. | R$ 3,90 |
| `mochila_30` | Mochila Real (+30 espaços) | Uma mochila grande que aumenta a mochila do herói em 30 espaços. Dá para vestir até 6 mochilas. | R$ 1,99 |
| `licenca_covil_10` | 10 Licenças do Covil | Mais 10 entradas nos covis do Ferreiro Andarilho, além das 10 grátis de cada dia. | R$ 3,99 |

## Oferta de boas-vindas (`premium_7d_oferta`)
- É um produto separado do `premium_7d`, com o mesmo efeito (7 dias de premium) e preço de R$ 4,99.
- O jogo só mostra essa oferta para quem **nunca comprou nada**: some depois da primeira compra de qualquer produto.
- Ao abrir o jogo pela tela inicial aparece um banner com a oferta ("Quero!" compra, "Agora não" fecha). Ela também fica no topo da loja especial enquanto valer.
- No Play Console, basta cadastrar o produto com esse preço. Não é preciso criar uma "promoção", porque o próprio jogo controla quem pode comprar.

## Visuais (skins)
Hoje o jogo tem **3 visuais**, todos na lista acima: `skin_sol` (Cavaleiro do Sol), `skin_tempestade` (Lâmina da Tempestade) e `skin_anjo` (Anjo Dourado, adicionado em 13/11). Eles aparecem na loja especial (botão do topo da tela) com o botão de preço. Depois de comprados, são trocados no encaixe "Visual" da tela de equipamentos, que lista os visuais comprados e "Sem visual"; o retrato do Lio muda junto.

## Mochila Real (`mochila_30`)
Produto consumível novo (13/11): cada compra dá 1 Mochila Real (+30 espaços). Dá para vestir até 6 mochilas. A Mochila de Couro (+10) é vendida por ouro nos comerciantes e não entra no Play Console.

## Licenças do Covil (`licenca_covil_10`)
Produto consumível novo (13/11, Fase 8B): cada compra dá 10 Licenças do Covil. Os covis do Ferreiro Andarilho abrem segunda, quarta, sexta e domingo, com 10 entradas grátis por dia. Depois delas, cada entrada gasta 1 licença.
