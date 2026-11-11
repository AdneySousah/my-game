# Arte de referência — plano de geração

São 6 imagens geradas pelo Meshy (Text to Image) que viram a referência visual do jogo. As aprovadas ficam nesta pasta, como `<id>/<id>.png`.

| # | id | O que é | Modelo | Formato | Créditos |
|---|---|---|---|---|---|
| 1 | `ref_lio` | Lio de corpo inteiro, em A-pose, fundo transparente | `nano-banana-pro` (melhor qualidade) | 3:4 | 9 |
| 2 | `ref_pradoluz` | Clima da vila de fazenda | `nano-banana-2` | 16:9 | 6 |
| 3 | `ref_qaressa` | Clima da cidade no deserto | `nano-banana-2` | 16:9 | 6 |
| 4 | `ref_hrimvald` | Clima da fortaleza na neve | `nano-banana-2` | 16:9 | 6 |
| 5 | `ref_lysthael` | Clima da cidade élfica | `nano-banana-2` | 16:9 | 6 |
| 6 | `ref_altarea` | Clima da capital | `nano-banana-2` | 16:9 | 6 |
| | | | | **Total** | **39** |

**Bônus do `ref_lio`:** se aprovada, essa imagem pode ser usada direto para gerar o modelo 3D do Lio na Fase 3 (Image to 3D), sem pagar outra imagem.

Se alguma imagem não ficar boa, gerar de novo custa o mesmo valor. Antes de refazer, eu pergunto.

## Prompts

### 1. ref_lio
```
stylized chibi low-poly 3D game character concept, 3 heads tall, oversized head, big expressive amber eyes,
teenage boy hero, short messy spiky golden-blond hair, cocky cheerful grin,
ragged apprentice clothes: patched beige linen tunic, rope belt, brown cloth pants, worn leather boots, bandaged forearms,
simple hand-painted texture, vibrant saturated colors, clean readable silhouette, soft cel-shaded look,
full body, front view, empty hands, no weapon, no shield, plain background
```
Opções: `pose_mode: a-pose`, `remove_background: true`.

### 2. ref_pradoluz
```
isometric view of a cozy farming village in a stylized chibi low-poly game world, golden wheat fields,
small timber houses with orange-red roofs, wooden windmill, fences, a dirt road, lush green grass,
bright blue sky, warm sunny light, vibrant saturated colors (#7BC950 green, #F2C14E wheat, #D9643A roofs, #8FD3FF sky),
simple hand-painted textures, clean shapes, cheerful mood, video game environment concept art, no text
```

### 3. ref_qaressa
```
isometric view of a desert city around a turquoise oasis in a stylized chibi low-poly game world,
sand-colored clay buildings with domes, colorful purple and orange fabric awnings, palm trees, market stalls,
sealed stone wells, dunes in the background, hot bright sunlight,
vibrant saturated colors (#F4C27A sand, #D9733F terracotta, #2EC4B6 turquoise, #9B5DE5 fabric),
simple hand-painted textures, clean shapes, video game environment concept art, no text
```

### 4. ref_hrimvald
```
isometric view of a snowy mountain fortress town in a stylized chibi low-poly game world,
thick stone walls with bluish stone, wooden houses with snow-covered roofs, icicles, a few warm orange fires and torches,
pine trees, snowy peaks behind, cold clear light,
vibrant saturated colors (#EAF6FF snow, #7FD1FF ice, #5C6F8A stone, #FF8C42 fire),
simple hand-painted textures, clean shapes, video game environment concept art, no text
```

### 5. ref_lysthael
```
isometric view of an elven city built in and around giant trees in a stylized chibi low-poly game world,
wooden walkways and round treehouses, a huge mother tree in the center, pink flowers, glowing yellow lanterns,
part of the forest slightly withered and grey at the edges, soft magical light,
vibrant saturated colors (#3DDC97 leaves, #8C5E3C bark, #FF7EB6 flowers, #FFF27A light),
simple hand-painted textures, clean shapes, video game environment concept art, no text
```

### 6. ref_altarea
```
isometric view of a grand medieval capital city in a stylized chibi low-poly game world,
white marble buildings with gold trim, royal blue and red banners, a big central plaza, castle on a hill,
a long white stairway rising into the clouds in the distance, guards patrolling, bright daylight,
vibrant saturated colors (#F5F0E6 marble, #E6B325 gold, #3A5BD9 royal blue, #C8323C red),
simple hand-painted textures, clean shapes, video game environment concept art, no text
```
