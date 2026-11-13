"""Gera data/dialogues/act1.json e as chaves de texto do Ato 1 em data/i18n/strings.csv.

O texto dos diálogos fica aqui (pt_BR e en lado a lado). Para mudar uma fala, edite
este arquivo e rode:  python -X utf8 tools/content/gen_act1_text.py
As chaves geradas começam com DLG_, BARK_, NPC_, QUEST_, OBJ_, ITEM_, PRO_ e TITLE_; as outras
linhas do strings.csv não são tocadas.
"""
import csv
import io
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# speaker, pt_BR, en
DIALOGUES = {
    # --- Missão 1: Mais um dia em Pradoluz ---
    "main_01_marta": [
        ("marta", "Lio! O sol já está alto e você ainda com cara de travesseiro.", "Lio! The sun is up and you still look like a pillow."),
        ("lio", "Bom dia, mãe. Sonhei que eu era o herói mais forte do mundo.", "Morning, Mom. I dreamed I was the strongest hero in the world."),
        ("marta", "Pois o herói mais forte do mundo está atrasado para o treino. O Bram já passou aqui resmungando.", "Well, the strongest hero in the world is late for training. Bram already came by, grumbling."),
        ("lio", "Ele resmunga até dormindo.", "He grumbles in his sleep."),
        ("marta", "Vai logo. E não quebre nada... de novo.", "Go on. And don't break anything... again."),
    ],
    "main_01_bram": [
        ("bram", "Atrasado. Um olho só e eu ainda te vi chegando de longe, arrastando os pés.", "Late. One eye and I still saw you coming a mile away, dragging your feet."),
        ("lio", "Eu estava aquecendo. Andar devagar é um aquecimento avançado.", "I was warming up. Walking slowly is an advanced warm-up."),
        ("bram", "Hmpf. A vila está passando fome por causa do tributo do Gorvan, e você fazendo piada.", "Hmph. The village is starving because of Gorvan's tribute, and you're making jokes."),
        ("bram", "Ataque com o botão grande. Role para fugir dos golpes. E fique de olho no fôlego.", "Attack with the big button. Roll to dodge blows. And keep an eye on your stamina."),
        ("lio", "Atacar, rolar, respirar. Anotado, mestre.", "Attack, roll, breathe. Noted, master."),
    ],
    # --- Missão 2: A lição do caolho ---
    "main_02_offer": [
        ("bram", "Treinar com espantalho não ensina nada. Bandidos estão assaltando as carroças na Floresta Sussurrante.", "Training with scarecrows teaches nothing. Bandits are robbing the carts in the Whispering Forest."),
        ("lio", "Bandidos de verdade? Finalmente uma aula interessante!", "Real bandits? Finally an interesting lesson!"),
        ("bram", "Derrube quatro deles e volte inteiro. Inteiro, ouviu? Sua mãe me mata.", "Take down four of them and come back in one piece. One piece, you hear? Your mother would kill me."),
    ],
    "main_02_done": [
        ("lio", "Quatro bandidos, nenhum arranhão. Bom, quase nenhum.", "Four bandits, not a scratch. Well, almost none."),
        ("bram", "Não foi ruim. Mas você abaixa a guarda depois de cada golpe. Um dia isso vai te custar caro.", "Not bad. But you drop your guard after every swing. One day that'll cost you."),
        ("lio", "Um dia. Hoje não!", "One day. Not today!"),
    ],
    # --- Missão 3: Um cozinheiro na floresta ---
    "main_03_offer": [
        ("bram", "Um caçador viu um sujeito gordinho escondido na clareira da floresta, gritando por socorro.", "A hunter saw a chubby fellow hiding in the forest clearing, yelling for help."),
        ("bram", "Diz que veio da capital. Gente da capital sabe das coisas do Gorvan. Traga ele aqui.", "Says he came from the capital. Capital folk know things about Gorvan. Bring him here."),
        ("lio", "Resgate de gordinho na floresta. Deixa comigo.", "Rescuing a chubby guy in the forest. Leave it to me."),
    ],
    "main_03_bento_meet": [
        ("bento", "Não me come! Eu sou só pele, osso e... bom, um pouco de banha!", "Don't eat me! I'm just skin, bones and... well, a little lard!"),
        ("lio", "Calma! Eu não como gente. Sou o Lio, de Pradoluz.", "Easy! I don't eat people. I'm Lio, from Pradoluz."),
        ("bento", "Bento, ex-cozinheiro da cozinha real. Ex, porque queimei o pudim do Arauto. Longa história.", "Bento, former cook of the royal kitchen. Former, because I burned the Herald's pudding. Long story."),
        ("bento", "Tem dois orcs rondando a clareira. Eles sentiram o cheiro do meu sanduíche!", "There are two orcs prowling the clearing. They smelled my sandwich!"),
        ("lio", "Fica aqui. E guarda esse sanduíche.", "Stay here. And hide that sandwich."),
    ],
    "main_03_bento_join": [
        ("bento", "Você derrubou os dois! Com uma espada que parece uma colher de pau!", "You took them both down! With a sword that looks like a wooden spoon!"),
        ("lio", "É uma espada de aprendiz. Ela tem potencial.", "It's an apprentice sword. It has potential."),
        ("bento", "Eu ouvi coisas na capital. Sobre o tributo, sobre o Gorvan. Me leva para a sua vila e eu conto tudo.", "I heard things in the capital. About the tribute, about Gorvan. Take me to your village and I'll tell you everything."),
        ("bento", "E eu cozinho! Sou medroso, mas cozinho muito bem.", "And I cook! I'm a coward, but I cook really well."),
        ("lio", "Fechado, sócio. Minha mãe vai adorar mais uma boca... talvez.", "Deal, partner. My mom will love another mouth to feed... maybe."),
    ],
    "main_03_marta": [
        ("marta", "Lio, quem é esse moço?", "Lio, who is this young man?"),
        ("lio", "Bento, meu sócio. Ele cozinha.", "Bento, my partner. He cooks."),
        ("marta", "Cozinhar o quê, filho? O Gorvan levou quase tudo. Sobrou farinha e saudade.", "Cook what, son? Gorvan took nearly everything. All that's left is flour and longing."),
        ("bento", "Senhora, com farinha e saudade eu faço um pão que faz chorar. No bom sentido.", "Ma'am, with flour and longing I make bread that'll make you cry. In a good way."),
        ("marta", "Hm. Fica. Mas lava a louça.", "Hm. Stay. But you wash the dishes."),
    ],
    # --- Missão 4: Os corvos da mina ---
    "main_04_offer": [
        ("bento", "Lio, aquilo que eu ouvi na capital: as carroças do tributo não vão para o castelo.", "Lio, about what I heard in the capital: the tribute carts don't go to the castle."),
        ("bento", "Elas somem na Mina dos Corvos, ao norte da floresta. A comida da sua vila está lá dentro!", "They vanish into the Crow Mine, north of the forest. Your village's food is in there!"),
        ("lio", "Então é para lá que a gente vai.", "Then that's where we're going."),
        ("bento", "A gente? Eu... eu fico guardando a vila. Alguém precisa. Fala com o Bram antes, tá?", "We? I... I'll guard the village. Someone has to. Talk to Bram first, okay?"),
    ],
    "main_04_bram": [
        ("bram", "A Mina dos Corvos... fechou há anos. Se o Gorvan esconde comida lá, deve ter gente armada vigiando.", "The Crow Mine... it closed years ago. If Gorvan hides food there, there'll be armed men guarding it."),
        ("bram", "Siga a trilha da floresta para o norte. Descanse nas fogueiras. E não entre sem fôlego.", "Follow the forest trail north. Rest at the campfires. And don't go in out of breath."),
        ("lio", "Relaxa, mestre. Eu volto antes do jantar do Bento.", "Relax, master. I'll be back before Bento's dinner."),
        ("bram", "É disso que eu tenho medo.", "That's what I'm afraid of."),
    ],
    # --- Missão 5: O Arauto da Colheita ---
    "gorvan_intro": [
        ("gorvan", "Ora, ora! Um ratinho de Pradoluz no meu celeiro. Veio catar as migalhas?", "Well, well! A little Pradoluz mouse in my granary. Came for the crumbs?"),
        ("lio", "Vim buscar a comida da minha vila. Toda. Pode embrulhar pra viagem?", "I came for my village's food. All of it. Could you wrap it to go?"),
        ("gorvan", "Hohoho! O tributo pertence ao Soberano Alado. E quem mexe no que é do céu... vira adubo!", "Hohoho! The tribute belongs to the Winged Sovereign. And whoever touches what is heaven's... becomes fertilizer!"),
    ],
    "gorvan_transform": [
        ("gorvan", "Chega de brincadeira! Vamos ver se você corta palha tão bem quanto corta piada!", "Enough games! Let's see if you cut straw as well as you crack jokes!"),
        ("gorvan", "Levanta, colheita! Teu senhor tem fome!", "Rise, harvest! Your master is hungry!"),
    ],
    "gorvan_reborn": [
        ("lio", "Ele virou um espantalho gigante?! Isso não estava no treino do Bram!", "He turned into a giant scarecrow?! That was not in Bram's training!"),
        ("lio", "Esse brilho dourado é um escudo... e o trigo que brotou cura ele. Primeiro quebro o escudo, e corto o trigo antes que ele chegue lá!", "That golden glow is a shield... and the wheat that sprouted heals him. Break the shield first, and cut the wheat before he gets to it!"),
    ],
    "main_05_marta": [
        ("marta", "Lio! As carroças voltaram cheias! A vila inteira está na praça!", "Lio! The carts came back full! The whole village is in the square!"),
        ("lio", "Eu disse que voltava antes do jantar. Bom... de algum jantar.", "I said I'd be back before dinner. Well... some dinner."),
        ("marta", "Todo arranhado... e eu nunca tive tanto orgulho de você. Vem, hoje tem pão de verdade.", "All scratched up... and I've never been so proud of you. Come, there's real bread today."),
    ],
    # --- Missão 6: Mais cinco desses (fim do Ato 1) ---
    "act1_end_bram": [
        ("bram", "Gorvan era só um dos cinco Arautos. Os outros fazem o mesmo nas cidades deles.", "Gorvan was only one of the five Heralds. The others do the same in their cities."),
        ("lio", "Então tem gente passando fome lá também. Ou sede. Ou frio.", "So people are starving there too. Or thirsty. Or freezing."),
        ("bram", "O mundo é grande, moleque. E cruel. Não é lugar pra quem só sabe fazer piada.", "The world is big, kid. And cruel. It's no place for someone who only knows how to joke."),
        ("lio", "Então eu levo a espada também.", "Then I'll bring the sword too."),
    ],
    "act1_end_bento": [
        ("bento", "Você vai embora, né? Dá pra ver na sua cara de herói.", "You're leaving, aren't you? I can see it on your hero face."),
        ("lio", "Se tem mais cinco desses, alguém precisa dar um jeito.", "If there are five more like him, someone has to deal with them."),
        ("bento", "Então eu vou junto! Alguém tem que cozinhar pro herói. E correr na frente... quer dizer, atrás dele.", "Then I'm coming! Someone has to cook for the hero. And run ahead... I mean, behind him."),
        ("lio", "Sócio é sócio.", "Partners are partners."),
    ],
    # --- Secundária: Trigo escondido ---
    "side_trigo_offer": [
        ("nina", "Psiu! Você não viu nada. Esse trigo não é do tributo, tá? É da minha vó.", "Psst! You didn't see anything. This wheat isn't for the tribute, okay? It's my grandma's."),
        ("lio", "Segredo guardado. Sua vó está bem?", "Secret's safe. Is your grandma all right?"),
        ("nina", "Ela tosse muito. O curandeiro disse que a erva-de-orvalho ajuda, mas ela só cresce na floresta.", "She coughs a lot. The healer said dewleaf helps, but it only grows in the forest."),
        ("lio", "Erva-de-orvalho. Quantas?", "Dewleaf. How many?"),
        ("nina", "Três! As folhas brilham um pouquinho, igual sereno de manhã.", "Three! The leaves glow a little, like morning dew."),
    ],
    "side_trigo_done": [
        ("lio", "Três ervas-de-orvalho, fresquinhas. Brilhando e tudo.", "Three dewleaves, fresh. Glowing and everything."),
        ("nina", "Você conseguiu! A vó vai fazer chá e parar de tossir!", "You did it! Grandma will make tea and stop coughing!"),
        ("nina", "Toma, é tudo o que eu juntei. E quando o trigo crescer, o primeiro pão é seu!", "Here, it's all I saved. And when the wheat grows, the first loaf is yours!"),
    ],
    # --- Secundária: O ferro do Tobias ---
    "side_ferro_offer": [
        ("tobias", "L-l-lio! Os orcs... eles levaram o meu c-c-caixote de ferro da carroça!", "L-l-lio! The orcs... they took my c-c-crate of iron from the cart!"),
        ("lio", "Respira, Tobias. Onde foi isso?", "Breathe, Tobias. Where was that?"),
        ("tobias", "Na trilha do norte da f-floresta. Sem f-ferro eu não conserto as enxadas da vila.", "On the north trail of the f-forest. Without i-iron I can't fix the village's hoes."),
        ("lio", "Orcs ladrões de ferro. Vou trazer o seu caixote. E uns orcs a menos.", "Iron-stealing orcs. I'll bring your crate back. And a few fewer orcs."),
    ],
    "side_ferro_done": [
        ("lio", "Um caixote de ferro, entregue em mãos. Pesado, hein?", "One crate of iron, hand-delivered. Heavy, huh?"),
        ("tobias", "O-obrigado! Quando eu voltar a f-forjar, a sua espada vai ser a p-primeira da fila.", "Th-thank you! When I'm back at the f-forge, your sword will be f-first in line."),
        ("lio", "Nada de colher de pau, então!", "No more wooden spoon, then!"),
    ],
    # --- Secundária: O sítio do Juca (Campos de Pradoluz) ---
    "side_juca_offer": [
        ("juca", "No meu tempo, o sítio do leste, lá nos Campos, era o mais bonito de Pradoluz. Hoje é ninho de bandido.", "Back in my day, the east farm out in the Fields was the prettiest in Pradoluz. Now it's a bandit nest."),
        ("lio", "O sítio da carroça velha, perto dos fenos?", "The one with the old cart, by the haystacks?"),
        ("juca", "Esse mesmo. E levaram a minha ferradura da sorte. Sessenta anos pendurada na porta!", "That's the one. And they took my lucky horseshoe. Sixty years hanging on the door!"),
        ("lio", "Bandidos fora, ferradura de volta. Pode deixar, seu Juca.", "Bandits out, horseshoe back. Leave it to me, Mr. Juca."),
    ],
    "side_juca_done": [
        ("lio", "A sua ferradura. E o sítio está livre de bandidos.", "Your horseshoe. And the farm is free of bandits."),
        ("juca", "Hehe! Agora sim. No meu tempo a gente pagava com galinha, mas toma umas moedas.", "Heh! Now that's more like it. Back in my day we paid in chickens, but here, take some coins."),
    ],
    # --- Secundária: A farinha da Celeste (Campos de Pradoluz) ---
    "side_farinha_offer": [
        ("celeste", "Ai, Lio... a carroça da farinha tombou nos Campos quando os bandidos atacaram. Os sacos ficaram espalhados.", "Oh, Lio... the flour cart tipped over in the Fields when the bandits attacked. The sacks got scattered."),
        ("lio", "Quantos sacos?", "How many sacks?"),
        ("celeste", "Três. Sem farinha, nada de pão doce na loja.", "Three. No flour, no sweet bread in the shop."),
        ("lio", "Pão doce? Já estou indo.", "Sweet bread? I'm already on my way."),
    ],
    "side_farinha_done": [
        ("lio", "Três sacos de farinha. Meio amassados, mas inteiros.", "Three sacks of flour. A bit squashed, but whole."),
        ("celeste", "Que menino bom! Toma, e passa aqui amanhã que tem pão doce saindo do forno.", "What a good boy! Here, and come by tomorrow, there'll be sweet bread fresh from the oven."),
    ],
    # --- Secundária: A estrada do nordeste (Bosque Seco, depois do Gorvan) ---
    "side_estrada_offer": [
        ("bram", "Antes de você sumir no mundo: a estrada do nordeste, depois da floresta, está tomada por bandidos.", "Before you vanish into the world: the north-east road, past the forest, is overrun by bandits."),
        ("lio", "Os mesmos que roubavam aqui?", "The same ones who robbed us here?"),
        ("bram", "Piores. Gente que perdeu tudo pros Arautos e agora rouba quem passa. Limpe o caminho e volte inteiro.", "Worse. People who lost everything to the Heralds and now rob whoever passes. Clear the road and come back in one piece."),
        ("lio", "Inteiro é o meu tamanho favorito.", "One piece is my favorite size."),
    ],
    "side_estrada_done": [
        ("lio", "Estrada limpa. Eles nem eram tão durões.", "Road's clear. They weren't even that tough."),
        ("bram", "Mentira. Tem um corte novo na sua bochecha.", "Liar. There's a new cut on your cheek."),
        ("bram", "Toma. Foi minha quando eu tinha a sua idade. Hoje fica melhor em você.", "Here. It was mine when I was your age. It suits you better now."),
    ],
    # --- Secundária: O aço roubado (Bosque Seco, Tobias) ---
    "side_aco_offer": [
        ("tobias", "L-lio! A carroça de aço que vinha do sul n-não chegou. Os bandidos da estrada pegaram tudo.", "L-lio! The steel cart coming from the south n-never arrived. The road bandits took it all."),
        ("lio", "No Bosque Seco? Vi umas tendas por lá.", "In the Withered Grove? I saw some tents out there."),
        ("tobias", "Isso! Três caixotes. E t-tem uns orcs grandões ajudando eles agora.", "That's it! Three crates. And th-there are some big orcs helping them now."),
        ("lio", "Orcs carregando aço pra bandido. Que mundo. Pode deixar.", "Orcs hauling steel for bandits. What a world. Leave it to me."),
    ],
    "side_aco_done": [
        ("lio", "Três caixotes de aço. E os orcs vão pensar duas vezes antes de voltar.", "Three crates of steel. And the orcs will think twice before coming back."),
        ("tobias", "Com isso eu f-forjo por um ano! Toma, uma broca e um trevo. Você vai precisar.", "With this I can f-forge for a year! Here, a drill and a clover. You'll need them."),
    ],
    # --- Secundária: Tempero da estepe (Estepe de Pedra, Bento) ---
    "side_tempero_offer": [
        ("bento", "Sócio, tenho um sonho. Um ensopado digno de rei. Mas falta a sálvia-de-pedra.", "Partner, I have a dream. A stew fit for a king. But it needs stone sage."),
        ("lio", "E onde cresce essa sálvia?", "And where does this sage grow?"),
        ("bento", "Na Estepe de Pedra, entre os arenitos. Quatro molhos! E... dizem que tem bandido por lá. Por isso você vai e eu fico.", "On the Stone Steppe, among the sandstone. Four bunches! And... they say there are bandits there. That's why you go and I stay."),
        ("lio", "Corajoso como sempre.", "Brave as ever."),
    ],
    "side_tempero_done": [
        ("lio", "Quatro molhos de sálvia-de-pedra. Cheiram a poeira.", "Four bunches of stone sage. They smell like dust."),
        ("bento", "Cheiram a GLÓRIA! Prova esse caldo e depois me diz se não sou o melhor cozinheiro do reino.", "They smell like GLORY! Taste this broth and then tell me I'm not the best cook in the kingdom."),
        ("lio", "...Tá, é o melhor. Não conta pra minha mãe.", "...Fine, it's the best. Don't tell my mom."),
    ],
    # --- Ato 2, missão 7: A cidade da sede ---
    "main_07_zahir": [
        ("zahir", "Viajante! Bem-vindo a Qaressa, a joia do deserto! Água? Tenho. Só que custa um olho... e o outro de entrada.", "Traveler! Welcome to Qaressa, jewel of the desert! Water? I have some. It costs an arm... and a leg as a deposit."),
        ("lio", "Vocês vivem em volta de um oásis e a água custa ouro?", "You live around an oasis and water costs gold?"),
        ("zahir", "Shhh! A Arauta Sahra lacrou todos os poços. Quem quer beber, compra dela. Eu só... revendo. Com uma margenzinha.", "Shhh! Herald Sahra sealed every well. Whoever wants a drink buys from her. I just... resell. With a tiny margin."),
        ("zahir", "Se quer saber mais, fale com a Nadira, a ferreira. Foi ela que tentou quebrar o cadeado do poço grande.", "If you want to know more, talk to Nadira, the blacksmith. She's the one who tried to break the big well's lock."),
    ],
    "main_07_nadira": [
        ("nadira", "Um forasteiro com cara de quem vai arrumar confusão. Gostei.", "An outsider who looks like he's about to cause trouble. I like it."),
        ("lio", "Ouvi dizer que você tentou abrir um poço.", "I heard you tried to open a well."),
        ("nadira", "Tentei. O cadeado é de ouro do céu: nenhum martelo daqui arranha. A chave fica com a Sahra, na Torre Afundada.", "I tried. The lock is sky-gold: no hammer here even scratches it. Sahra keeps the key in the Sunken Tower."),
        ("nadira", "Mas a torre só abre com os selos das Ruínas de Ammar. E as ruínas estão cheias de coisa que não devia estar viva.", "But the tower only opens with the seals from the Ruins of Ammar. And the ruins are full of things that shouldn't be alive."),
        ("lio", "Coisas mortas que andam. Minha especialidade nova.", "Dead things that walk. My new specialty."),
        ("nadira", "Antes, me traga escamas dos homens-lagarto das dunas. Com elas eu faço armadura que aguenta o sol daqui.", "First, bring me scales from the lizardmen in the dunes. With them I make armor that can take this sun."),
    ],
    "main_07_nadira_done": [
        ("nadira", "Escamas boas. Grossas. Isso vai virar couraça.", "Good scales. Thick. These will become armor."),
        ("nadira", "As Ruínas de Ammar ficam a leste das dunas. Ainda estamos limpando o caminho, então descanse e se prepare.", "The Ruins of Ammar lie east of the dunes. We're still clearing the way, so rest and get ready."),
    ],
    "zahir_idle": [
        ("zahir", "Preço especial pra você, amigo! Bem... especial pra mim, mas você entendeu.", "Special price for you, friend! Well... special for me, but you get it."),
    ],
    "nadira_idle": [
        ("nadira", "Fogo, martelo e paciência. O resto é conversa.", "Fire, hammer and patience. The rest is just talk."),
    ],
    # --- Ato 2, missão 8: As Ruínas de Ammar ---
    "main_08_nadira": [
        ("nadira", "O caminho para as Ruínas de Ammar está aberto, a leste das dunas.", "The way to the Ruins of Ammar is open, east of the dunes."),
        ("nadira", "Dizem que os selos da Torre Afundada estão lá. E que os mortos guardam cada pedra.", "They say the seals of the Sunken Tower are there. And that the dead guard every stone."),
        ("lio", "Mortos guardando pedra. Deve ser o emprego mais chato do mundo.", "Dead guys guarding rocks. Must be the most boring job in the world."),
    ],
    "main_08_mural": [
        ("lio", "Uma pintura... gente subindo uma escada até o céu. E um homem com asas lá em cima.", "A painting... people climbing a staircase to the sky. And a winged man up top."),
        ("lio", "Homens que subiram ao céu. Então o Vaelor não caiu do céu. Ele SUBIU até lá?", "Men who rose to the sky. So Vaelor didn't fall from the sky. He CLIMBED up there?"),
    ],
    "severin_intro": [
        ("severin", "Pare aí. Este templo pertence à Ordem Celeste.", "Stop right there. This temple belongs to the Celestial Order."),
        ("lio", "E você é...?", "And you are...?"),
        ("severin", "Severin Vale. Ouvi falar de um garoto que derrubou o Arauto da Colheita. Esperava alguém maior.", "Severin Vale. I heard of a boy who brought down the Herald of the Harvest. I expected someone bigger."),
        ("severin", "Os Arautos mantêm a ordem. Sem eles, o mundo vira caos. Vou te mostrar o que acontece com quem esquece isso.", "The Heralds keep order. Without them, the world falls into chaos. I'll show you what happens to those who forget it."),
    ],
    "severin_duel_end": [
        ("severin", "Chega. Você é rápido, mas luta como quem briga na feira.", "Enough. You're fast, but you fight like a market brawler."),
        ("lio", "Ainda... estou de pé...", "Still... standing..."),
        ("severin", "De pé, não. Vivo. Porque eu quis.", "Not standing. Alive. Because I allowed it."),
        ("severin", "Volte para a sua vila, garoto. Da próxima vez eu não vou segurar o golpe.", "Go back to your village, boy. Next time I won't hold back my blade."),
        ("lio", "Da próxima vez... eu vou estar pronto.", "Next time... I'll be ready."),
    ],
    "main_08_return": [
        ("nadira", "Você está um trapo. O que houve?", "You look like a rag. What happened?"),
        ("lio", "Um cavaleiro da Ordem Celeste. Severin. Ele me derrubou como se eu fosse um saco de farinha.", "A knight of the Celestial Order. Severin. He knocked me down like a sack of flour."),
        ("nadira", "A Ordem serve aos Arautos. Se ele estava lá, a Sahra sabe que você vem.", "The Order serves the Heralds. If he was there, Sahra knows you're coming."),
        ("nadira", "Descanse. E treine. A Torre Afundada não vai ser mais gentil que ele.", "Rest. And train. The Sunken Tower won't be any kinder than he was."),
    ],
    # --- Ato 2, missão 9: A Arauta da Sede ---
    "main_09_nadira": [
        ("nadira", "Você voltou inteiro. Bom. Achei o caminho da Torre Afundada: a leste das Ruínas, depois do muro quebrado.", "You came back in one piece. Good. I found the way to the Sunken Tower: east of the Ruins, past the broken wall."),
        ("nadira", "A Sahra guarda lá a chave dos poços. E toda a água que ela tirou da cidade, em jarros lacrados.", "Sahra keeps the key to the wells there. And all the water she took from the city, in sealed jars."),
        ("lio", "Uma vilã que coleciona jarros de água. O Bram nunca vai acreditar.", "A villain who collects water jars. Bram will never believe it."),
        ("nadira", "Não ria. Dizem que quando ela se irrita, vira areia. E areia não sangra.", "Don't laugh. They say that when she gets angry, she turns into sand. And sand doesn't bleed."),
    ],
    "main_09_tower": [
        ("lio", "Olha o tamanho disso... a torre inteira está afundando na areia.", "Look at the size of it... the whole tower is sinking into the sand."),
        ("lio", "E esses jarros... cada um é a água de uma família de Qaressa. Ela vai devolver tudo. Gota por gota.", "And these jars... each one is a Qaressa family's water. She's giving it all back. Drop by drop."),
    ],
    "sahra_intro": [
        ("sahra", "Um cliente! Que raridade aqui em cima. Veio comprar água, querido? Para você, faço preço de amigo.", "A customer! How rare up here. Come to buy water, dear? For you, a friend's price."),
        ("lio", "Vim buscar a chave dos poços. De graça.", "I came for the key to the wells. For free."),
        ("sahra", "De graça? Nada no deserto é de graça. Nem a sombra. Nem a sua vida.", "For free? Nothing in the desert is free. Not the shade. Not your life."),
        ("sahra", "O Soberano Alado me deu a sede deste povo para guardar. E eu cobro juros.", "The Winged Sovereign gave me this people's thirst to keep. And I charge interest."),
    ],
    "sahra_transform": [
        ("sahra", "Você suja minhas sedas e ainda quer desconto? Chega de negociar!", "You stain my silks and still want a discount? No more bargaining!"),
        ("sahra", "Areia, venha a mim! Mostre a ele o que é sede de verdade!", "Sand, come to me! Show him what true thirst is!"),
    ],
    "sahra_reborn": [
        ("lio", "Ela virou uma guerreira de areia! E sumiu no chão... ela pode aparecer atrás de mim!", "She turned into a sand warrior! And she sank into the ground... she can pop up behind me!"),
        ("lio", "Escudo de novo... e os jarros de água que brotaram curam ela. Quebro o escudo e quebro os jarros antes que ela beba!", "A shield again... and the water jars that sprouted heal her. Break the shield and smash the jars before she drinks!"),
    ],
    "main_09_return": [
        ("nadira", "Ouviu isso? Os poços... a água está subindo! O povo está dançando na praça!", "Did you hear that? The wells... the water is rising! People are dancing in the square!"),
        ("lio", "A chave estava no colar dela. Achei que ia ser mais difícil abrir um cadeado de ouro do céu.", "The key was on her necklace. I thought opening a sky-gold lock would be harder."),
        ("nadira", "Você derrubou dois Arautos, garoto. A Ordem Celeste não vai deixar barato.", "You've brought down two Heralds, kid. The Celestial Order won't let this go."),
        ("nadira", "Mas hoje Qaressa bebe de graça. Hoje a gente comemora.", "But today Qaressa drinks for free. Today we celebrate."),
    ],
    # --- Ato 3, missão 10: Rumo ao frio ---
    "main_10_nadira": [
        ("nadira", "Chegou carta do norte, de Hrimvald. Uma fortaleza nas montanhas. O povo está congelando.", "A letter came from the north, from Hrimvald. A fortress in the mountains. The people are freezing."),
        ("nadira", "Dizem que o Arauto de lá, o Brannoc, trancou toda a lenha e todo o carvão. Quem quer se aquecer, ajoelha.", "They say their Herald, Brannoc, locked away all the firewood and coal. Whoever wants warmth has to kneel."),
        ("lio", "Primeiro comida, depois água, agora fogo. Esses Arautos têm um manual?", "First food, then water, now fire. Do these Heralds share a handbook?"),
        ("nadira", "O caminho sai das Dunas, a oeste: deserto de pedra, planalto e um pinheiral cheio de neve. Leve roupa quente.", "The road leaves the Dunes to the west: stone desert, highlands and a pine forest full of snow. Take warm clothes."),
        ("bento", "Roupa quente e uma panela grande. Onde tem frio, tem gente precisando de sopa.", "Warm clothes and a big pot. Where it's cold, people need soup."),
    ],
    "main_10_arrive": [
        ("lio", "Hrimvald... nenhuma chaminé soltando fumaça. E aquela jaula cheia de lenha bem no meio da praça.", "Hrimvald... not a single chimney smoking. And that cage full of firewood right in the middle of the square."),
        ("bento", "Lenha trancada na frente de quem está morrendo de frio. Isso não é lei, Lio. É crueldade com cadeado.", "Firewood locked in front of people freezing to death. That's not law, Lio. That's cruelty with a padlock."),
        ("lio", "Vamos achar alguém que conheça a cidade. Aquele velhinho de cobertor parece saber de tudo.", "Let's find someone who knows the town. That old man in the blanket looks like he knows everything."),
    ],
    "main_10_osk": [
        ("osk", "Forasteiros... e sem tremer? Ou são loucos ou são de muito longe.", "Strangers... and not shivering? Either you're mad or from very far away."),
        ("lio", "Um pouco dos dois. Sou o Lio. O que aconteceu com a lenha da cidade?", "A bit of both. I'm Lio. What happened to the town's firewood?"),
        ("osk", "O Brannoc mandou cortar tudo e trancar. Diz que o calor é presente do céu, e presente se merece.", "Brannoc had it all cut and locked up. He says warmth is a gift from the sky, and gifts must be earned."),
        ("osk", "Eu já queimei a mesa, as cadeiras e a cama pra aquecer meus netos. Ia buscar galhos no pinheiral...", "I've already burned the table, the chairs and the bed to warm my grandchildren. I was going to fetch branches in the pine woods..."),
        ("osk", "Mas os mortos andam lá agora. Gente que morreu de frio, e o frio não deixou descansar.", "But the dead walk there now. People who died of cold, and the cold wouldn't let them rest."),
        ("lio", "Então eu limpo o caminho. Ninguém mais vai ter medo de buscar lenha.", "Then I'll clear the way. Nobody will be afraid to fetch wood again."),
    ],
    "main_10_osk_done": [
        ("lio", "O pinheiral está mais calmo. Os mortos de lá descansaram, finalmente.", "The pine woods are calmer. The dead there are finally resting."),
        ("osk", "Você fez isso por gente que nem conhece... Meu pai dizia que o calor de verdade vem das pessoas.", "You did this for people you don't even know... My father used to say real warmth comes from people."),
        ("osk", "Mas o Brannoc vai saber. Ele sempre sabe. Cuidado, rapaz. Ele não é um homem que perdoa.", "But Brannoc will know. He always knows. Be careful, lad. He's not a man who forgives."),
        ("bento", "Eu fico aqui ajudando o povo. Faço sopa com o que tiver. Você descobre um jeito de abrir aquela jaula.", "I'll stay and help the people. I'll make soup with whatever there is. You find a way to open that cage."),
    ],
    "osk_idle": [
        ("osk", "Os netos dormem abraçados no cachorro. É o único cobertor que sobrou.", "My grandkids sleep hugging the dog. It's the only blanket left."),
    ],
    "osk_idle_after": [
        ("osk", "O fogo voltou a uma casa: a minha. Graças a você e àquele seu amigo da sopa.", "Fire came back to one house: mine. Thanks to you and that soup friend of yours."),
    ],
    "brunhild_idle": [
        ("brunhild", "Forja sem carvão é só um banquinho de ferro. Mas eu dou meu jeito. Quer melhorar essa espada?", "A forge without coal is just an iron stool. But I manage. Want to improve that sword?"),
    ],
    "bento_idle_hrimvald": [
        ("bento", "Sopa de raiz, sopa de casca, sopa de sola de bota... aqui a gente inventa. O importante é estar quente.", "Root soup, bark soup, boot-sole soup... here we improvise. What matters is that it's hot."),
    ],
    # --- Ato 3, missão 11: A mina debaixo da montanha ---
    "main_11_brunhild": [
        ("brunhild", "Quer chegar no Brannoc? O castelo dele fica no alto dos Picos Uivantes. A ponte foi derrubada há anos.", "Want to reach Brannoc? His castle sits high on the Howling Peaks. The bridge was knocked down years ago."),
        ("brunhild", "Mas meu avô cavava na Mina de Gelo, debaixo da montanha. Dizem que os túneis vão até os porões do castelo.", "But my grandfather dug in the Ice Mine, under the mountain. They say the tunnels reach the castle cellars."),
        ("lio", "Uma mina esquecida, congelada e provavelmente cheia de monstros. Meu tipo de atalho.", "A forgotten, frozen mine, probably full of monsters. My kind of shortcut."),
        ("brunhild", "A entrada fica no fim da crista, ao norte da cidade. Volte inteiro, ouviu? Eu acabei de afiar essa espada.", "The entrance is at the end of the ridge, north of town. Come back in one piece, you hear? I just sharpened that sword."),
    ],
    "main_11_peaks": [
        ("lio", "Esse vento parece que grita. Agora entendi o nome: Picos Uivantes.", "This wind sounds like it's screaming. Now I get the name: the Howling Peaks."),
        ("lio", "A entrada da mina deve estar depois daquela crista. E tem alguém parado lá em cima...", "The mine entrance must be past that ridge. And someone is standing up there..."),
    ],
    "severin2_intro": [
        ("severin", "Eu sabia que você viria por aqui. Garotos teimosos sempre escolhem o caminho mais difícil.", "I knew you'd come this way. Stubborn boys always pick the hardest path."),
        ("lio", "Severin. Veio me mandar de volta pra casa de novo?", "Severin. Here to send me home again?"),
        ("severin", "O Brannoc é duro, mas mantém Hrimvald de pé. Sem ordem, aquele povo se mata por um pedaço de lenha.", "Brannoc is harsh, but he keeps Hrimvald standing. Without order, those people would kill each other over a log."),
        ("lio", "Eles estão morrendo de frio olhando pra uma jaula cheia de lenha. Isso é ordem pra você?", "They're freezing to death staring at a cage full of firewood. Is that order to you?"),
        ("severin", "...Levante a espada. Desta vez eu não vou segurar.", "...Raise your sword. This time I won't hold back."),
    ],
    "severin2_duel_end": [
        ("severin", "Hah... hah... Você ficou mais forte. Muito mais forte.", "Hah... hah... You've grown stronger. Much stronger."),
        ("lio", "E você ficou mais lento. Ou está pensando demais no que eu disse?", "And you've gotten slower. Or are you thinking too much about what I said?"),
        ("severin", "Empate. Por hoje. Não confunda isso com eu concordar com você.", "A draw. For today. Don't mistake that for me agreeing with you."),
        ("severin", "Vá para a mina, se quiser. O que está lá embaixo não é problema meu.", "Go to the mine, if you want. Whatever is down there isn't my problem."),
    ],
    "main_11_bento": [
        ("bento", "Lio! Você voltou! E coberto de gelo... senta aqui, a sopa de casca de pinheiro está quase boa.", "Lio! You're back! And covered in ice... sit here, the pine-bark soup is almost good."),
        ("lio", "Atravessei a mina inteira. No fundo tinha um gigante de gelo guardando um túnel que sobe para o castelo.", "I crossed the whole mine. At the bottom there was an ice giant guarding a tunnel that goes up to the castle."),
        ("lio", "E o Severin de novo. Desta vez ninguém caiu. Acho que ele está começando a duvidar dos Arautos.", "And Severin again. This time nobody fell. I think he's starting to doubt the Heralds."),
        ("bento", "Então o castelo está logo ali. Lio... quando você for, eu vou junto. Não discute.", "Then the castle is right there. Lio... when you go, I'm going with you. Don't argue."),
        ("lio", "Bento, lá vai ser perigoso de verdade.", "Bento, it's going to be really dangerous there."),
        ("bento", "Por isso mesmo. Alguém tem que garantir que você coma antes de salvar o mundo.", "That's exactly why. Someone has to make sure you eat before saving the world."),
    ],
    # --- Ato 3, missão 12: O Arauto do Frio ---
    "main_12_bento": [
        ("bento", "Arrumei a mochila: pão de casca, sopa em pote e um cachecol extra. Vamos acabar com esse inverno?", "Packed the bag: bark bread, soup in a jar and an extra scarf. Shall we end this winter?"),
        ("lio", "Bento... promete que fica atrás de mim o tempo todo?", "Bento... promise you'll stay behind me the whole time?"),
        ("bento", "Prometo ficar perto. Atrás é com você. Vamos, o túnel da mina sobe direto para o castelo.", "I promise to stay close. Behind is up to you. Come on, the mine tunnel goes straight up to the castle."),
    ],
    "main_12_castle": [
        ("lio", "Castelo Ermo. Nem os estandartes balançam aqui. Até o vento tem medo dele.", "The Lonely Castle. Not even the banners move here. Even the wind is afraid of him."),
        ("bento", "Lá no fundo, perto do trono. Aquele velho de capa é o Brannoc. Lio... cuidado com o machado.", "Down there, by the throne. That old man in the cloak is Brannoc. Lio... watch out for the axe."),
    ],
    "brannoc_intro": [
        ("brannoc", "Então é você. O menino que derrubou a Colheita e a Sede, e agora quer derreter o meu inverno.", "So it's you. The boy who toppled Harvest and Thirst, and now wants to melt my winter."),
        ("lio", "Seu inverno está matando gente que só quer se aquecer. Abra a jaula, Brannoc.", "Your winter is killing people who only want to keep warm. Open the cage, Brannoc."),
        ("brannoc", "O frio ensina. Quem tem fome de calor aprende a obedecer. Foi o céu que me deu essa lição.", "Cold teaches. Those hungry for warmth learn to obey. The sky gave me that lesson."),
        ("bento", "Isso não é lição, é maldade! Ele tem netos, sabia? O Osk queimou a própria cama!", "That's no lesson, it's cruelty! He has grandkids, you know? Osk burned his own bed!"),
        ("brannoc", "Então que os dois congelem juntos.", "Then you can both freeze together."),
    ],
    "brannoc_transform": [
        ("brannoc", "Chega! Vocês querem ver o verdadeiro inverno?", "Enough! You want to see the true winter?"),
        ("brannoc", "Gelo antigo, levanta! Que esta montanha inteira se curve!", "Ancient ice, rise! Let this whole mountain bow!"),
    ],
    "brannoc_reborn": [
        ("lio", "Ele virou um gigante de gelo! E esse brilho de novo... um escudo.", "He turned into an ice giant! And that glow again... a shield."),
        ("bento", "Lio, os cristais! Ele está tirando força deles! Quebra os cristais!", "Lio, the crystals! He's drawing strength from them! Smash the crystals!"),
    ],
    "main_12_osk": [
        ("osk", "Rapaz... dois anos. O povo achou que você não ia voltar.", "Lad... two years. The people thought you'd never come back."),
        ("lio", "Eu precisava ficar mais forte. Na próxima vez que alguém entrar na frente de um golpe por mim... vai ser porque eu deixei de ser lento.", "I needed to get stronger. The next time someone steps in front of a blow for me... it won't be because I was too slow."),
        ("osk", "Todo inverno a gente acende uma fogueira no túmulo dele. A cidade inteira faz sopa nesse dia. Do jeito que ele gostaria.", "Every winter we light a fire at his grave. The whole town makes soup that day. The way he would have liked."),
        ("lio", "Ele ia reclamar do sal. E depois pedir mais um prato.", "He'd complain about the salt. And then ask for another bowl."),
        ("osk", "Chegou um mensageiro dos elfos de Lys'Thaël. A floresta deles está morrendo em silêncio. Pediram por você.", "A messenger came from the elves of Lys'Thaël. Their forest is dying in silence. They asked for you."),
    ],
    "osk_idle_final": [
        ("osk", "Os netos já brigam por lugar perto da lareira. Tem barulho melhor que esse?", "The grandkids already fight over a spot by the fireplace. Is there any sound better than that?"),
    ],
    "brunhild_idle_final": [
        ("brunhild", "Carvão à vontade e um herói de volta. Essa bigorna nunca cantou tão alto. Bora melhorar essa espada?", "Coal galore and a hero back home. This anvil never sang so loud. Shall we improve that sword?"),
    ],
    # --- Ato 4, missão 13: A floresta em silêncio ---
    "main_13_arrive": [
        ("lio", "Lys'Thaël... uma cidade inteira nas árvores. E ninguém fala. Nem um passarinho.", "Lys'Thaël... a whole city in the trees. And nobody speaks. Not even a bird."),
        ("lio", "Aquela árvore gigante no meio está perdendo as folhas. Dá pra sentir que ela está doente.", "That giant tree in the middle is losing its leaves. You can feel it's sick."),
        ("lio", "Bento ia dizer que um lugar tão bonito precisa de música. ...Vamos descobrir quem tirou a música daqui.", "Bento would say a place this beautiful needs music. ...Let's find out who took the music away."),
    ],
    "main_13_elarion": [
        ("elarion", "Psiu! Fale baixo, forasteiro. Aqui quem canta, some. Ordem da Arauta Velyra.", "Shh! Keep your voice down, outsider. Here, whoever sings disappears. Herald Velyra's orders."),
        ("lio", "Proibiram cantar? Por quê?", "They banned singing? Why?"),
        ("elarion", "Nossos cantos alimentavam a Árvore-Mãe. Sem eles, a Velyra suga a força dela para o céu. E a floresta inteira murcha junto.", "Our songs fed the Mother Tree. Without them, Velyra drains her strength up to the sky. And the whole forest withers with her."),
        ("elarion", "Os cultistas mascarados vigiam as bordas do pântano. Quem tenta fugir para cantar lá fora não volta.", "The masked cultists watch the swamp's edge. Whoever tries to sneak out to sing never comes back."),
        ("lio", "Então eu vou lá conversar com eles. Do meu jeito.", "Then I'll go have a word with them. My way."),
    ],
    "main_13_faenor": [
        ("faenor", "Então foi você que espantou os mascarados. A cidade respirou um pouco hoje.", "So you're the one who scared off the masked ones. The city breathed a little today."),
        ("faenor", "Eu entalho lâminas há trezentos anos. Nunca vi a Árvore-Mãe tão fraca. A Velyra mora na Torre do Vigia, no meio do Pântano das Raízes.", "I've carved blades for three hundred years. I've never seen the Mother Tree so weak. Velyra lives in the Watcher's Tower, in the middle of the Swamp of Roots."),
        ("faenor", "O caminho para o pântano sai pelo norte da cidade. Agora que os cultistas recuaram, o portão pode abrir.", "The way to the swamp leaves through the north of the city. Now that the cultists fell back, the gate can open."),
        ("lio", "Obrigado, Faenor. Afia a minha espada enquanto eu ainda tenho uma, tá?", "Thanks, Faenor. Sharpen my sword while I still have one, okay?"),
    ],
    "elarion_idle": [
        ("elarion", "Tenho de tudo um pouco. Só não peça partitura... isso dá cadeia por aqui.", "I've got a bit of everything. Just don't ask for sheet music... that'll get you jailed around here."),
    ],
    "faenor_idle": [
        ("faenor", "Uma lâmina boa é como um canto: precisa de paciência e de alguém que a escute.", "A good blade is like a song: it needs patience and someone to listen to it."),
    ],
    # --- Ato 4, missão 14: O vigia e o segredo ---
    "main_14_faenor": [
        ("faenor", "O portão norte está aberto. O Pântano das Raízes começa logo depois, e a Torre do Vigia fica no fundo dele.", "The north gate is open. The Swamp of Roots starts right after it, and the Watcher's Tower stands at its far end."),
        ("faenor", "Dizem que um cavaleiro de armadura azul chegou ontem. Ficou parado na clareira diante da torre, como quem espera alguém.", "They say a knight in blue armor arrived yesterday. He's been standing in the clearing before the tower, like someone waiting."),
        ("lio", "Armadura azul e cara de quem nunca ri? Eu sei quem é.", "Blue armor and a face that never smiles? I know who that is."),
    ],
    "main_14_swamp": [
        ("lio", "Raízes do tamanho de pontes... e todas apontando para aquela torre. Como se a Velyra puxasse a vida da floresta inteira.", "Roots the size of bridges... all pointing at that tower. As if Velyra were pulling the life out of the whole forest."),
    ],
    "severin3_intro": [
        ("severin", "Garoto. Ou melhor... não é mais um garoto. Dois anos fizeram diferença.", "Boy. Or rather... not a boy anymore. Two years made a difference."),
        ("lio", "Você também mudou, Severin. Da última vez você hesitou.", "You've changed too, Severin. Last time you hesitated."),
        ("severin", "Eu não hesito. A Velyra mantém essa floresta em ordem. É o meu dever proteger a torre.", "I don't hesitate. Velyra keeps this forest in order. It's my duty to guard the tower."),
        ("lio", "Então vamos terminar isso. Sem empate dessa vez.", "Then let's finish this. No draw this time."),
    ],
    "severin3_duel_end": [
        ("severin", "Hah... não... eu perdi.", "Hah... no... I lost."),
        ("lio", "Fica no chão, Severin. Eu não vim te matar.", "Stay down, Severin. I didn't come to kill you."),
        ("lio", "...Espera. Ouviu isso? Tem crianças cantando lá na beira da água.", "...Wait. Did you hear that? There are children singing by the water."),
    ],
    "severin3_after": [
        ("severin", "Ela... ia matá-las. Crianças. Só por cantarem.", "She... was going to kill them. Children. Just for singing."),
        ("severin", "Disseram que os Arautos trazem ordem. Que ordem precisa de um chicote de espinhos contra crianças?", "They said the Heralds bring order. What order needs a whip of thorns against children?"),
        ("lio", "Você sabe a resposta. Só falta ter coragem de dizer.", "You know the answer. You just need the courage to say it."),
        ("severin", "...Vá até a torre. Eu não vou te impedir. Preciso pensar.", "...Go to the tower. I won't stop you. I need to think."),
    ],
    "main_14_bram": [
        ("bram", "Moleque! Ou melhor, homem feito. Olha só a cicatriz. Ficou melhor que a minha.", "Kid! Or rather, a grown man. Look at that scar. Looks better than mine."),
        ("lio", "Mestre Bram? Você atravessou meio mundo até aqui?", "Master Bram? You crossed half the world to get here?"),
        ("bram", "Soube do Bento. Sinto muito, garoto. E soube que você está indo atrás dos Arautos, um por um. Então tem uma coisa que eu devia ter contado há muito tempo.", "I heard about Bento. I'm sorry, kid. And I heard you're going after the Heralds, one by one. So there's something I should have told you a long time ago."),
        ("bram", "Na noite em que você nasceu, acharam só um dedo do seu pai na neve. Disseram que foram lobos.", "The night you were born, they only found one of your father's fingers in the snow. They said it was wolves."),
        ("bram", "Eu vi aquele dedo, Lio. Não foi dente. Foi um corte limpo. De faca.", "I saw that finger, Lio. It wasn't teeth. It was a clean cut. A knife."),
        ("lio", "Então... meu pai...", "Then... my father..."),
        ("bram", "O Doran pode estar vivo. Não sei onde, nem por quê. Mas lobo nenhum corta assim.", "Doran may be alive. I don't know where, or why. But no wolf cuts like that."),
    ],
    # --- Ato 4, missão 15: A Arauta do Silêncio ---
    "main_15_stairs": [
        ("lio", "Quantos degraus... O Bento ia reclamar de cada um deles.", "So many steps... Bento would have complained about every single one."),
        ("lio", "Lá em cima. Dá pra sentir a floresta sendo puxada pra ela.", "Up there. I can feel the forest being pulled toward her."),
    ],
    "velyra_intro": [
        ("velyra", "Silêncio. Esta torre só ouve o vento.", "Silence. This tower listens only to the wind."),
        ("lio", "E as crianças que você queria calar no pântano? Também eram vento?", "And the children you wanted to silence in the swamp? Were they wind too?"),
        ("velyra", "Canções acordam a floresta, e a floresta pertence aos deuses. Eu só devolvo a eles o que é deles.", "Songs wake the forest, and the forest belongs to the gods. I only give back to them what is theirs."),
        ("lio", "Então eu vim pegar de volta.", "Then I came to take it back."),
    ],
    "velyra_transform": [
        ("velyra", "Basta! Se você não se cala, a floresta inteira vai te engolir!", "Enough! If you won't be silent, the whole forest will swallow you!"),
    ],
    "velyra_reborn": [
        ("lio", "Um escudo de casca... e essas flores roxas estão dando força pra ela. Corto as flores e quebro o escudo.", "A shield of bark... and those purple flowers are feeding her. I cut the flowers and break the shield."),
        ("lio", "E se as raízes me prenderem, uma investida ou um salto me solta.", "And if the roots grab me, a charge or a leap will tear me free."),
    ],
    "main_15_elarion": [
        ("elarion", "Está ouvindo? A floresta está cantando de novo! Até as crianças voltaram para debaixo da Árvore-Mãe.", "Do you hear it? The forest is singing again! Even the children are back under the Mother Tree."),
        ("lio", "Ela ficou linda assim. Bem melhor que cinza.", "She looks beautiful like this. Much better than grey."),
        ("elarion", "Chegou um mensageiro de Altaréa, a capital. O Arauto Cassian fechou os portões e proibiu até as pessoas de se reunirem.", "A messenger came from Altaréa, the capital. The Herald Cassian closed the gates and forbade people from even gathering."),
        ("lio", "Mais um Arauto. Então é para lá que eu vou.", "Another Herald. Then that's where I'm going."),
        ("elarion", "Leve isto, com a gratidão de todo o povo de Lys'Thaël. E volte para ouvir a gente cantar.", "Take this, with the gratitude of all of Lys'Thaël. And come back to hear us sing."),
    ],
    # --- Ato 5, missão 16: A Lei de Ferro ---
    "main_16_road": [
        ("lio", "A Estrada Real... e guardas da Lei até no meio do trigo. O Cassian não deixa nem o vento passar sem carimbo.", "The Royal Road... and Law guards even in the middle of the wheat. Cassian won't let even the wind pass without a stamp."),
        ("lio", "Bento, você ia adorar essa estrada. Reta, lisa, cheia de lugar pra cochilar.", "Bento, you'd love this road. Straight, smooth, full of places to nap."),
    ],
    "main_16_city": [
        ("lio", "Altaréa. Ruas brancas, bandeiras douradas... e ninguém na rua. Toque de recolher em plena luz do dia.", "Altaréa. White streets, golden banners... and nobody outside. A curfew in broad daylight."),
        ("lio", "Aquela estátua na praça deve ser ele. O Juiz. O Arauto da Lei.", "That statue in the square must be him. The Judge. The Herald of the Law."),
    ],
    "main_16_isolda": [
        ("isolda", "Você é o rapaz que derrubou a Velyra? Pensei que fosse mais alto.", "You're the boy who brought down Velyra? I thought you'd be taller."),
        ("lio", "Todo mundo pensa. E você é...?", "Everyone does. And you are...?"),
        ("isolda", "Isolda. Eu cuido da resistência, se dá para chamar assim um punhado de padeiros e estudantes com raiva.", "Isolda. I run the resistance, if you can call a handful of angry bakers and students that."),
        ("isolda", "O Cassian escreve uma lei nova por dia. Ontem proibiu reuniões de mais de três pessoas. Hoje, proibiu rir na praça.", "Cassian writes a new law every day. Yesterday he banned gatherings of more than three people. Today, he banned laughing in the square."),
        ("isolda", "Quem desobedece vai para as minas do castelo, com os carcereiros. Meu irmão está lá há um ano.", "Whoever disobeys goes to the castle mines, with the jailers. My brother has been there for a year."),
        ("lio", "Então a gente tira ele de lá. E tira o Cassian do trono.", "Then we get him out of there. And get Cassian off the throne."),
        ("isolda", "O portão do castelo é guardado dia e noite. Precisamos de um plano... e de mais gente. Me dê um tempo para reunir o pessoal.", "The castle gate is guarded day and night. We need a plan... and more people. Give me some time to gather everyone."),
    ],
    "isolda_idle": [
        ("isolda", "Fala baixo. As paredes desta cidade têm ouvidos e todos usam capacete.", "Keep your voice down. The walls of this city have ears, and they all wear helmets."),
    ],
    "aurelio_idle": [
        ("aurelio", "Bem-vindo, bem-vindo! Só não fique mais de três minutos parado na porta. Tem lei para isso também.", "Welcome, welcome! Just don't stand at the door for more than three minutes. There's a law for that too."),
    ],
    "matias_idle": [
        ("matias", "Eu forjava arados. Agora o Castelo só encomenda grilhões. Mas para você, eu afio o que precisar.", "I used to forge plows. Now the Castle only orders shackles. But for you, I'll sharpen whatever you need."),
    ],
    # --- Ato 5, missão 17: O portão e o juiz ---
    "main_17_isolda": [
        ("isolda", "Reuni o pessoal. Padeiros, estudantes, até o velho Aurélio. Hoje à noite a gente abre o portão norte.", "I gathered everyone. Bakers, students, even old Aurélio. Tonight we open the north gate."),
        ("isolda", "Só tem um problema: um cavaleiro de armadura azul chegou de manhã e está parado na frente do castelo. Ninguém tem coragem de passar por ele.", "There's just one problem: a knight in blue armor arrived this morning and is standing in front of the castle. Nobody dares to pass him."),
        ("lio", "Armadura azul? Deixa esse comigo.", "Blue armor? Leave that one to me."),
    ],
    "main_17_severin": [
        ("severin", "Eu sabia que você viria. Você sempre vem.", "I knew you'd come. You always do."),
        ("lio", "Vai me impedir de novo, Severin?", "Going to stop me again, Severin?"),
        ("severin", "Não. Desde o pântano eu não durmo. Vi o que a Velyra quase fez. Vi as correntes desta cidade. Isso não é a ordem dos deuses... é medo.", "No. Since the swamp I haven't slept. I saw what Velyra almost did. I saw the chains of this city. That isn't the gods' order... it's fear."),
        ("severin", "Vá até o Cassian. Os guardas vão vir atrás de você, e eu vou segurar este portão. Ninguém passa.", "Go to Cassian. The guards will come after you, and I'll hold this gate. No one gets through."),
        ("lio", "Bem-vindo ao lado certo, Severin.", "Welcome to the right side, Severin."),
        ("severin", "Não se acostume. E liberte os presos no caminho. Os carcereiros guardam as chaves.", "Don't get used to it. And free the prisoners on the way. The jailers carry the keys."),
    ],
    "severin_gate": [
        ("severin", "Vá. Ninguém passa por este portão enquanto eu estiver de pé.", "Go. No one passes this gate while I'm standing."),
    ],
    "cassian_intro": [
        ("cassian", "Entrar no salão do trono sem ser chamado. Mais um crime para a sua lista, garoto.", "Entering the throne hall without being summoned. One more crime for your list, boy."),
        ("lio", "Fala dos presos nas minas? Ou das crianças proibidas de rir?", "You mean the prisoners in the mines? Or the children forbidden to laugh?"),
        ("cassian", "A lei não ri, não chora e não perdoa. Por isso funciona. Os deuses me deram esta cidade para que ela obedecesse.", "The law doesn't laugh, doesn't cry and doesn't forgive. That's why it works. The gods gave me this city so it would obey."),
        ("lio", "Então vou te dar uma sentença: culpado.", "Then here's your sentence: guilty."),
    ],
    "cassian_transform": [
        ("cassian", "Basta! Se a carne é fraca, a lei veste aço!", "Enough! If the flesh is weak, the law wears steel!"),
    ],
    "cassian_reborn": [
        ("lio", "Uma armadura vazia, movida só pela lei dele... e esses pilares dourados dão força para ela. Quebro os pilares e depois o escudo.", "An empty armor, moved only by his law... and those golden pillars are feeding it. I break the pillars, then the shield."),
        ("lio", "E se as correntes me prenderem, uma investida ou um salto me solta.", "And if the chains grab me, a charge or a leap will set me free."),
    ],
    "main_17_end": [
        ("isolda", "Ele saiu! Meu irmão saiu das minas, Lio! E as pessoas estão rasgando os decretos na praça!", "He's out! My brother got out of the mines, Lio! And people are tearing up the decrees in the square!"),
        ("lio", "E o Severin?", "And Severin?"),
        ("isolda", "Segurou o portão a noite inteira. Nenhum guarda passou. Agora está lá em cima, olhando para o céu, como todo mundo.", "He held the gate all night. Not a single guard got through. Now he's up there, looking at the sky, like everyone else."),
        ("isolda", "Quando o Cassian caiu, uma escada de luz apareceu sobre o castelo. Ela sobe até uma cidade nas nuvens.", "When Cassian fell, a stairway of light appeared over the castle. It climbs up to a city in the clouds."),
        ("lio", "A Cidadela Celeste. É lá que está o Vaelor... o deus que mandou todos os Arautos.", "The Celestial Citadel. That's where Vaelor is... the god who sent all the Heralds."),
        ("isolda", "Então vá. Altaréa fica te devendo uma. E o meu irmão também.", "Then go. Altaréa owes you one. And so does my brother."),
    ],
    # --- Secundária: Decretos rasgados (Arredores, Aurélio) ---
    "side_decretos_offer": [
        ("aurelio", "Os decretos novos estão pregados nos postes dos Arredores. Quem lê fica com medo e não vem mais à cidade comprar nada.", "The new decrees are nailed to the posts in the Outskirts. Whoever reads them gets scared and stops coming to the city to buy anything."),
        ("aurelio", "Arranca uns cinco para mim? Eu guardo como prova. Um dia alguém vai ter que responder por cada linha.", "Tear down about five for me? I'll keep them as evidence. One day someone will have to answer for every line."),
        ("lio", "Rasgar papel de tirano. Esse trabalho eu faço até de graça.", "Tearing up a tyrant's paper. I'd do that job for free."),
    ],
    "side_decretos_done": [
        ("aurelio", "\"Fica proibido assobiar\"... \"Fica proibido usar azul às quintas\"... Que homem pequeno, para uma cidade tão grande.", "\"Whistling is forbidden\"... \"Wearing blue on Thursdays is forbidden\"... What a small man, for such a big city."),
        ("aurelio", "Toma, com desconto de herói. Quer dizer, de graça.", "Here, with a hero's discount. Meaning, free."),
    ],
    # --- Secundária: Correntes partidas (Arredores, Matias) ---
    "side_correntes_offer": [
        ("matias", "Os carcereiros levam gente dos sítios para as minas do castelo, presa em correntes que eu fui obrigado a forjar.", "The jailers take people from the farms to the castle mines, chained with links I was forced to forge."),
        ("matias", "Derrote seis deles nos Arredores e me traga as correntes. Eu derreto tudo e faço algo que proteja em vez de prender.", "Defeat six of them in the Outskirts and bring me the chains. I'll melt them all down and make something that protects instead of binds."),
    ],
    "side_correntes_done": [
        ("matias", "Seis correntes a menos no mundo. Isso aqui era grilhão. Agora é seu.", "Six fewer chains in the world. This used to be a shackle. Now it's yours."),
        ("lio", "Pesa menos do que parece. Igual a esperança, eu acho.", "It weighs less than it looks. Like hope, I guess."),
    ],
    # --- Secundária: Os cantos escondidos (Mata Úmida, Elarion) ---
    "side_cantos_offer": [
        ("elarion", "Antes da proibição, os bardos esconderam as partituras mais antigas na Mata Úmida. Se a Velyra achar, queima tudo.", "Before the ban, the bards hid the oldest sheet music in the Damp Woods. If Velyra finds it, she'll burn it all."),
        ("elarion", "Traz as quatro? Um dia a gente vai cantar de novo. E eu quero estar com a letra certa.", "Will you bring all four? One day we'll sing again. And I want to have the right lyrics."),
        ("lio", "Quatro partituras na mata. Eu só não prometo cantar junto.", "Four sheets in the woods. I just don't promise to sing along."),
    ],
    "side_cantos_done": [
        ("elarion", "Estão todas aqui... até a Canção da Primeira Folha. Obrigado, de verdade.", "They're all here... even the Song of the First Leaf. Thank you, truly."),
        ("elarion", "Toma, por conta da casa. E um dia eu te ensino o refrão.", "Here, on the house. And one day I'll teach you the chorus."),
    ],
    # --- Secundária: Lâmina de raiz (Bordas do Pântano, Faenor) ---
    "side_lamina_offer": [
        ("faenor", "Os mortos do pântano carregam raízes da Árvore-Mãe arrancadas pela Velyra. Elas ainda guardam força.", "The swamp dead carry roots of the Mother Tree that Velyra tore out. They still hold strength."),
        ("faenor", "Derrote oito deles e traga o que sobrar. Faço uma lâmina digna de quem vai enfrentar uma Arauta.", "Defeat eight of them and bring what's left. I'll make a blade worthy of someone facing a Herald."),
    ],
    "side_lamina_done": [
        ("faenor", "Raiz viva, aço velho e trezentos anos de mão firme. Ela é sua.", "Living root, old steel and three hundred years of steady hands. It's yours."),
        ("lio", "Ela é leve... e quente. Como se estivesse viva.", "It's light... and warm. As if it were alive."),
    ],
    # --- Secundária: Os móveis do Osk (Pinheiral, Osk) ---
    "side_moveis_offer": [
        ("osk", "Rapaz... posso pedir mais uma coisa? Sobrou só a porta da casa pra queimar.", "Lad... may I ask one more thing? All that's left to burn is my front door."),
        ("osk", "Tem galhos secos caídos no pinheiral, debaixo da neve. Quatro feixes e meus netos passam a semana quentinhos.", "There are dry branches fallen in the pine woods, under the snow. Four bundles and my grandkids stay warm all week."),
        ("lio", "Quatro feixes de galho. E a porta continua no lugar. Combinado.", "Four bundles of branches. And the door stays where it is. Deal."),
    ],
    "side_moveis_done": [
        ("lio", "Quatro feixes. Secos, do jeito que o senhor pediu.", "Four bundles. Dry, just the way you asked."),
        ("osk", "A porta agradece. E eu também. Leve isso: era do meu pai, dá sorte na forja.", "The door thanks you. And so do I. Take this: it was my father's, it brings luck at the forge."),
    ],
    # --- Secundária: Carvão roubado (Planalto Frio, Brunhild) ---
    "side_carvao_offer": [
        ("brunhild", "Você bate forte, dá pra ver pelo jeito que segura a espada. Tenho um serviço.", "You hit hard, I can tell by how you hold that sword. I've got a job."),
        ("brunhild", "Os orcs da neve roubaram as últimas carroças de carvão no Planalto Frio. Sem carvão, nada de forja.", "The snow orcs stole the last coal carts on the Cold Highlands. No coal, no forge."),
        ("lio", "Orcs que roubam carvão no frio. Pelo menos eles são coerentes.", "Orcs stealing coal in the cold. At least they're consistent."),
        ("brunhild", "Derrube oito deles e o resto foge com o rabo entre as pernas. Eu pago bem.", "Knock down eight of them and the rest run off with their tails between their legs. I pay well."),
    ],
    "side_carvao_done": [
        ("brunhild", "O carvão voltou! Agora sim, essa bigorna vai cantar.", "The coal is back! Now this anvil is going to sing."),
        ("brunhild", "Toma umas luvas que eu fiz com a sobra. Não queimam, não congelam e combinam com você.", "Take these gloves I made from the leftovers. They don't burn, don't freeze and they suit you."),
    ],
    # --- Conversas fora de missão ---
    "marta_idle_fed": [
        ("marta", "A despensa está cheia pela primeira vez em anos. Come mais um pedaço!", "The pantry is full for the first time in years. Have another slice!"),
    ],
    "bram_idle_fed": [
        ("bram", "Não fique se achando. Mas... bom trabalho, moleque.", "Don't get cocky. But... good work, kid."),
    ],
    "celeste_idle_fed": [
        ("celeste", "Prateleiras cheias de novo! Logo, logo eu reabro o armazém, querido.", "Full shelves again! Very soon I'll reopen the store, dear."),
    ],
    "tobias_idle_fed": [
        ("tobias", "A f-forja voltou a esquentar! Obrigado, Lio.", "The f-forge is warm again! Thank you, Lio."),
    ],
    "nina_idle_fed": [
        ("nina", "A vó fez bolo de trigo! Guardei um pedaço pra você.", "Grandma made a wheat cake! I saved you a piece."),
    ],
    "juca_idle_fed": [
        ("juca", "No meu tempo não tinha herói. Agora tem. Mudou pra melhor.", "Back in my day there were no heroes. Now there is one. Changed for the better."),
    ],
    "marta_idle": [
        ("marta", "Coma alguma coisa antes de sair. Mesmo que seja só pão duro.", "Eat something before you go. Even if it's just stale bread."),
    ],
    "marta_idle_bento": [
        ("marta", "O seu amigo lavou a louça e ainda fez sopa de quase nada. Gostei dele.", "Your friend washed the dishes and made soup out of almost nothing. I like him."),
    ],
    "bram_idle": [
        ("bram", "Guarda alta, pés firmes. E pare de sorrir no meio da luta, distrai.", "Guard up, feet steady. And stop grinning mid-fight, it's distracting."),
    ],
    "bento_idle_floresta": [
        ("bento", "Esse barulho foi um galho ou um orc? Diz que foi um galho.", "Was that noise a branch or an orc? Tell me it was a branch."),
    ],
    "bento_idle_vila": [
        ("bento", "Sabia que pão de farinha com saudade leva uma pitada de esperança? Receita secreta.", "Did you know flour-and-longing bread takes a pinch of hope? Secret recipe."),
    ],
    "celeste_idle": [
        ("celeste", "O armazém está quase vazio, querido. O tributo leva tudo antes de chegar às prateleiras.", "The store is nearly empty, dear. The tribute takes everything before it reaches the shelves."),
        ("celeste", "Quando a vila voltar a comer, eu volto a vender. Promessa.", "When the village eats again, I'll sell again. Promise."),
    ],
    "tobias_idle": [
        ("tobias", "A f-forja está fria. Um ferreiro sem fogo é só um homem com um m-martelo.", "The f-forge is cold. A smith without fire is just a man with a h-hammer."),
    ],
    "nina_idle": [
        ("nina", "Não conta para ninguém do trigo, tá?", "Don't tell anyone about the wheat, okay?"),
    ],
    "nina_idle_happy": [
        ("nina", "A vó parou de tossir! Ela disse que você é um herói. Eu disse que você é meio bobo, mas é herói.", "Grandma stopped coughing! She said you're a hero. I said you're a bit silly, but a hero."),
    ],
    "juca_idle": [
        ("juca", "No meu tempo o tributo era um saco de trigo por ano. Agora levam até o saco.", "Back in my day the tribute was one sack of wheat a year. Now they take the sack too."),
    ],
}

# key -> (pt_BR, en)
TEXTS = {
    "NPC_LIO": ("Lio", "Lio"),
    "NPC_MARTA": ("Marta", "Marta"),
    "NPC_BRAM": ("Mestre Bram", "Master Bram"),
    "NPC_BENTO": ("Bento", "Bento"),
    "NPC_SAHRA": ("Sahra", "Sahra"),
    "NPC_OSK": ("Osk", "Osk"),
    "NPC_BRUNHILD": ("Brunhild", "Brunhild"),
    "NPC_BRANNOC": ("Brannoc", "Brannoc"),
    "NPC_ELARION": ("Elarion", "Elarion"),
    "NPC_FAENOR": ("Faenor", "Faenor"),
    "NPC_VELYRA": ("Velyra", "Velyra"),
    "NPC_CELESTE": ("Dona Celeste", "Mrs. Celeste"),
    "NPC_TOBIAS": ("Tobias", "Tobias"),
    "NPC_NINA": ("Nina", "Nina"),
    "NPC_JUCA": ("Velho Juca", "Old Juca"),
    "NPC_ZAHIR": ("Zahir", "Zahir"),
    "NPC_NADIRA": ("Nadira", "Nadira"),
    "NPC_SEVERIN": ("Severin", "Severin"),
    "BARK_ZAHIR_1": ("Água fresquinha! Quase de graça!", "Fresh water! Almost free!"),
    "BARK_NADIRA_1": ("Cuidado com as faíscas.", "Mind the sparks."),
    "BARK_MARTA_1": ("Cuidado na estrada, filho!", "Careful on the road, son!"),
    "BARK_MARTA_2": ("Já comeu hoje?", "Have you eaten today?"),
    "BARK_BRAM_1": ("Guarda alta, moleque!", "Guard up, kid!"),
    "BARK_BRAM_2": ("Hmpf.", "Hmph."),
    "BARK_BENTO_1": ("Isso foi um orc?!", "Was that an orc?!"),
    "BARK_BENTO_2": ("Alguém aí tem sal?", "Anyone got salt?"),
    "BARK_CELESTE_1": ("Prateleiras vazias, coração cheio.", "Empty shelves, full heart."),
    "BARK_TOBIAS_1": ("F-forja fria...", "C-cold forge..."),
    "BARK_NINA_1": ("Psiu!", "Psst!"),
    "BARK_JUCA_1": ("Tributo, tributo...", "Tribute, tribute..."),
    "BARK_JUCA_2": ("No meu tempo...", "Back in my day..."),
    "QUEST_MAIN_01": ("Mais um dia em Pradoluz", "Another Day in Pradoluz"),
    "QUEST_MAIN_02": ("A lição do caolho", "The One-Eyed Lesson"),
    "QUEST_MAIN_03": ("Um cozinheiro na floresta", "A Cook in the Woods"),
    "QUEST_MAIN_07": ("A cidade da sede", "The Thirsty City"),
    "QUEST_MAIN_08": ("As Ruínas de Ammar", "The Ruins of Ammar"),
    "QUEST_MAIN_04": ("Os corvos da mina", "The Crows of the Mine"),
    "QUEST_MAIN_05": ("O Arauto da Colheita", "The Herald of the Harvest"),
    "QUEST_MAIN_06": ("Mais cinco desses", "Five More Like Him"),
    "QUEST_MORE_SOON": ("Fim do Ato 1 — a estrada do nordeste leva ao deserto de Qaressa", "End of Act 1 — the north-east road leads to the desert of Qaressa"),
    "QUEST_ACT2_SOON": ("Fale com a Nadira: as Ruínas de Ammar, a leste das dunas, estão abertas", "Talk to Nadira: the Ruins of Ammar, east of the dunes, are open"),
    "QUEST_ACT2_SOON2": ("Fale com a Nadira: o caminho para a Torre Afundada está aberto", "Talk to Nadira: the way to the Sunken Tower is open"),
    "QUEST_MAIN_09": ("A Arauta da Sede", "The Herald of Thirst"),
    "QUEST_MAIN_10": ("Rumo ao frio", "Into the Cold"),
    "QUEST_ACT3_SOON": ("Hrimvald precisa de você: os Picos Uivantes e a Mina de Gelo chegam na próxima versão", "Hrimvald needs you: the Howling Peaks and the Ice Mine arrive in the next version"),
    "QUEST_SIDE_MOVEIS": ("Os móveis do Osk", "Osk's Furniture"),
    "QUEST_MAIN_11": ("A mina debaixo da montanha", "The Mine Beneath the Mountain"),
    "QUEST_MAIN_12": ("O Arauto do Frio", "The Herald of Cold"),
    "QUEST_MAIN_13": ("A floresta em silêncio", "The Silent Forest"),
    "QUEST_MAIN_14": ("O vigia e o segredo", "The Watcher and the Secret"),
    "QUEST_MAIN_15": ("A Arauta do Silêncio", "The Herald of Silence"),
    "QUEST_MAIN_16": ("A Lei de Ferro", "The Iron Law"),
    "QUEST_MAIN_17": ("O portão e o juiz", "The Gate and the Judge"),
    "QUEST_ACT5_SOON3": ("A Escadaria do Céu e a Cidadela Celeste chegam na próxima versão", "The Stairway to the Sky and the Celestial Citadel arrive in the next version"),
    "OBJ_TALK_ISOLDA_PLAN": ("Fale com a Isolda sobre o plano", "Talk to Isolda about the plan"),
    "OBJ_TALK_SEVERIN_GATE": ("Fale com o cavaleiro no portão do castelo", "Talk to the knight at the castle gate"),
    "OBJ_FREE_PRISONERS": ("Derrote carcereiros e liberte os presos", "Defeat jailers and free the prisoners"),
    "OBJ_KILL_CASSIAN": ("Derrote o Cassian, Arauto da Lei", "Defeat Cassian, Herald of the Law"),
    "OBJ_TALK_ISOLDA_FREE": ("Fale com a Isolda em Altaréa", "Talk to Isolda in Altaréa"),
    "NPC_CASSIAN": ("Cassian", "Cassian"),
    "STO_CASSIAN_1": ("O Colosso se partiu em mil pedaços de luz dourada. No portão, o Severin ainda segurava a porta.", "The Colossus broke into a thousand pieces of golden light. At the gate, Severin was still holding the door."),
    "STO_CASSIAN_2": ("Ao amanhecer, Altaréa rasgou cada decreto. Pela primeira vez em anos, a praça riu alto.", "At dawn, Altaréa tore down every decree. For the first time in years, the square laughed out loud."),
    "STO_CASSIAN_3": ("E sobre o castelo surgiu uma escada de luz, subindo até a Cidadela Celeste. O caminho até o Vaelor estava aberto.", "And above the castle a stairway of light appeared, climbing up to the Celestial Citadel. The way to Vaelor was open."),
    "QUEST_ACT5_SOON2": ("O Castelo do Arauto e o Cassian chegam na próxima versão", "The Herald's Castle and Cassian arrive in the next version"),
    "QUEST_SIDE_DECRETOS": ("Decretos rasgados", "Torn Decrees"),
    "QUEST_SIDE_CORRENTES": ("Correntes partidas", "Broken Chains"),
    "OBJ_REACH_ROYAL_ROAD": ("Siga pelo portão leste de Lys'Thaël até a Estrada Real", "Take Lys'Thaël's east gate to the Royal Road"),
    "OBJ_KILL_LAW_GUARDS": ("Derrote guardas da Lei nos Arredores", "Defeat Law guards in the Outskirts"),
    "OBJ_REACH_ALTAREA": ("Entre em Altaréa, a capital", "Enter Altaréa, the capital"),
    "OBJ_TALK_ISOLDA": ("Encontre a Isolda perto da barricada", "Find Isolda near the barricade"),
    "OBJ_COLLECT_DECREES": ("Arranque decretos nos Arredores: %d/%d", "Tear down decrees in the Outskirts: %d/%d"),
    "OBJ_RETURN_AURELIO": ("Leve os decretos para o Aurélio", "Bring the decrees to Aurélio"),
    "OBJ_KILL_JAILERS": ("Derrote carcereiros nos Arredores", "Defeat jailers in the Outskirts"),
    "OBJ_RETURN_MATIAS": ("Leve as correntes para o Matias", "Bring the chains to Matias"),
    "ITEM_DECRETO": ("Decreto do Arauto", "Herald's decree"),
    "NPC_ISOLDA": ("Isolda", "Isolda"),
    "NPC_AURELIO": ("Aurélio", "Aurélio"),
    "NPC_MATIAS": ("Matias", "Matias"),
    "BARK_ISOLDA_1": ("Aqui não...", "Not here..."),
    "BARK_AURELIO_1": ("Entre, entre!", "Come in, come in!"),
    "BARK_MATIAS_1": ("Mais grilhões...", "More shackles..."),
    "QUEST_ACT5_SOON": ("Altaréa, a capital do Arauto Cassian, chega na próxima versão", "Altaréa, the capital of the Herald Cassian, arrives in the next version"),
    "OBJ_CLIMB_TOWER": ("Suba ao topo da Torre do Vigia", "Climb to the top of the Watcher's Tower"),
    "OBJ_KILL_VELYRA": ("Derrote a Velyra, Arauta do Silêncio", "Defeat Velyra, Herald of Silence"),
    "OBJ_TALK_ELARION_BLOOM": ("Fale com o Elarion sob a Árvore-Mãe", "Talk to Elarion under the Mother Tree"),
    "STO_VELYRA_1": ("Os espinhos da Dríade viraram pó. Velyra caiu de joelhos, e as flores roxas murcharam com ela.", "The Dryad's thorns turned to dust. Velyra fell to her knees, and the purple flowers withered with her."),
    "STO_VELYRA_2": ("Lá embaixo, uma onda de luz subiu pelas raízes da Árvore-Mãe. Os galhos cinzentos se encheram de flores.", "Far below, a wave of light rose through the roots of the Mother Tree. The grey branches filled with blossoms."),
    "STO_VELYRA_3": ("Naquela noite, Lys'Thaël cantou de novo. E ninguém pediu silêncio.", "That night, Lys'Thaël sang again. And no one asked for silence."),
    "QUEST_ACT4_SOON2": ("A escada para o topo da Torre do Vigia está livre: a Velyra chega na próxima versão", "The stairs to the top of the Watcher's Tower are clear: Velyra arrives in the next version"),
    "OBJ_TALK_FAENOR_SWAMP": ("Fale com o Faenor sobre o pântano", "Talk to Faenor about the swamp"),
    "OBJ_REACH_PANTANO": ("Entre no Pântano das Raízes, ao norte de Lys'Thaël", "Enter the Swamp of Roots, north of Lys'Thaël"),
    "OBJ_DUEL_SEVERIN_3": ("Enfrente o Severin na clareira diante da torre", "Face Severin in the clearing before the tower"),
    "OBJ_KILL_THORN_GUARDIAN": ("Derrote o Guardião de Espinhos na Torre do Vigia", "Defeat the Thorn Guardian in the Watcher's Tower"),
    "OBJ_TALK_BRAM_LYSTHAEL": ("Fale com o Mestre Bram em Lys'Thaël", "Talk to Master Bram in Lys'Thaël"),
    "STO_SEVERIN_1": ("Na beira da água, três crianças élficas cantavam baixinho. A Velyra ergueu o chicote de espinhos. Lio se jogou na frente.", "By the water, three elf children were singing softly. Velyra raised her whip of thorns. Lio threw himself in front of them."),
    "STO_SEVERIN_2": ("Severin ficou de joelhos na lama, olhando para as próprias mãos. Pela primeira vez, a ordem dos deuses pareceu errada.", "Severin knelt in the mud, staring at his own hands. For the first time, the gods' order seemed wrong."),
    "QUEST_ACT4_SOON": ("O portão norte de Lys'Thaël abriu: o Pântano das Raízes e a Torre do Vigia chegam na próxima versão", "Lys'Thaël's north gate is open: the Swamp of Roots and the Watcher's Tower arrive in the next version"),
    "QUEST_SIDE_CANTOS": ("Os cantos escondidos", "The Hidden Songs"),
    "QUEST_SIDE_LAMINA": ("Lâmina de raiz", "Root Blade"),
    "OBJ_REACH_LYSTHAEL": ("Chegue a Lys'Thaël: Picos (leste) → Vale do Degelo → Mata Úmida → Bordas do Pântano", "Reach Lys'Thaël: Peaks (east) → Thaw Valley → Damp Woods → Swamp's Edge"),
    "OBJ_TALK_ELARION": ("Fale com o Elarion", "Talk to Elarion"),
    "OBJ_KILL_CULTISTS": ("Derrote cultistas nas Bordas do Pântano: %d/%d", "Defeat cultists at the Swamp's Edge: %d/%d"),
    "OBJ_TALK_FAENOR": ("Fale com o Faenor", "Talk to Faenor"),
    "OBJ_COLLECT_SONGS": ("Encontre partituras na Mata Úmida: %d/%d", "Find sheet music in the Damp Woods: %d/%d"),
    "OBJ_RETURN_ELARION": ("Leve as partituras para o Elarion", "Bring the sheet music to Elarion"),
    "OBJ_KILL_SWAMP_DEAD": ("Derrote mortos do pântano: %d/%d", "Defeat swamp dead: %d/%d"),
    "OBJ_RETURN_FAENOR": ("Volte para o Faenor", "Go back to Faenor"),
    "ITEM_PARTITURA": ("Partitura antiga", "Ancient sheet music"),
    "BARK_ELARION_1": ("Psiu...", "Shh..."),
    "BARK_FAENOR_1": ("Hmm.", "Hmm."),
    "QUEST_ACT3_DONE": ("Fim do Ato 3 — Hrimvald está aquecida. O Ato 4 (Lys'Thaël) vem nas próximas versões", "End of Act 3 — Hrimvald is warm again. Act 4 (Lys'Thaël) comes in the next versions"),
    "OBJ_TALK_BENTO_CASTLE": ("Fale com o Bento", "Talk to Bento"),
    "OBJ_REACH_CASTELO": ("Suba ao Castelo Ermo pelo túnel no fundo da Mina de Gelo", "Climb to the Lonely Castle through the tunnel at the bottom of the Ice Mine"),
    "OBJ_KILL_BRANNOC": ("Derrote o Brannoc, Arauto do Frio", "Defeat Brannoc, Herald of Cold"),
    "OBJ_TALK_OSK_AFTER": ("Fale com o Velho Osk em Hrimvald", "Talk to Old Osk in Hrimvald"),
    "STO_BENTO_1": ("No último golpe do gigante, Lio caiu na neve. E Bento, que tinha medo até de lagartixa, correu para a frente dele.", "With the giant's last blow, Lio fell in the snow. And Bento, who was afraid of even a lizard, ran in front of him."),
    "STO_BENTO_2": ("\"Não chora, Lio... come direito, tá? E guarda o meu cachecol.\" O gelo do Arauto se partiu. O coração de Bento parou.", "\"Don't cry, Lio... eat properly, okay? And keep my scarf.\" The Herald's ice shattered. Bento's heart stopped."),
    "STO_BENTO_3": ("Naquela noite, todas as chaminés de Hrimvald voltaram a soltar fumaça. Só uma panela ficou fria, ao pé de uma cruz na colina.", "That night, every chimney in Hrimvald smoked again. Only one pot stayed cold, at the foot of a cross on the hill."),
    "STO_BENTO_4": ("Lio subiu as montanhas sozinho. Treinou com a neve, com o sol e com as folhas caindo. Nunca mais seria lento demais.", "Lio climbed the mountains alone. He trained through snow, sun and falling leaves. He would never be too slow again."),
    "STO_BENTO_LATER": ("Dois anos depois...", "Two years later..."),
    "QUEST_ACT3_SOON2": ("O túnel para o Castelo Ermo está aberto: o Brannoc chega na próxima versão", "The tunnel to the Lonely Castle is open: Brannoc arrives in the next version"),
    "OBJ_TALK_BRUNHILD_CASTLE": ("Pergunte à Brunhild como chegar ao castelo", "Ask Brunhild how to reach the castle"),
    "OBJ_REACH_PICOS": ("Suba aos Picos Uivantes, ao norte de Hrimvald", "Climb the Howling Peaks, north of Hrimvald"),
    "OBJ_DUEL_SEVERIN_2": ("Enfrente o Severin na crista", "Face Severin on the ridge"),
    "OBJ_KILL_ICE_GUARDIAN": ("Derrote o Guardião de Gelo no fundo da Mina de Gelo", "Defeat the Ice Guardian deep in the Ice Mine"),
    "OBJ_RETURN_BENTO_HRIMVALD": ("Volte para o Bento em Hrimvald", "Go back to Bento in Hrimvald"),
    "QUEST_SIDE_CARVAO": ("Carvão roubado", "Stolen Coal"),
    "OBJ_TALK_NADIRA_NORTH": ("Fale com a Nadira sobre o norte", "Talk to Nadira about the north"),
    "OBJ_REACH_HRIMVALD": ("Chegue a Hrimvald: Dunas (oeste) → Deserto Rochoso → Planalto Frio → Pinheiral", "Reach Hrimvald: Dunes (west) → Rocky Desert → Cold Highlands → Pine Woods"),
    "OBJ_TALK_OSK": ("Fale com o Velho Osk", "Talk to Old Osk"),
    "OBJ_KILL_FROZEN": ("Derrote mortos congelados no Pinheiral: %d/%d", "Defeat frozen dead in the Pine Woods: %d/%d"),
    "OBJ_RETURN_OSK": ("Volte para o Velho Osk", "Go back to Old Osk"),
    "OBJ_COLLECT_BRANCHES": ("Recolha galhos secos no Pinheiral: %d/%d", "Gather dry branches in the Pine Woods: %d/%d"),
    "OBJ_RETURN_OSK_WOOD": ("Leve os galhos para o Osk", "Bring the branches to Osk"),
    "OBJ_KILL_SNOW_ORCS": ("Derrote orcs da neve no Planalto Frio: %d/%d", "Defeat snow orcs on the Cold Highlands: %d/%d"),
    "OBJ_RETURN_BRUNHILD": ("Volte para a Brunhild", "Go back to Brunhild"),
    "ITEM_GALHO_SECO": ("Feixe de galhos secos", "Bundle of dry branches"),
    "BARK_OSK_1": ("Brrr...", "Brrr..."),
    "BARK_BRUNHILD_1": ("Clang!", "Clang!"),
    "QUEST_ACT2_DONE": ("Fim do Ato 2 — os poços de Qaressa estão abertos. O Ato 3 vem nas próximas versões", "End of Act 2 — Qaressa's wells are open. Act 3 comes in the next versions"),
    "OBJ_TALK_NADIRA_TOWER": ("Pergunte à Nadira sobre a Torre Afundada", "Ask Nadira about the Sunken Tower"),
    "OBJ_REACH_TOWER": ("Chegue à Torre Afundada, a leste das Ruínas", "Reach the Sunken Tower, east of the Ruins"),
    "OBJ_KILL_SAHRA": ("Derrote a Arauta Sahra no pátio da torre", "Defeat Herald Sahra in the tower court"),
    "OBJ_RETURN_NADIRA_TOWER": ("Volte para a Nadira em Qaressa", "Go back to Nadira in Qaressa"),
    "OBJ_KILL_GOLEM": ("Derrote o Golem de pedra no fundo da mina", "Defeat the stone golem in the depths of the mine"),
    "OBJ_KILL_GORVAN": ("Derrote Gorvan no Celeiro do Tributo", "Defeat Gorvan in the Tribute Granary"),
    "OBJ_RETURN_VILLAGE": ("Volte para a Marta em Pradoluz", "Return to Marta in Pradoluz"),
    "OBJ_TALK_BRAM_END": ("Converse com o Bram", "Talk to Bram"),
    "OBJ_TALK_BENTO_END": ("Converse com o Bento", "Talk to Bento"),
    "QUEST_SIDE_TRIGO": ("Trigo escondido", "Hidden Wheat"),
    "QUEST_SIDE_FERRO": ("O ferro do Tobias", "Tobias's Iron"),
    "QUEST_SIDE_JUCA": ("O sítio do Juca", "Juca's Farm"),
    "QUEST_SIDE_FARINHA": ("A farinha da Celeste", "Celeste's Flour"),
    "QUEST_SIDE_ESTRADA": ("A estrada do nordeste", "The North-East Road"),
    "QUEST_SIDE_ACO": ("O aço roubado", "The Stolen Steel"),
    "QUEST_SIDE_TEMPERO": ("Tempero da estepe", "Steppe Seasoning"),
    "OBJ_TALK_MARTA": ("Fale com a Marta", "Talk to Marta"),
    "OBJ_TALK_BRAM": ("Encontre o Mestre Bram no treino", "Meet Master Bram at training"),
    "OBJ_KILL_BANDIDOS": ("Derrote bandidos na floresta: %d/%d", "Defeat bandits in the forest: %d/%d"),
    "OBJ_RETURN_BRAM": ("Volte ao Mestre Bram", "Return to Master Bram"),
    "OBJ_FIND_BENTO": ("Encontre o homem na clareira da floresta", "Find the man in the forest clearing"),
    "OBJ_KILL_ORCS_BENTO": ("Derrote os orcs da clareira: %d/%d", "Defeat the clearing orcs: %d/%d"),
    "OBJ_TALK_BENTO": ("Fale com o Bento", "Talk to Bento"),
    "OBJ_BENTO_TO_MARTA": ("Leve o Bento até a Marta", "Bring Bento to Marta"),
    "OBJ_ASK_BRAM_MINE": ("Pergunte ao Bram sobre a mina", "Ask Bram about the mine"),
    "OBJ_REACH_MINE": ("Chegue à Mina dos Corvos", "Reach the Crow Mine"),
    "OBJ_MINE_DEEP": ("Explore o fundo da mina", "Explore the depths of the mine"),
    "OBJ_COLLECT_HERBS": ("Colha erva-de-orvalho na floresta: %d/%d", "Gather dewleaf in the forest: %d/%d"),
    "OBJ_RETURN_NINA": ("Leve as ervas para a Nina", "Bring the herbs to Nina"),
    "OBJ_KILL_ORCS": ("Derrote orcs na floresta: %d/%d", "Defeat orcs in the forest: %d/%d"),
    "OBJ_FIND_IRON": ("Ache o caixote de ferro na trilha norte", "Find the iron crate on the north trail"),
    "OBJ_RETURN_TOBIAS": ("Devolva o ferro ao Tobias", "Return the iron to Tobias"),
    "OBJ_KILL_FARM_BANDITS": ("Expulse os bandidos do sítio nos Campos: %d/%d", "Drive the bandits off the farm in the Fields: %d/%d"),
    "OBJ_FIND_HORSESHOE": ("Ache a ferradura da sorte perto da carroça", "Find the lucky horseshoe by the cart"),
    "OBJ_RETURN_JUCA": ("Leve a ferradura para o Velho Juca", "Bring the horseshoe to Old Juca"),
    "OBJ_COLLECT_FLOUR": ("Recolha os sacos de farinha nos Campos: %d/%d", "Pick up the flour sacks in the Fields: %d/%d"),
    "OBJ_RETURN_CELESTE": ("Leve a farinha para a Dona Celeste", "Bring the flour to Mrs. Celeste"),
    "OBJ_KILL_ROAD_BANDITS": ("Derrote bandidos da estrada no Bosque Seco: %d/%d", "Defeat road bandits in the Withered Grove: %d/%d"),
    "OBJ_RETURN_BRAM": ("Volte ao Mestre Bram", "Go back to Master Bram"),
    "OBJ_REACH_QARESSA": ("Atravesse as Dunas de Ossos até Qaressa", "Cross the Bone Dunes to Qaressa"),
    "OBJ_TALK_ZAHIR": ("Fale com Zahir no mercado", "Talk to Zahir at the market"),
    "OBJ_TALK_NADIRA": ("Fale com Nadira, a ferreira", "Talk to Nadira, the blacksmith"),
    "OBJ_KILL_LIZARDMEN": ("Derrote homens-lagarto nas Dunas: %d/%d", "Defeat lizardmen in the Dunes: %d/%d"),
    "OBJ_RETURN_NADIRA": ("Leve as escamas para a Nadira", "Bring the scales to Nadira"),
    "OBJ_TALK_NADIRA_RUINS": ("Pergunte à Nadira sobre as ruínas", "Ask Nadira about the ruins"),
    "OBJ_KILL_ANCIENT": ("Derrote esqueletos antigos nas Ruínas: %d/%d", "Defeat ancient skeletons in the Ruins: %d/%d"),
    "OBJ_REACH_MURAL": ("Encontre o mural do templo, ao norte das Ruínas", "Find the temple mural, north of the Ruins"),
    "OBJ_DUEL_SEVERIN": ("Enfrente o cavaleiro no templo", "Face the knight in the temple"),
    "OBJ_RETURN_NADIRA_RUINS": ("Volte para a Nadira em Qaressa", "Go back to Nadira in Qaressa"),
    "OBJ_KILL_RAIDERS": ("Derrote orcs saqueadores no Bosque Seco: %d/%d", "Defeat orc raiders in the Withered Grove: %d/%d"),
    "OBJ_COLLECT_STEEL": ("Recupere os caixotes de aço no acampamento: %d/%d", "Recover the steel crates at the camp: %d/%d"),
    "OBJ_RETURN_TOBIAS_STEEL": ("Leve o aço para o Tobias", "Bring the steel to Tobias"),
    "OBJ_COLLECT_SAGE": ("Colha sálvia-de-pedra na Estepe: %d/%d", "Gather stone sage on the Steppe: %d/%d"),
    "OBJ_RETURN_BENTO": ("Leve a sálvia para o Bento", "Bring the sage to Bento"),
    # Prólogo (um texto por ilustração, na ordem) e tela inicial
    "PRO_1": ("Há dezenove invernos, em Pradoluz, uma vila de fazendeiros esquecida pelo resto do mundo...", "Nineteen winters ago, in Pradoluz, a farming village the rest of the world had forgotten..."),
    "PRO_2": ("...nasceu um menino. E ele brilhava.", "...a boy was born. And he shone."),
    "PRO_3": ("A luz dourada iluminou a vila inteira, como se o sol tivesse nascido no meio da noite.", "The golden light lit up the whole village, as if the sun had risen in the middle of the night."),
    "PRO_4": ("O pai, Doran, olhou para o filho, depois para a casa pobre... e fugiu pela neve.", "His father, Doran, looked at his son, then at their poor house... and ran into the snow."),
    "PRO_5": ("Na manhã seguinte, só acharam pegadas de lobo e a luva dele, rasgada, com um dedo dentro. Disseram que os lobos o levaram.", "The next morning they found only wolf tracks and his torn glove, with a finger inside. They said the wolves had taken him."),
    "PRO_6": ("Mas, no meio da tempestade, alguém sem rosto o esperava. \"Você nunca mais vai ter medo.\"", "But in the heart of the storm, someone without a face was waiting. \"You will never be afraid again.\""),
    "PRO_7": ("Meses depois, um homem alado surgiu nos céus de Varenthia e se declarou deus. Cinco Arautos passaram a governar em seu nome.", "Months later, a winged man appeared in the skies of Varenthia and declared himself a god. Five Heralds began to rule in his name."),
    "PRO_8": ("E, do alto de sua torre, o deus olhava para o sul. Para Pradoluz. Preocupado.", "And from the top of his tower, the god looked south. Toward Pradoluz. Worried."),
    "PRO_LATER": ("Dezenove anos depois...", "Nineteen years later..."),
    "PRO_SKIP": ("Pular", "Skip"),
    "TITLE_GAME": ("Herdeiro dos Céus", "Heir of the Skies"),
    "TITLE_CONTINUE": ("Continuar", "Continue"),
    "TITLE_NEW": ("Novo jogo", "New game"),
    "TITLE_QUIT": ("Sair", "Quit"),
    "TITLE_SAVE_INFO": ("Lio · Nv. %d · %s", "Lio · Lv. %d · %s"),
    "TITLE_CONFIRM_NEW": ("Começar de novo apaga o jogo salvo. Tem certeza?", "Starting over erases your saved game. Are you sure?"),
    "TITLE_OPTIONS": ("Opções", "Options"),
    "OPT_TITLE": ("Opções", "Options"),
    "OPT_MUSIC": ("Música", "Music"),
    "OPT_SFX": ("Efeitos", "Effects"),
    "OPT_VOICE": ("Vozes", "Voices"),
    "OPT_CREDITS": ("Créditos", "Credits"),
    "OPT_MENU": ("Opções", "Options"),
    "OPT_SHOW_FPS": ("Mostrar quadros por segundo", "Show frames per second"),
    "OPT_FPS_LIMIT": ("Limite de quadros", "Frame limit"),
    "OPT_ON": ("Ligado", "On"),
    "OPT_OFF": ("Desligado", "Off"),
    "OPT_CREDITS_TEXT": (
        "Música (CC-BY 3.0), série RPG Orchestral Essentials: \"A Dream of First Flight\", \"Visions of Freedom\", "
        "\"Morning Frost\", \"The World At Your Door\", \"A Bitter Hope\", \"A Slave To No One\" e \"Can't Stop Winning\" "
        "Composed by Jonathan Shaw (www.jshaw.co.uk).\n"
        "Efeitos sonoros (CC0): Kenney (www.kenney.nl), artisticdude e rubberduck (opengameart.org).\n"
        "Modelos, interface e ilustrações gerados com Meshy. Fonte: Open Sans (OFL).",
        "Music (CC-BY 3.0), RPG Orchestral Essentials series: \"A Dream of First Flight\", \"Visions of Freedom\", "
        "\"Morning Frost\", \"The World At Your Door\", \"A Bitter Hope\", \"A Slave To No One\" and \"Can't Stop Winning\" "
        "Composed by Jonathan Shaw (www.jshaw.co.uk).\n"
        "Sound effects (CC0): Kenney (www.kenney.nl), artisticdude and rubberduck (opengameart.org).\n"
        "Models, interface and illustrations made with Meshy. Font: Open Sans (OFL).",
    ),
    "TITLE_YES": ("Sim, começar de novo", "Yes, start over"),
    "TITLE_NO": ("Voltar", "Back"),
    # Itens da mochila (etapa 5.1)
    "ITEM_POT_VIDA_P": ("Poção de vida pequena", "Small health potion"),
    "ITEM_POT_VIDA_M": ("Poção de vida média", "Medium health potion"),
    "ITEM_POT_VIDA_G": ("Poção de vida grande", "Large health potion"),
    "ITEM_POT_VIDA_DESC": ("Recupera vida aos poucos, em 2 segundos.", "Restores health over 2 seconds."),
    "ITEM_POT_FOLEGO_P": ("Poção de fôlego pequena", "Small stamina potion"),
    "ITEM_POT_FOLEGO_M": ("Poção de fôlego média", "Medium stamina potion"),
    "ITEM_POT_FOLEGO_G": ("Poção de fôlego grande", "Large stamina potion"),
    "ITEM_POT_FOLEGO_DESC": ("Recupera o fôlego para esquivas e skills.", "Restores stamina for dodges and skills."),
    "ITEM_POT_FORCA": ("Tônico da força", "Tonic of strength"),
    "ITEM_POT_FORCA_DESC": ("+20% de ataque por 90 segundos.", "+20% attack for 90 seconds."),
    "ITEM_POT_PEDRA": ("Tônico da pedra", "Tonic of stone"),
    "ITEM_POT_PEDRA_DESC": ("+25% de defesa por 90 segundos.", "+25% defense for 90 seconds."),
    "ITEM_POT_VENTO": ("Tônico do vento", "Tonic of wind"),
    "ITEM_POT_VENTO_DESC": ("+15% de velocidade de movimento e de ataque por 90 segundos.", "+15% movement and attack speed for 90 seconds."),
    "ITEM_MAT_DESC": ("Material de criação. O ferreiro usa para forjar e fortalecer equipamentos.", "Crafting material. The blacksmith uses it to forge and strengthen gear."),
    "ITEM_TREVO": ("Trevo de Fortificação", "Fortification Clover"),
    "ITEM_TREVO_DESC": ("Aumenta a chance de fortalecer um equipamento no ferreiro.", "Raises the chance of strengthening gear at the blacksmith."),
    "ITEM_TREVO_REAL": ("Trevo Real", "Royal Clover"),
    "ITEM_TREVO_REAL_DESC": ("O fortalecimento dá certo sempre.", "Strengthening always succeeds."),
    "ITEM_BROCA": ("Broca de Engaste", "Socket Drill"),
    "ITEM_BROCA_DESC": ("Tenta abrir um encaixe para gema num equipamento.", "Tries to open a gem socket on a piece of gear."),
    "ITEM_BROCA_REAL": ("Broca Real", "Royal Drill"),
    "ITEM_BROCA_REAL_DESC": ("Abre um encaixe sempre (até 3).", "Always opens a socket (up to 3)."),
    "ITEM_AMULETO": ("Amuleto de Proteção", "Protection Amulet"),
    "ITEM_AMULETO_DESC": ("Se o fortalecimento falhar, o equipamento não quebra nem some.", "If strengthening fails, the gear neither breaks nor vanishes."),
    "ITEM_ERVA_ORVALHO": ("Erva-de-orvalho", "Dewleaf"),
    "ITEM_CAIXOTE_FERRO": ("Caixote de ferro", "Iron crate"),
    "ITEM_FERRADURA_SORTE": ("Ferradura da sorte", "Lucky horseshoe"),
    "ITEM_SACO_FARINHA": ("Saco de farinha", "Sack of flour"),
    "ITEM_CAIXOTE_ACO": ("Caixote de aço", "Steel crate"),
    "ITEM_SALVIA_PEDRA": ("Sálvia-de-pedra", "Stone sage"),
    "ITEM_EQ_ESPADA_APRENDIZ": ("Espada de aprendiz", "Apprentice sword"),
    "ITEM_EQ_ESPADA_COMUM": ("Espada de ferro", "Iron sword"),
    "ITEM_EQ_ELMO_COMUM": ("Elmo de ferro", "Iron helmet"),
    "ITEM_EQ_PEITORAL_COMUM": ("Colete de couro", "Leather vest"),
    "ITEM_EQ_LUVAS_COMUM": ("Luvas de couro", "Leather gloves"),
    "ITEM_EQ_CALCA_COMUM": ("Calça reforçada", "Padded trousers"),
    "ITEM_EQ_BOTAS_COMUM": ("Botas de couro", "Leather boots"),
    "ITEM_EQ_PULSEIRA_COMUM": ("Pulseira de couro", "Leather bracelet"),
    "ITEM_EQ_CINTO_COMUM": ("Cinto de couro", "Leather belt"),
    "ITEM_EQ_ESPADA_RARO": ("Espada de aço", "Steel sword"),
    "ITEM_EQ_ELMO_RARO": ("Elmo de aço", "Steel helmet"),
    "ITEM_EQ_PEITORAL_RARO": ("Peitoral de aço", "Steel breastplate"),
    "ITEM_EQ_LUVAS_RARO": ("Manoplas de aço", "Steel gauntlets"),
    "ITEM_EQ_CALCA_RARO": ("Calça de placas", "Plated trousers"),
    "ITEM_EQ_BOTAS_RARO": ("Botas de aço", "Steel boots"),
    "ITEM_EQ_PULSEIRA_RARO": ("Pulseira de aço", "Steel bracelet"),
    "ITEM_EQ_CINTO_RARO": ("Cinto de placas", "Plated belt"),
    "ITEM_EQ_ESPADA_EPICO": ("Espada rúnica", "Runic sword"),
    "ITEM_EQ_ELMO_EPICO": ("Elmo rúnico", "Runic helmet"),
    "ITEM_EQ_PEITORAL_EPICO": ("Peitoral rúnico", "Runic breastplate"),
    "ITEM_EQ_LUVAS_EPICO": ("Garras rúnicas", "Runic claws"),
    "ITEM_EQ_CALCA_EPICO": ("Calça rúnica", "Runic trousers"),
    "ITEM_EQ_BOTAS_EPICO": ("Botas rúnicas", "Runic boots"),
    "ITEM_EQ_PULSEIRA_EPICO": ("Pulseira rúnica", "Runic bracelet"),
    "ITEM_EQ_CINTO_EPICO": ("Cinto rúnico", "Runic belt"),
    "ITEM_EQ_ESPADA_LENDARIO": ("Espada do Sol Alado", "Winged Sun Sword"),
    "ITEM_EQ_ELMO_LENDARIO": ("Elmo do Sol Alado", "Winged Sun Helmet"),
    "ITEM_EQ_PEITORAL_LENDARIO": ("Peitoral do Sol Alado", "Winged Sun Breastplate"),
    "ITEM_EQ_LUVAS_LENDARIO": ("Manoplas do Sol Alado", "Winged Sun Gauntlets"),
    "ITEM_EQ_CALCA_LENDARIO": ("Calça do Sol Alado", "Winged Sun Trousers"),
    "ITEM_EQ_BOTAS_LENDARIO": ("Botas do Sol Alado", "Winged Sun Boots"),
    "ITEM_EQ_PULSEIRA_LENDARIO": ("Pulseira do Sol Alado", "Winged Sun Bracelet"),
    "ITEM_EQ_CINTO_LENDARIO": ("Cinto do Sol Alado", "Winged Sun Belt"),
    "ITEM_EQ_ESPADA_MITICO": ("Espada da Chama Rubra", "Crimson Flame Sword"),
    "ITEM_EQ_ELMO_MITICO": ("Elmo da Chama Rubra", "Crimson Flame Helmet"),
    "ITEM_EQ_PEITORAL_MITICO": ("Peitoral da Chama Rubra", "Crimson Flame Breastplate"),
    "ITEM_EQ_LUVAS_MITICO": ("Manoplas da Chama Rubra", "Crimson Flame Gauntlets"),
    "ITEM_EQ_CALCA_MITICO": ("Calça da Chama Rubra", "Crimson Flame Trousers"),
    "ITEM_EQ_BOTAS_MITICO": ("Botas da Chama Rubra", "Crimson Flame Boots"),
    "ITEM_EQ_PULSEIRA_MITICO": ("Pulseira da Chama Rubra", "Crimson Flame Bracelet"),
    "ITEM_EQ_CINTO_MITICO": ("Cinto da Chama Rubra", "Crimson Flame Belt"),
    "ITEM_EQ_ESPADA_CELESTIAL": ("Espada do Herdeiro Celeste", "Celestial Heir Sword"),
    "ITEM_EQ_ELMO_CELESTIAL": ("Elmo do Herdeiro Celeste", "Celestial Heir Helmet"),
    "ITEM_EQ_PEITORAL_CELESTIAL": ("Peitoral do Herdeiro Celeste", "Celestial Heir Breastplate"),
    "ITEM_EQ_LUVAS_CELESTIAL": ("Manoplas do Herdeiro Celeste", "Celestial Heir Gauntlets"),
    "ITEM_EQ_CALCA_CELESTIAL": ("Calça do Herdeiro Celeste", "Celestial Heir Trousers"),
    "ITEM_EQ_BOTAS_CELESTIAL": ("Botas do Herdeiro Celeste", "Celestial Heir Boots"),
    "ITEM_EQ_PULSEIRA_CELESTIAL": ("Pulseira do Herdeiro Celeste", "Celestial Heir Bracelet"),
    "ITEM_EQ_CINTO_CELESTIAL": ("Cinto do Herdeiro Celeste", "Celestial Heir Belt"),
    "ITEM_EQ_MITICO_DESC": ("O metal ainda pulsa como brasa viva.", "The metal still pulses like a living ember."),
    "ITEM_EQ_CELESTIAL_DESC": ("Forjada para quem ousa desafiar os céus.", "Forged for those who dare to defy the heavens."),
    "ITEM_MAT_INSIGNIA_CHEFE": ("Insígnia de Chefe", "Boss Insignia"),
    "ITEM_MAT_INSIGNIA_CHEFE_DESC": ("Cai dos chefes das masmorras. O ferreiro pede 10 para cada peça épica ou melhor.", "Dropped by dungeon bosses. The smith asks for 10 for each epic or better piece."),
    "ITEM_EQ_ESPADA_APRENDIZ_DESC": ("A espada de treino que o Mestre Bram te deu.", "The training sword Master Bram gave you."),
    "ITEM_EQ_COMUM_DESC": ("Peça simples, feita por qualquer ferreiro.", "A simple piece any smith can make."),
    "ITEM_EQ_RARO_DESC": ("Aço bem trabalhado, com detalhes azuis.", "Well-worked steel with blue trims."),
    "ITEM_EQ_EPICO_DESC": ("Runas antigas brilham no metal escuro.", "Ancient runes glow on the dark metal."),
    "ITEM_EQ_LENDARIO_DESC": ("Dizem que foi forjada com a luz do céu.", "They say it was forged with the light of the sky."),
    "ITEM_MAT_LINGOTE_ACO": ("Lingote de aço", "Steel ingot"),
    "ITEM_MAT_SEDA_DESERTO": ("Seda do deserto", "Desert silk"),
    "ITEM_MAT_FRAGMENTO_RUINA": ("Fragmento de ruína", "Ruin shard"),
    "ITEM_MAT_ESCAMA_DUNA": ("Escama de duna", "Dune scale"),
    "ITEM_MAT_CRISTAL_AREIA": ("Cristal de areia", "Sand crystal"),
    "ITEM_MAT_PELE_NEVE": ("Pele da neve", "Snow pelt"),
    "ITEM_MAT_CRISTAL_GELO": ("Cristal de gelo", "Ice crystal"),
    "ITEM_MAT_ESCAMA_PANTANO": ("Escama do pântano", "Swamp scale"),
    "ITEM_MAT_SEIVA_AMARGA": ("Seiva amarga", "Bitter sap"),
    "ITEM_MAT_SELO_LEI": ("Selo da Lei", "Seal of the Law"),
    "ITEM_MAT_CORRENTE": ("Corrente de ferro", "Iron chain"),
    "ITEM_MAT_LINGOTE_ACO_DESC": ("O ferreiro usa para fortalecer e restaurar equipamentos.", "The smith uses it to strengthen and restore gear."),
    "ITEM_GEMA_RUBI_1": ("Rubi I", "Ruby I"),
    "ITEM_GEMA_RUBI_2": ("Rubi II", "Ruby II"),
    "ITEM_GEMA_RUBI_3": ("Rubi III", "Ruby III"),
    "ITEM_GEMA_RUBI_4": ("Rubi IV", "Ruby IV"),
    "ITEM_GEMA_RUBI_5": ("Rubi V", "Ruby V"),
    "ITEM_GEMA_RUBI_DESC": ("Num encaixe de equipamento, aumenta ataque. Três iguais viram uma do nível seguinte no ferreiro.", "In a gear socket, raises attack. Three of a kind become one of the next tier at the smith."),
    "ITEM_GEMA_SAFIRA_1": ("Safira I", "Sapphire I"),
    "ITEM_GEMA_SAFIRA_2": ("Safira II", "Sapphire II"),
    "ITEM_GEMA_SAFIRA_3": ("Safira III", "Sapphire III"),
    "ITEM_GEMA_SAFIRA_4": ("Safira IV", "Sapphire IV"),
    "ITEM_GEMA_SAFIRA_5": ("Safira V", "Sapphire V"),
    "ITEM_GEMA_SAFIRA_DESC": ("Num encaixe de equipamento, aumenta vida. Três iguais viram uma do nível seguinte no ferreiro.", "In a gear socket, raises health. Three of a kind become one of the next tier at the smith."),
    "ITEM_GEMA_ESMERALDA_1": ("Esmeralda I", "Emerald I"),
    "ITEM_GEMA_ESMERALDA_2": ("Esmeralda II", "Emerald II"),
    "ITEM_GEMA_ESMERALDA_3": ("Esmeralda III", "Emerald III"),
    "ITEM_GEMA_ESMERALDA_4": ("Esmeralda IV", "Emerald IV"),
    "ITEM_GEMA_ESMERALDA_5": ("Esmeralda V", "Emerald V"),
    "ITEM_GEMA_ESMERALDA_DESC": ("Num encaixe de equipamento, aumenta chance de crítico. Três iguais viram uma do nível seguinte no ferreiro.", "In a gear socket, raises crit chance. Three of a kind become one of the next tier at the smith."),
    "ITEM_GEMA_TOPAZIO_1": ("Topázio I", "Topaz I"),
    "ITEM_GEMA_TOPAZIO_2": ("Topázio II", "Topaz II"),
    "ITEM_GEMA_TOPAZIO_3": ("Topázio III", "Topaz III"),
    "ITEM_GEMA_TOPAZIO_4": ("Topázio IV", "Topaz IV"),
    "ITEM_GEMA_TOPAZIO_5": ("Topázio V", "Topaz V"),
    "ITEM_GEMA_TOPAZIO_DESC": ("Num encaixe de equipamento, aumenta recarga das skills. Três iguais viram uma do nível seguinte no ferreiro.", "In a gear socket, raises skill cooldown. Three of a kind become one of the next tier at the smith."),
    "ITEM_GEMA_AMETISTA_1": ("Ametista I", "Amethyst I"),
    "ITEM_GEMA_AMETISTA_2": ("Ametista II", "Amethyst II"),
    "ITEM_GEMA_AMETISTA_3": ("Ametista III", "Amethyst III"),
    "ITEM_GEMA_AMETISTA_4": ("Ametista IV", "Amethyst IV"),
    "ITEM_GEMA_AMETISTA_5": ("Ametista V", "Amethyst V"),
    "ITEM_GEMA_AMETISTA_DESC": ("Num encaixe de equipamento, aumenta defesa. Três iguais viram uma do nível seguinte no ferreiro.", "In a gear socket, raises defense. Three of a kind become one of the next tier at the smith."),
}

PREFIXES = ("DLG_", "BARK_", "NPC_", "QUEST_", "OBJ_", "ITEM_", "PRO_", "TITLE_", "OPT_")


def main() -> None:
    dialogues = {}
    texts = dict(TEXTS)
    for did, lines in DIALOGUES.items():
        out = []
        for i, (speaker, pt, en) in enumerate(lines, 1):
            key = f"DLG_{did.upper()}_{i}"
            texts[key] = (pt, en)
            out.append([speaker, key])
        dialogues[did] = {"lines": out}

    dpath = ROOT / "data" / "dialogues" / "act1.json"
    dpath.parent.mkdir(parents=True, exist_ok=True)
    doc = {"_comment": "Gerado por tools/content/gen_act1_text.py. Não editar à mão.", "dialogues": dialogues}
    dpath.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    cpath = ROOT / "data" / "i18n" / "strings.csv"
    rows = list(csv.reader(io.StringIO(cpath.read_text(encoding="utf-8"))))
    header, body = rows[0], [r for r in rows[1:] if r and not r[0].startswith(PREFIXES)]
    for key, (pt, en) in texts.items():
        # Line breaks go in the CSV as the two characters \n (the game turns them back).
        body.append([key, pt.replace("\n", "\\n"), en.replace("\n", "\\n")])
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(header)
    w.writerows(body)
    cpath.write_text(buf.getvalue(), encoding="utf-8")
    print(f"ok: {len(dialogues)} diálogos, {len(texts)} textos")


if __name__ == "__main__":
    main()
