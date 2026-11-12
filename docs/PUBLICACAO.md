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

## 5. Antes de publicar de verdade (mais para frente)
- Conta pessoal: teste fechado com **12 testadores por 14 dias seguidos** antes de pedir a produção (confirmar a regra no painel na hora).
- Ficha da loja: ícone 512×512, imagem de destaque 1024×500, fotos do jogo, descrição curta e completa (eu preparo).
- Conteúdo do app: política de privacidade (eu escrevo; o jogo é offline e não coleta dados), classificação etária, público-alvo, segurança dos dados, anúncios (não tem).
- Recebimentos: confirmar o depósito de teste do Google na conta do Itaú; inscrição na taxa de 15% (grupo de contas).

## Para mim (como gerar uma versão nova)
1. Aumentar `version/code` (e `version/name`) do preset Android em `export_presets.cfg`.
2. `bash tools/build/build_android.sh` (aab) e `bash tools/build/build_android.sh apk` (apk).
