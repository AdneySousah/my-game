# Decisões do projeto

Registro do que já foi decidido. Quando algo mudar, atualize aqui com a data.

## Jogo (11/11/2026)
- RPG de ação 3D low-poly, original, com história.
- Um único herói: guerreiro com 4 skills ativas, nível máximo 100.
- 4 cidades, com campos e dungeons para explorar.
- Totalmente offline. Só a compra com dinheiro real precisa de internet.
- Câmera de cima na diagonal (isométrica). No celular: joystick virtual, botão de ataque e 4 botões de skill. No PC: teclado e controle.

## Plataformas (11/11/2026)
- Android é a prioridade. Windows também, com a mesma base de código.

## Monetização (11/11/2026)
- Compras com dinheiro real pelo Google Play Billing (plugin oficial do Godot), como itens consumíveis:
  - pacotes de ouro;
  - pacotes de EXP;
  - pacotes de poções.
- Fantasias de evento (mudam o visual e dão atributos): ficam para o fim, podem sair com o jogo já publicado. O sistema de equipamentos já nasce com o espaço para elas.
- As compras são atalhos, não obrigação: o jogo inteiro precisa ser jogável sem pagar.
- No PC as compras ficam desligadas até decidirmos a loja (ex.: Steam).
- Sem servidor por enquanto. O save fica criptografado e com verificação de integridade.
- Conta de desenvolvedor do Google Play e perfil de pagamentos: já criados.

## Arte e assets (11/11/2026)
- Todos os assets 3D vêm do Meshy (plano Premium: 3.000 créditos/mês + 600 do Agent, 12 tentativas grátis por tarefa no site, API e MCP).
- Só personagens humanoides (rig automático do Meshy).
- Cenários com peças modulares; terreno feito no Godot.
- Animações da biblioteca do Meshy; as skills ganham força com efeitos visuais feitos no Godot.
- Visual uniforme: texto base de prompt fixo, imagem de referência, paleta de cores e shader estilo desenho.
- Geração aos poucos, fase por fase, com controle de créditos (`tools/meshy/ledger.py`).
- Herói e chefes: gerados preferencialmente no site (tentativas grátis). Inimigos comuns e objetos: pelo MCP.

## Ferramentas (11/11/2026)
- Godot 4.7.2 (versão padrão, GDScript) em `C:\Godot`.
- Repositório na conta pessoal do GitHub, envio por SSH, binários no Git LFS.

## Em aberto
- Nome do jogo (Fase 1).
- Data de renovação dos créditos do Meshy (o controle usa o dia 1 de cada mês até sabermos).
