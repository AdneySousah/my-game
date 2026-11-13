# Áudio do jogo (plano com o ElevenLabs)

Pedido do dono em 13/11/2026: trilhas que combinam com cada lugar, música que muda quando começa uma luta, sons de ambiente, de dano, de morte (diferentes por tipo de monstro), de passos e dos bichos. Tudo natural, sem poluição sonora.

## Plano e licença
- **Plano Creator** (US$ 22/mês, 121.000 créditos/mês, sobra acumula por até 2 meses).
- Música (Eleven Music) custa ~900 créditos por minuto. Efeito sonoro custa 200 créditos por geração.
- **Licença:** os termos de música liberam uso comercial em **jogos independentes** no Creator. Jogo independente é o que fatura menos de US$ 500 mil no total, de uma empresa/pessoa que fatura menos de US$ 1 milhão por ano com jogos. Os "Studio Games" (acima disso) precisam do plano Enterprise. Se passar do limite, há 60 dias para trocar de plano, e as cópias já distribuídas continuam valendo.
- O Creator é **para uso individual**: a conta tem que ser do dono, não de uma empresa.
- A chave da API fica **fora do projeto**, em `Documents/HerdeiroDosCeus_chave/elevenlabs.txt`. Nunca vai para o git.

## Como vai tocar (regras para não virar barulho)
- **Música por lugar:** cada mapa tem a sua (`map_music` em `data/audio/audio.json`). Na troca, uma passa para a outra aos poucos (crossfade).
- **Luta:** quando um monstro persegue o herói, a música do campo muda para a de luta, e volta uns 4 s depois que a luta acaba. Masmorras têm a sua própria música de ação, e chefes a deles.
- **Ambiente:** um som contínuo baixo por tipo de lugar (pássaros na floresta, vento na neve, insetos no pântano, gotas na mina, conversa na cidade). Sons soltos (pássaro cantando, sapo, peixe) tocam de vez em quando, perto do herói e com volume pela distância.
- **Limites:** no máximo 1 som de bicho a cada 4–6 s, e o mesmo efeito não repete em menos de 0,1 s. Passos baixos e com variação. A música abaixa um pouco nas falas e no som de morte.
- Canais: Música, Efeitos, Voz (já existem nas Opções).

## Músicas (≈ 22 faixas, ~1,5–2,5 min, em loop)
Todas com o mesmo "tema do herói" (uma melodia curta) em versões diferentes, para soar como um só jogo. Estilo: fantasia orquestral leve, com flauta, cordas, harpa e percussão suave. Em cada região entra um instrumento próprio.

| id | Onde | Clima |
|---|---|---|
| titulo | tela inicial | épico e esperançoso |
| prologo | prólogo/histórias | delicado, narrativo |
| vila | Pradoluz | calmo, alegre, flauta e violão |
| cidade_deserto | Qaressa | calmo, oud e percussão de mão |
| cidade_neve | Hrimvald | calmo, nórdico, sinos e cordas graves |
| cidade_elfica | Lysthael | etéreo, harpa e coro suave |
| capital | Altaréa | nobre, cordas e metais suaves |
| casa | dentro das casas | aconchegante, caixinha de música |
| campo_verde | Floresta, Campos, Estrada | aventura leve |
| campo_seco | Bosque Seco, Estepe, Ruínas por fora | aventura, ritmo seco |
| campo_deserto | Dunas, Deserto Rochoso | aventura, escala árabe |
| campo_neve | Planalto, Pinheiral, Picos, Vale | aventura fria, aberta |
| campo_pantano | Mata Úmida, Bordas, Pântano | misterioso |
| luta_campo | luta em área aberta | ação média, tambores |
| masmorra_mina | Mina, Mina de Gelo | ação tensa, metálica |
| masmorra_ruinas | Torre, Torre de Vigia, Topo | ação antiga, coro |
| masmorra_castelo | Castelo, Castelo do Arauto | ação pesada, órgão |
| ceu | Escadaria do Céu, Cidadela | celestial, intenso |
| chefe | chefes de masmorra | ação forte |
| arauto | formas verdadeiras dos Arautos e Vaelor | épico, coro |
| vitoria | depois de um chefe (curta) | fanfarra |
| derrota | morte do herói (curta) | triste, breve |

Créditos: ~22 × 2 min × 900 ≈ 40.000 (com refações, ~60.000).

## Efeitos (≈ 70)
- **Herói:**
  - passos em grama, pedra/madeira, areia e neve (2 variações cada);
  - golpe da espada (3);
  - dano recebido (2);
  - morte;
  - esquiva;
  - beber poção;
  - MP de volta;
  - subir de nível.
- **Acerto:** espada na carne, no metal e na pedra.
- **Monstros (dano e morte por tipo):**
  - humano (bandido, guarda);
  - orc;
  - esqueleto/morto (ossos);
  - golem (pedra);
  - homem-lagarto;
  - cultista;
  - celeste (luz quebrando);
  - slime/espírito;
  - grito dos chefes.
- **Bichos:**
  - pássaros (3 cantos);
  - cachorro feliz (carinho);
  - vaca mugindo (carinho);
  - gato (carinho);
  - sapo (2);
  - peixe pulando/água (2).
- **Ambiente (loops de 20–30 s):**
  - floresta;
  - campo com vento;
  - deserto;
  - neve/vento;
  - pântano;
  - mina/caverna;
  - cidade;
  - água corrente;
  - fogueira.
- **Mundo e interface:**
  - baú;
  - porta;
  - moedas;
  - pegar item;
  - missão concluída;
  - viagem;
  - cliques e abrir/fechar janela;
  - forja (martelo);
  - escudo quebrando.

Créditos: ~70 × 200 ≈ 14.000 (com refações, ~30.000).

**Total estimado: 60.000 a 90.000 créditos.** Cabe em um mês do Creator. O que não passar pela aprovação do dono é refeito no mês seguinte.

## Fluxo
1. `tools/audio/eleven.py` lê a lista (`tools/audio/audio_list.json`), gera pela API e salva em `assets/_inbox/audio/`.
2. O dono ouve e aprova.
3. Os aprovados vão para `assets/audio/` (música em mp3 com loop, efeitos em ogg) e entram no `audio.json`.
4. Os sons atuais de terceiros (CC-BY) saem do `docs/CREDITOS.md` à medida que forem trocados.

## Do plano anterior (11/11/2026)
- O sistema de som já existe: autoload `Audio` (`scripts/autoload/audio.gd`), lista em `data/audio/audio.json`, volumes de Música, Efeitos e Voz nas Opções. Os sons atuais são provisórios e gratuitos (créditos em `docs/CREDITOS.md`); os novos entram **com os mesmos ids** sempre que der, para não mexer no código.
- **"Fala" dos NPCs:** bipes curtos com tom próprio de cada personagem, tocados enquanto o texto aparece (feito no Godot, sem arquivo). O ElevenLabs pode fazer depois reações curtas ("hm!", "ah!", risada) por personagem.
- Bibliotecas gratuitas como complemento: Kenney.nl (CC0), Freesound/OpenGameArt (só CC0, ou CC-BY com crédito).
- Formatos: efeitos em OGG; músicas em mp3 com `loop=true` no `.import`.
