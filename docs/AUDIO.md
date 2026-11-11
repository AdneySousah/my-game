# Plano de áudio

Pedido do dono em 11/11/2026. Entra na **Fase 4 (fatia vertical)**, quando o jogo ganha a primeira cidade de verdade. Até lá, o jogo segue sem som.

## O que vamos precisar
| Tipo | Exemplos | Quantidade aproximada |
|---|---|---|
| **Música** | Tema de Pradoluz, campo, dungeon, chefe, menu, vitória | 1 por cidade + campo + dungeon + chefe (~20 no jogo todo) |
| **Efeitos de combate** | Espada cortando o ar, golpe acertando, crítico, esquiva, morte | ~20 |
| **Efeitos das skills** | Um som para cada uma das 8 skills | 8 (+ variações) |
| **Passos** | Grama, terra, pedra, areia, neve, madeira | 6 superfícies × 3 variações |
| **Interface** | Clique, subir de nível, moeda, abrir painel, erro ("sem fôlego") | ~10 |
| **Ambiente** | Vento, pássaros, fogueira, água do oásis | 1 a 2 por região |
| **"Fala" dos NPCs** | Sons curtos de "conversa" enquanto o texto aparece | Ver abaixo |

## De onde tirar

### 1. ElevenLabs (IA com conector para o Claude) — recomendado
- Gera **efeitos sonoros** a partir de texto (ex.: "espada cortando o ar, curto, estilo desenho animado") e também **música** e **vozes**.
- Tem conector oficial. Quando chegarmos na Fase 4, eu gero e importo os sons direto, como faço com o Meshy.
- **Atenção:** o uso comercial (vender o jogo) exige um **plano pago** da ElevenLabs. No plano grátis, o uso é só não comercial. Na hora de assinar, confirme os termos atuais no site deles.

### 2. Bibliotecas gratuitas (complemento)
- **Kenney.nl:** pacotes de efeitos e interface em CC0 (livres, inclusive para uso comercial, sem precisar dar crédito).
- **Freesound.org / OpenGameArt.org:** muito material, mas cada arquivo tem a sua licença. Só usar os que forem **CC0**, ou **CC-BY** com crédito nos créditos do jogo.

### 3. "Fala" dos NPCs sem gastar nada
Como muitos jogos fazem, a "voz" dos NPCs pode ser feita **pelo próprio Godot**: bipes curtos com tom diferente para cada personagem, tocados a cada letra que aparece no diálogo. Não precisa de arquivo nem de crédito. Se quisermos algo mais rico, a ElevenLabs gera sons curtos de reação ("hm!", "ah!", risada) por personagem.

## Como vai ficar no projeto
- Pasta `assets/audio/music` e `assets/audio/sfx`, em formato **OGG** (leve para celular).
- Um controle central de áudio (autoload) com volumes separados para **música**, **efeitos** e **vozes**, na tela de opções.
- Registro de licença de cada som em `assets/audio/LICENCAS.md` (de onde veio e se pode uso comercial).

## Quando
- **Fase 4:** sistema de áudio, efeitos do combate e das 8 skills, passos na grama e na terra, interface, música de Pradoluz e da primeira dungeon, "fala" dos NPCs.
- **Fase 6:** música e ambiente das outras regiões, passos em areia e neve.
- **Fase 7:** mixagem final (volumes, música mudando entre exploração e combate).
