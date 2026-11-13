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
| `ouro_5000` | Saco de ouro | 5.000 de ouro. | R$ 4,90 |
| `ouro_30000` | Baú de ouro | 30.000 de ouro (20% a mais). | R$ 24,90 |
| `xp_boost_1h` | Pergaminho do saber | +50% de XP dos inimigos por 1 hora (o tempo corre mesmo com o jogo fechado). | R$ 3,90 |
| `kit_pocoes` | Kit de poções | 10 de vida média, 10 de fôlego médio e 3 tônicos. | R$ 4,90 |
| `trevo_real` | Trevo Real | O fortalecimento dá certo sempre. | R$ 6,90 |
| `broca_real` | Broca Real | Abre um encaixe sempre (até 3). | R$ 4,90 |
| `amuleto` | Amuleto de Proteção | Se o fortalecimento falhar, o equipamento não quebra nem some. | R$ 3,90 |

## Oferta de boas-vindas (`premium_7d_oferta`)
- É um produto separado do `premium_7d`, com o mesmo efeito (7 dias de premium) e preço de R$ 4,99.
- O jogo só mostra essa oferta para quem **nunca comprou nada**: some depois da primeira compra de qualquer produto.
- Ao abrir o jogo pela tela inicial aparece um banner com a oferta ("Quero!" compra, "Agora não" fecha). Ela também fica no topo da loja especial enquanto valer.
- No Play Console, basta cadastrar o produto com esse preço. Não é preciso criar uma "promoção", porque o próprio jogo controla quem pode comprar.

## Visuais (skins)
Hoje o jogo tem **2 visuais**, e os dois já estão na lista acima: `skin_sol` (Cavaleiro do Sol) e `skin_tempestade` (Lâmina da Tempestade). Eles aparecem na loja especial (botão do topo da tela) com o botão de preço; depois de comprados, viram "Vestir/Tirar".
