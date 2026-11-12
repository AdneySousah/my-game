# Publicação no Google Play — passo a passo do dono

Conta: pessoal, já com perfil de pagamentos. Pacote do jogo: **`com.adneysousah.herdeirodosceus`** (não muda nunca mais).

## Arquivos que eu entrego
- `build/android/herdeiro.aab` — o que vai para o Google Play.
- `build/android/herdeiro.apk` — instala direto no celular por cabo, sem passar pela loja (as compras não funcionam nele).

A chave de upload fica em `C:\Users\assantos\Documents\HerdeiroDosCeus_chave` (arquivo `upload.keystore` e a senha no `LEIA-ME_senha.txt`). **Guarde uma cópia dessa pasta** num pen drive ou no seu Google Drive. Ela nunca vai para o GitHub.

## 1. Criar o app (uma vez)
1. Página inicial do Play Console → **Criar app**.
2. Nome: **Herdeiro dos Céus** · Idioma padrão: **Português (Brasil)** · **Jogo** · **Gratuito**.
3. Marque as duas declarações (políticas e leis de exportação dos EUA) → **Criar app**.

## 2. Teste interno (você e quem você escolher, sem revisão do Google)
1. No menu do app: **Testar e lançar** → **Testes** → **Teste interno**.
2. Aba **Testadores** → **Criar lista de e-mails** → nome "Equipe" → coloque o seu e-mail Google (o do celular) → salvar e marcar a lista.
3. Aba **Versões** → **Criar nova versão**.
4. Se perguntar sobre **Assinatura de apps do Google Play**, aceite a opção padrão (o Google guarda a chave final; a nossa é só a de upload).
5. Envie o `herdeiro.aab` → nome da versão fica automático (0.1.0) → em notas escreva "Primeira versão de teste" → **Próxima** → **Salvar e publicar**.
6. De volta à aba **Testadores**, copie o **link de participação**, abra no celular, aceite e instale pelo Google Play. Pode levar alguns minutos para aparecer.

## 3. Produtos da loja especial (depois do passo 2, porque o Google só libera com uma versão enviada)
Menu do app: **Monetizar com o Google Play** → **Produtos** → **Produtos únicos** → **Criar produto único**. Para cada linha da tabela:
- **ID do produto**: exatamente como na tabela (não dá para mudar depois).
- **Nome** e **Descrição**: como na tabela.
- Crie a **opção de compra** (tipo "Comprar"), coloque o **preço em R$** e **ative** o produto.

| ID do produto | Nome | Descrição | Preço |
|---|---|---|---|
| `ouro_5000` | Saco de ouro | 5.000 de ouro. | R$ 4,90 |
| `ouro_30000` | Baú de ouro | 30.000 de ouro (20% a mais). | R$ 24,90 |
| `xp_boost_1h` | Pergaminho do saber | +50% de XP dos inimigos por 1 hora (o tempo corre mesmo com o jogo fechado). | R$ 3,90 |
| `kit_pocoes` | Kit de poções | 10 de vida média, 10 de fôlego médio e 3 tônicos. | R$ 4,90 |
| `trevo_real` | Trevo Real | O fortalecimento dá certo sempre. | R$ 6,90 |
| `broca_real` | Broca Real | Abre um encaixe sempre (até 3). | R$ 4,90 |
| `amuleto` | Amuleto de Proteção | Se o fortalecimento falhar, o equipamento não quebra nem some. | R$ 3,90 |

Se o Console pedir a versão em inglês, use: Bag of gold / Chest of gold / Scroll of learning / Potion kit / Royal Clover / Royal Drill / Protection Amulet.

## 4. Comprar de teste sem pagar
1. **Gerenciar conta** (fora do app) → **Teste de licença** → adicione o seu e-mail → resposta **RESPOND_NORMALLY** → salvar.
2. No celular, na hora de comprar, o Google mostra "Cartão de teste, sempre aprova". Nada é cobrado.

## Avisos amarelos normais no envio (não impedem nada)
- "Não há um arquivo de desofuscação": só serve para apps que usam R8/ProGuard; o jogo não usa.
- "Código nativo sem símbolos de depuração": os símbolos só deixam os relatórios de travamento mais detalhados. Ver na Fase 7 se o Godot oferece os símbolos do motor para enviar junto.

## 5. Ficha da loja, conteúdo do app e teste fechado
Tudo o que a ficha pede está em `docs/loja/`: textos em `ficha.md` (português e inglês), ícone, imagem de destaque, 6 fotos e a política de privacidade (`privacidade.html`). Os nomes dos menus podem variar um pouco no seu painel.

### 5.1 Publicar a política de privacidade (precisa de um endereço na internet)
1. Abra o Google Docs no computador e crie um documento em branco.
2. Abra `docs/loja/privacidade.html` no navegador (dois cliques), selecione tudo (Ctrl+A), copie e cole no documento.
3. No Docs: **Arquivo → Compartilhar → Publicar na Web → Publicar**. Copie o link que aparece: esse é o endereço da política.

### 5.2 Ficha da loja
**Crescer usuários → Presença na loja → Página principal da loja**: cole os textos de `ficha.md`, envie o ícone, a imagem de destaque e as 6 fotos (em **Capturas de tela do telefone**) e salve. Para o inglês: **Gerenciar traduções → Adicionar suas próprias traduções → Inglês (Estados Unidos)**, com `destaque_en.png`.

### 5.3 Conteúdo do app (menu **Política e programas → Conteúdo do app**)
- **Política de privacidade:** cole o link do passo 5.1.
- **Acesso ao app:** "Todas as funcionalidades estão disponíveis sem restrições de acesso" (não tem login).
- **Anúncios:** "Não, meu app não contém anúncios".
- **Classificação do conteúdo:** Iniciar questionário → seu e-mail → categoria **Jogo**. Respostas:
  - Violência: **Sim**, violência de fantasia com personagens de desenho (sem sangue, sem pessoas realistas).
  - Medo, sexo, linguagem imprópria, drogas, álcool e tabaco: **Não**.
  - Jogos de azar ou apostas simuladas: **Não**.
  - Usuários interagem entre si ou compartilham conteúdo: **Não**. Compartilha a localização: **Não**.
  - Compras digitais: **Sim**.
- **Público-alvo:** marque só **13 a 15, 16 a 17 e 18 ou mais**. Marcar menores de 13 coloca o jogo nas regras de apps para famílias, bem mais exigentes. Se perguntar se o app foi feito para crianças: **Não**.
- **Segurança dos dados:** "Seu app coleta ou compartilha algum dos tipos de dados de usuário exigidos?" → **Não**. O jogo não envia nada a lugar nenhum; o save fica no aparelho e o pagamento é feito pelo próprio Google Play. Depois **Salvar** e **Enviar**.
- **ID de publicidade:** "Seu app usa o ID de publicidade?" → **Não**.
- **Apps governamentais, recursos financeiros, saúde, notícias:** **Não** em todos.

### 5.4 Teste fechado (12 testadores por 14 dias seguidos)
1. **Testar e lançar → Testes → Teste fechado → Alpha → Gerenciar faixa**.
2. Aba **Testadores** → **Criar lista de e-mails** → nome "Testadores" → os e-mails Google das 12 pessoas (ou mais, por garantia) → salvar e marcar a lista.
3. Aba **Países/regiões** → **Brasil**.
4. Aba **Versões** → **Criar nova versão** → **Adicionar da biblioteca** → escolha a versão 3 (0.1.2) → notas "Teste fechado" → **Próxima** → **Salvar** → **Enviar para revisão**. O teste fechado passa pela revisão do Google (algumas horas ou dias).
5. Aprovado, copie o **link de participação** na aba Testadores e mande para as 12 pessoas. Cada uma abre o link no celular, aceita e instala pela Play Store. Elas precisam continuar inscritas por **14 dias seguidos**; abrir o jogo de vez em quando ajuda.
6. Depois dos 14 dias: **Painel → Solicitar acesso à produção** e responder às perguntas sobre o teste.

## 6. Antes de publicar de verdade (mais para frente)
- Teste fechado concluído (passo 5.4) e acesso à produção aprovado.
- Ícone do app no celular igual ao da loja (eu troco no jogo depois que você aprovar o ícone).
- Recebimentos: confirmar o depósito de teste do Google na conta do Itaú; inscrição na taxa de 15% (grupo de contas).

## Para mim (como gerar uma versão nova)
1. Aumentar `version/code` (e `version/name`) do preset Android em `export_presets.cfg`.
2. `bash tools/build/build_android.sh` (aab) e `bash tools/build/build_android.sh apk` (apk). Se outra sessão estiver com trabalho pela metade, gerar a partir de um `git worktree` limpo.
3. Imagens da loja: `--path . res://tests/store_art.tscn -- <pasta>` (ícone, destaque, ícones do app) e `--path . --fixed-fps 60 --resolution 1920x1080 res://tests/store_shots.tscn -- <pasta>` (fotos).
