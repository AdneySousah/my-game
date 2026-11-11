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

## Meshy (11/11/2026)
- Os créditos mensais renovam todo **dia 4**. Saldo em 11/11: 3.269 (2.919 mensais + 350 permanentes).
- Modelos: personagens com `meshy-t2.5` + textura `meshy-n1`; objetos com `meshy-t2` + `meshy-n1`.
- Personagem animado ≈ 40 créditos (modelo 15 + rig 5 + ~5 animações × 3 + imagem conceito ~6).

## Design (11/11/2026, versão 0.1, aguardando aprovação)
- Fantasia medieval clássica, sem magia para o jogador, com ruínas antigas. Tom equilibrado e com humor. Visual chibi vibrante.
- 5 cidades: fazenda (terra natal), deserto, fortaleza na neve, cidade élfica, capital.
- O deus é o pai do herói. O final é aberto para continuação.
- Nível 100 em ~30 h; história termina perto do 65.
- 8 skills, 4 equipadas; pontos de atributo; fortalecimento até +20; gemas e até 3 encaixes; desmontagem no lugar da fusão; conjuntos de armadura, armas e acessórios.
- Missões diárias (5 por dia), calendário de login, títulos por conquistas, dificuldade escolhida no início, Modo Infernal nas dungeons.
- Pets e montarias: pós-lançamento.
- Documentos: [design/GDD.md](design/GDD.md) e [ESTILO.md](ESTILO.md).

## Design — respostas de 11/11/2026
- Teleporte em todas as cidades (volta para qualquer cidade já visitada) e pontos de descanso nas áreas de aventura e nas dungeons, que servem para teleporte e para voltar depois de morrer.
- As 8 skills são liberadas até o nível 30: níveis 1, 4, 8, 12, 16, 20, 25 e 30.
- Trevo de Fortificação e Broca de Engaste em duas versões: comum (ouro/login/drops, chance de falhar nos níveis altos; Trevo comum 100% até +11, 75% no +12...) e Real (dinheiro real, 100% de sucesso).
- Penalidade "Derrotado": −5% em todos os atributos por 5 minutos.

## Em aberto
- As decisões pendentes no fim do [GDD](design/GDD.md).
