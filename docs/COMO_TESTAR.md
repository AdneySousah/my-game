# Como testar o jogo

## No PC
- **Jogar:** dois cliques em `Jogar.bat`, na pasta do projeto.
- **Abrir no editor:** dois cliques em `Editor.bat`, depois aperte **F5** para rodar.

### Controles no PC
| Ação | Teclado | Controle (Xbox) |
|---|---|---|
| Andar | W A S D ou setas | Analógico esquerdo |
| Atacar (combo de 3 golpes) | J | X |
| Esquiva (rolamento, fica invulnerável) | Espaço | A |
| Correr (segurar; gasta fôlego) | Shift | Apertar o analógico esquerdo |
| Skills 1 a 4 | 1 2 3 4 (ou U I O P) | Y, B, LB, RB |
| Painel de atributos | C | Back |
| Painel de skills | K | — |
| Subir 1 nível (só para teste) | F1 | — |

Os botões de toque também aparecem no PC e funcionam com o mouse. Assim dá para sentir o layout do celular. O joystick funciona clicando e arrastando na parte de baixo, à esquerda.

## O que testar nesta versão (protótipo cinza)
Tudo ainda é forma simples. O amarelo é o Lio, o vermelho é o bandido e o roxo é o orc. Os modelos do Meshy entram na Fase 3.

1. **Sensação do combate:** o combo de 3 golpes é gostoso? Rápido ou lento demais?
2. **Esquiva:** quando aparece o círculo vermelho no chão, o inimigo vai atacar ali. Dá tempo de rolar para fora?
3. **Skills:** use **F1** até o nível 30 para liberar as 8. No painel **K**, troque quais ficam nos 4 botões.
   - Corte Giratório: dano em volta.
   - Investida: avança e atordoa (o inimigo fica amarelo).
   - Golpe Sísmico: lentidão (o inimigo fica azul).
   - Quebra-Guarda: o inimigo fica escuro e leva mais dano.
   - Brado de Guerra: você fica laranja e bate mais forte.
   - Onda de Corte: ataque à distância.
   - Salto Devastador: pula em cima dos inimigos.
   - Julgamento: golpe enorme em um alvo.
4. **Atributos:** no painel **C**, coloque pontos e veja a vida, o ataque e a defesa mudarem.
5. **Fôlego:** a barra verde-clara abaixo da vida. Esquiva, corrida e skills gastam; o ataque básico não. Sem fôlego o botão fica escuro e aparece "Sem fôlego!".
6. **Morte:** deixe os inimigos te derrotarem. Você perde 10% do ouro e 5% do XP do nível, volta no Ponto de descanso e fica com "Derrotado: −5%" por 5 minutos.

Anote o que achou: rápido, lento, fácil, difícil, confuso. Os números ficam todos em `data/` e são fáceis de ajustar.

## No celular (Android)
Precisa de uma configuração única no PC: o Android SDK, o Java 17 e os modelos de exportação do Godot. Quando você quiser testar no celular, eu preparo esse passo a passo.
