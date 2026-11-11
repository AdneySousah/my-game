# CLAUDE.md — regras do projeto

RPG de ação 3D low-poly, offline, feito em Godot 4.7 com GDScript. Um único herói guerreiro, 4 skills, nível máximo 100, 4 cidades, campos e dungeons. Foco em Android, com versão para Windows. O jogo é original: pode se inspirar na pegada dos ARPGs mobile, mas não copia nomes, história, personagens ou arte de nenhum jogo.

O dono do projeto não programa nem modela. Toda a parte de código, dados e geração de assets é nossa. Ele aprova o visual, testa o jogo e cuida da loja do Google Play.

Leia também: [docs/DECISOES.md](docs/DECISOES.md) (o que já foi decidido), [docs/ROADMAP.md](docs/ROADMAP.md) (fases) e [docs/MESHY.md](docs/MESHY.md) (como gerar assets).

## Ferramentas
- Godot: `C:\Godot\Godot_v4.7.2-stable_win64.exe` (editor) e `C:\Godot\Godot_v4.7.2-stable_win64_console.exe` (linha de comando).
- Importar/checar o projeto: `"/c/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --import`
- Rodar a cena inicial e sair: `"/c/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --quit-after 5`
- Créditos e status dos assets: `python tools/meshy/ledger.py report`
- **Testes (rodar antes de todo commit de código):** `"/c/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --fixed-fps 60 res://tests/test_runner.tscn` → precisa terminar com `TESTS_RESULT=PASS`. Inclui um robô que joga a arena por 75 s usando as 8 skills.
- **Fotos do jogo rodando (abre uma janela):** `"/c/Godot/Godot_v4.7.2-stable_win64_console.exe" --path . --fixed-fps 60 --resolution 1280x720 res://tests/capture.tscn -- <pasta de saída>`. Usar uma pasta nova a cada vez, porque os arquivos são sobrescritos.
- Tabela de XP: editar as constantes em `tools/balance/gen_xp.py` e rodar `python -X utf8 tools/balance/gen_xp.py` (nunca editar `xp_table.json` à mão).
- Textos do jogo: adicionar a chave em `data/i18n/strings.csv` (colunas `keys,pt_BR,en`) e usar `tr("CHAVE")`. Em textos que passam por `%`, escrever `%%` para mostrar o símbolo de porcentagem.
- Para o dono testar: `Jogar.bat` (abre o jogo) e `Editor.bat` (abre o editor).
- **Ferramentas para assets do Meshy (todas abrem com `--path .`):**
  - `res://tests/model_preview.tscn -- <a.glb> <out.png>`: modelo de 4 ângulos (precisa de janela).
  - `res://tests/lineup.tscn -- <out.png> <a.glb> ...`: vários modelos lado a lado em tamanho real.
  - `res://tests/character_preview.tscn -- <id> <out.png> [rx,ry,rz] [ação:tempo ...]`: personagem do jogo em ações; o 3º argumento testa ângulos da arma.
  - `--headless --script res://tests/anim_analyze.gd -- <rigged.glb> <anims.glb>`: momento dos golpes (picos da mão) e deslocamento do quadril de cada animação.
  - `--headless --script res://tests/inspect_glb.gd -- <a.glb> ...`: animações, ossos e malhas.
- **Mapas:** cada mapa é um JSON em `data/maps/` (chão, trilhas, paredes, peças, espalhamento, pontos de descanso, saídas, zonas de inimigos). Fotos dos mapas (vista aérea + pontos de jogo): `--path . --resolution 1280x720 res://tests/map_tour.tscn -- <pasta> [mapa ...]`.
- **Interface:** o tema vem de `GameTheme` (texturas em `assets/ui`, feitas a partir das imagens do Meshy com `--headless --script res://scripts/tools/ui_prepare.gd`). Botões, painéis e barras usam o tema automaticamente; não colocar `StyleBoxFlat` por cima. Texturas usadas em `_draw()` precisam ser carregadas antes (em `_ready`) com `GameTheme.tex()`: carregadas pela primeira vez dentro do desenho, aparecem como um quadrado branco.
- O jogo roda em `scenes/main/main.tscn` (`Main`): herói, câmera e HUD ficam; os mapas trocam. Progresso do mundo em `Session` (autoload).
- Na exportação (Fase 7), incluir `*.json` no filtro de arquivos, porque `data/` é lido com `FileAccess`.

## Git
- Os commits vão para a conta **pessoal** do GitHub (AdneySousah). O nome, o e-mail e a chave SSH estão fixados no `.git/config` local. Nunca altere isso e nunca use a configuração global.
- Envio sempre por SSH (remote `git@github.com:...`), nunca HTTPS (a senha salva no Windows pode ser de outra conta).
- Arquivos binários (glb, png, ogg...) vão pelo Git LFS (`.gitattributes`).
- Nunca commitar keystore, `.env` ou chaves de API.

## Código
- GDScript com tipagem estática em tudo (`var x: int`, `func f() -> void`). O projeto avisa quando falta tipo.
- Nomes de código em inglês; textos para o jogador sempre via chave de tradução (`tr("KEY")`), com o português em `data/i18n/` como idioma base.
- Conteúdo (itens, inimigos, skills, quests, diálogos, curva de XP, loja) fica em `data/` como `Resource` (`.tres`) ou JSON, nunca fixo no código. Isso permite criar e balancear conteúdo em volume.
- Cenas pequenas e compostas. Um script por responsabilidade.
- Autoloads só para estado realmente global (`Game`, e depois save, áudio, loja).
- Toda compra com dinheiro real passa por uma camada `Store` com implementação por plataforma (Google Play no Android; desligada no PC por enquanto).
- O save é local, criptografado e com verificação de integridade.

## Pastas
- `assets/` — modelos, texturas, sons, shaders. Cada asset do Meshy em `assets/<categoria>/<id>/`.
- `assets/_inbox/` — downloads crus do Meshy esperando aprovação. O Godot ignora esta pasta e o git também.
- `scenes/` — cenas `.tscn`. `scripts/` — código. `data/` — conteúdo do jogo. `tests/` — testes.
- `tools/` — scripts de apoio (o Godot ignora). `docs/` — documentação (o Godot ignora).

## Arte (resumo; detalhes em docs/MESHY.md)
- Low-poly com textura estilizada, unificado por um shader estilo desenho e uma paleta fixa.
- Todo personagem que anima é **humanoide** (o rig automático do Meshy só aceita humanoides). Sem quadrúpedes, dragões ou criaturas sem forma humana com esqueleto. Criaturas sem esqueleto (slime, espírito) são animadas por código.
- Cenários são montados com peças modulares do Meshy; o terreno é feito no Godot.
- Antes de gastar créditos do Meshy, rodar `python tools/meshy/ledger.py can-spend <créditos>` e registrar o gasto depois. Gerar aos poucos, só o que a fase atual precisa.
- Nenhum asset entra em `assets/` sem o dono aprovar o visual.
