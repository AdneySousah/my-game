# Guia de estilo visual — versão 0.1

Todo asset do jogo segue este guia. Os prompts do Meshy ficam em inglês, porque o Meshy entende melhor.

## Direção
- **Low-poly estilo chibi**, com cores **vibrantes e saturadas** e textura simples "pintada à mão".
- **Leitura de cima:** a câmera é isométrica e fica longe, então silhuetas claras e cores fortes valem mais que detalhes pequenos.
- **Proporção dos personagens:** cerca de **3 cabeças de altura**, cabeça grande, olhos expressivos, mãos e pés um pouco maiores.
- **Humor visual:** expressões exageradas e poses claras.

## Texto base dos prompts

### Personagens (herói, NPCs, inimigos, chefes)
```
stylized chibi low-poly 3D game character, 3 heads tall, oversized head, big expressive eyes,
simple hand-painted texture, vibrant saturated colors, clean readable silhouette, soft cel-shaded look,
full body, A-pose, front view, empty hands, no weapon, no shield, no base, no background
```
- Personagem **sempre sem arma na mão**. As armas são modelos separados, presos à mão no Godot. Assim dá para trocar de arma e usar duas espadas.
- Asas, capas grandes e cabelos longos: deixar curtos e colados ao corpo, porque o rig automático pode deformá-los. As asas do Vaelor serão um modelo separado, animado por código.

### Armas
```
stylized low-poly 3D game weapon, single object, chunky proportions, simple hand-painted texture,
vibrant saturated colors, clean shapes, straight, no hand, no base, no background
```

### Objetos e peças de cenário
```
stylized low-poly 3D game prop, chunky proportions, simple hand-painted texture,
vibrant saturated colors, clean shapes, readable from a top-down isometric camera,
flat bottom, no base, no background
```
Peças modulares (muros, pisos, casas) recebem também: `modular game piece, straight edges, fits a 2 meter grid`.

### O que evitar (escrever no prompt quando o Meshy insistir)
`realistic, photorealistic, gritty, dark, highly detailed, thin parts, floating parts, text, logo`

## Paleta por região

| Região | Clima | Cores principais |
|---|---|---|
| Pradoluz | Fazenda ensolarada | Verde-grama `#7BC950`, trigo `#F2C14E`, telhado `#D9643A`, céu `#8FD3FF` |
| Qaressa | Deserto quente | Areia `#F4C27A`, terracota `#D9733F`, turquesa do oásis `#2EC4B6`, tecido `#9B5DE5` |
| Hrimvald | Fortaleza gelada | Neve `#EAF6FF`, gelo `#7FD1FF`, pedra azulada `#5C6F8A`, fogo `#FF8C42` |
| Lys'Thaël | Floresta élfica | Folha `#3DDC97`, casca `#8C5E3C`, flor `#FF7EB6`, luz `#FFF27A` |
| Altaréa | Capital | Mármore `#F5F0E6`, dourado `#E6B325`, azul real `#3A5BD9`, vermelho `#C8323C` |
| Cidadela Celeste | Céu | Branco `#FFFFFF`, ouro pálido `#FFE29A`, céu `#B8E1FF`. Na fase corrompida: roxo `#5B2A86` e preto `#1B1B2F` |

## Personagens principais (descrição para o prompt)

- **Lio (19 anos):** `teenage boy hero, short messy spiky golden-blond hair, amber eyes, cocky cheerful grin, ragged apprentice clothes: patched beige linen tunic, rope belt, brown cloth pants, worn leather boots, bandaged forearms`
- **Lio (21 anos, depois do salto):** mesmo rosto, um pouco mais alto, olhar mais firme, cicatriz pequena na bochecha.
- **Vaelor:** `tall godlike man, long white hair, white and gold robes with light armor, calm cold expression` (as asas e a lança são modelos separados).
- **Bento:** `chubby friendly young man, former cook, round face, small mustache, white cook shirt, brown apron, big backpack with pots`
- **Mestre Bram:** `old grumpy retired knight, eye patch, grey beard, worn leather and chainmail, sarcastic smirk`
- **Severin:** `serious young knight, neat dark hair, heavy dark-blue plate armor with gold trim, stern expression`
- **Marta:** `kind farmer mother, brown hair in a bun, simple green dress, apron`

## Imagem de referência
Antes de gerar qualquer modelo 3D, geramos a **arte de referência do Lio** e **1 imagem de clima por região** com a geração de imagens do Meshy. Elas viram a "verdade visual" do jogo. Custo estimado: 6 imagens × 6 créditos ≈ **36 créditos**. As imagens aprovadas ficam em `docs/design/referencias/`.

## Shader e iluminação no Godot
- **Shader estilo desenho (toon):** 2 a 3 faixas de luz, borda de luz suave (rim light) e cores sem perder a saturação.
- **Contorno** só nos personagens, por desempenho no celular.
- Luz do sol quente e sombras azuladas, para ficar alegre mesmo nas áreas escuras.
- Efeitos das skills: partículas simples, rastros de espada e brilho, nas cores da paleta.

## Limites técnicos (resumo do docs/MESHY.md)
- **Herói:** 8–10 mil triângulos. **Inimigo:** 4–6 mil. **Chefe:** até 12 mil. **Objeto:** 300–2 mil.
- Textura gerada em 2K e reduzida para 1K no celular.
- Formato GLB.
