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
    "NPC_CELESTE": ("Dona Celeste", "Mrs. Celeste"),
    "NPC_TOBIAS": ("Tobias", "Tobias"),
    "NPC_NINA": ("Nina", "Nina"),
    "NPC_JUCA": ("Velho Juca", "Old Juca"),
    "NPC_ZAHIR": ("Zahir", "Zahir"),
    "NPC_NADIRA": ("Nadira", "Nadira"),
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
    "QUEST_MAIN_04": ("Os corvos da mina", "The Crows of the Mine"),
    "QUEST_MAIN_05": ("O Arauto da Colheita", "The Herald of the Harvest"),
    "QUEST_MAIN_06": ("Mais cinco desses", "Five More Like Him"),
    "QUEST_MORE_SOON": ("Fim do Ato 1 — a estrada do nordeste leva ao deserto de Qaressa", "End of Act 1 — the north-east road leads to the desert of Qaressa"),
    "QUEST_ACT2_SOON": ("As Ruínas de Ammar chegam na próxima versão", "The Ruins of Ammar arrive in the next version"),
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
    "ITEM_EQ_ESPADA_APRENDIZ_DESC": ("A espada de treino que o Mestre Bram te deu.", "The training sword Master Bram gave you."),
    "ITEM_EQ_COMUM_DESC": ("Peça simples, feita por qualquer ferreiro.", "A simple piece any smith can make."),
    "ITEM_EQ_RARO_DESC": ("Aço bem trabalhado, com detalhes azuis.", "Well-worked steel with blue trims."),
    "ITEM_EQ_EPICO_DESC": ("Runas antigas brilham no metal escuro.", "Ancient runes glow on the dark metal."),
    "ITEM_EQ_LENDARIO_DESC": ("Dizem que foi forjada com a luz do céu.", "They say it was forged with the light of the sky."),
    "ITEM_MAT_LINGOTE_ACO": ("Lingote de aço", "Steel ingot"),
    "ITEM_MAT_SEDA_DESERTO": ("Seda do deserto", "Desert silk"),
    "ITEM_MAT_ESCAMA_DUNA": ("Escama de duna", "Dune scale"),
    "ITEM_MAT_CRISTAL_AREIA": ("Cristal de areia", "Sand crystal"),
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
