# ElevenLabs: passo a passo do dono

Isto é só o que você faz uma vez. Depois disso, eu gero tudo pelo script e te mando para ouvir.

## 1. Assinar o plano Creator
1. Entre em **elevenlabs.io** e faça login (ou crie a conta). A conta precisa estar **no seu nome**, porque o Creator é para uso individual.
2. Clique no seu nome/ícone (canto de baixo, à esquerda) → **Subscription** (Assinatura).
3. Escolha **Creator** (US$ 22/mês; o primeiro mês costuma sair mais barato) e pague.
4. Confira se aparece "Creator" e os **121.000 créditos**.

## 2. Criar a chave da API
1. No menu da esquerda, vá em **Developers** → **API Keys** (pode aparecer como "Desenvolvedores" → "Chaves de API").
2. Clique em **Create API Key** (Criar chave).
3. Nome: `Herdeiro dos Ceus - audio`.
4. Em **Restrict Key** / permissões, ligue **só** estas três:
   - **Sound Effects** (`sound_generation`): os efeitos;
   - **Music** (`music_generation`): as músicas;
   - **User** → **Read** (`user_read`): para o script ver quantos créditos sobram.
   Todo o resto fica desligado.
5. Se aparecer **Credit quota** (limite de créditos), coloque **100000**. Assim a chave nunca gasta mais do que isso.
6. Clique em **Create** e **copie a chave** (começa com `sk_`). Ela só aparece uma vez.

## 3. Salvar a chave no computador
1. Na pasta do projeto, abra `tools\audio\salvar_chave_elevenlabs.bat` (dois cliques).
2. Cole a chave (botão direito do mouse cola na janela preta) e aperte **Enter**.
3. A janela salva a chave em `Documentos\HerdeiroDosCeus_chave\elevenlabs.txt`, a mesma pasta da chave do Android, e já testa. Tem que aparecer algo como "Créditos usados neste mês: 0 de 121.000".

**Não cole a chave no chat nem em nenhum arquivo do projeto.** Se ela vazar, apague-a em API Keys e crie outra.

## 4. Me avise
É só dizer "chave salva". A partir daí:
1. Eu gero um primeiro lote pequeno (a música de Pradoluz, a de luta e alguns efeitos) para você ouvir e aprovar o estilo.
2. Com o estilo aprovado, gero o resto em lotes.
3. A cada lote, abre uma página `assets\_inbox\audio\ouvir.html` com todos os sons para ouvir no navegador. Você me diz qual versão de cada um fica (ex.: "vila 2").

## Comandos do script (para referência; eu é que rodo)
```
python -X utf8 tools/audio/eleven.py status
python -X utf8 tools/audio/eleven.py custo --all
python -X utf8 tools/audio/eleven.py gen vila luta_campo step_grass
python -X utf8 tools/audio/eleven.py aprovar vila 2
python -X utf8 tools/audio/eleven.py ouvir
```
- A lista de músicas e sons, com os textos pedidos ao ElevenLabs, está em `tools/audio/audio_list.json`.
- O que já foi gasto fica em `tools/audio/audio_log.json`.
- O plano completo do áudio está em `docs/AUDIO.md`.
