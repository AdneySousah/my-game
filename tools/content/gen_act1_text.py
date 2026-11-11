"""Gera data/dialogues/act1.json e as chaves de texto do Ato 1 em data/i18n/strings.csv.

O texto dos diálogos fica aqui (pt_BR e en lado a lado). Para mudar uma fala, edite
este arquivo e rode:  python -X utf8 tools/content/gen_act1_text.py
As chaves geradas começam com DLG_, BARK_, NPC_, QUEST_, OBJ_ e ITEM_; as outras
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
        ("bento", "Elas somem na Mina dos Corvos, ao norte da floresta. A comida da sua vila está lá dentro!", "They vanish into the Crows' Mine, north of the forest. Your village's food is in there!"),
        ("lio", "Então é para lá que a gente vai.", "Then that's where we're going."),
        ("bento", "A gente? Eu... eu fico guardando a vila. Alguém precisa. Fala com o Bram antes, tá?", "We? I... I'll guard the village. Someone has to. Talk to Bram first, okay?"),
    ],
    "main_04_bram": [
        ("bram", "A Mina dos Corvos... fechou há anos. Se o Gorvan esconde comida lá, deve ter gente armada vigiando.", "The Crows' Mine... it closed years ago. If Gorvan hides food there, there'll be armed men guarding it."),
        ("bram", "Siga a trilha da floresta para o norte. Descanse nas fogueiras. E não entre sem fôlego.", "Follow the forest trail north. Rest at the campfires. And don't go in out of breath."),
        ("lio", "Relaxa, mestre. Eu volto antes do jantar do Bento.", "Relax, master. I'll be back before Bento's dinner."),
        ("bram", "É disso que eu tenho medo.", "That's what I'm afraid of."),
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
    # --- Conversas fora de missão ---
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
    "QUEST_MAIN_04": ("Os corvos da mina", "The Crows of the Mine"),
    "QUEST_SIDE_TRIGO": ("Trigo escondido", "Hidden Wheat"),
    "QUEST_SIDE_FERRO": ("O ferro do Tobias", "Tobias's Iron"),
    "OBJ_TALK_MARTA": ("Fale com a Marta", "Talk to Marta"),
    "OBJ_TALK_BRAM": ("Encontre o Mestre Bram no treino", "Meet Master Bram at training"),
    "OBJ_KILL_BANDIDOS": ("Derrote bandidos na floresta: %d/%d", "Defeat bandits in the forest: %d/%d"),
    "OBJ_RETURN_BRAM": ("Volte ao Mestre Bram", "Return to Master Bram"),
    "OBJ_FIND_BENTO": ("Encontre o homem na clareira da floresta", "Find the man in the forest clearing"),
    "OBJ_KILL_ORCS_BENTO": ("Derrote os orcs da clareira: %d/%d", "Defeat the clearing orcs: %d/%d"),
    "OBJ_TALK_BENTO": ("Fale com o Bento", "Talk to Bento"),
    "OBJ_BENTO_TO_MARTA": ("Leve o Bento até a Marta", "Bring Bento to Marta"),
    "OBJ_ASK_BRAM_MINE": ("Pergunte ao Bram sobre a mina", "Ask Bram about the mine"),
    "OBJ_REACH_MINE": ("Chegue à Mina dos Corvos", "Reach the Crows' Mine"),
    "OBJ_MINE_DEEP": ("Explore o fundo da mina", "Explore the depths of the mine"),
    "OBJ_COLLECT_HERBS": ("Colha erva-de-orvalho na floresta: %d/%d", "Gather dewleaf in the forest: %d/%d"),
    "OBJ_RETURN_NINA": ("Leve as ervas para a Nina", "Bring the herbs to Nina"),
    "OBJ_KILL_ORCS": ("Derrote orcs na floresta: %d/%d", "Defeat orcs in the forest: %d/%d"),
    "OBJ_FIND_IRON": ("Ache o caixote de ferro na trilha norte", "Find the iron crate on the north trail"),
    "OBJ_RETURN_TOBIAS": ("Devolva o ferro ao Tobias", "Return the iron to Tobias"),
    "ITEM_ERVA_ORVALHO": ("Erva-de-orvalho", "Dewleaf"),
    "ITEM_CAIXOTE_FERRO": ("Caixote de ferro", "Iron crate"),
}

PREFIXES = ("DLG_", "BARK_", "NPC_", "QUEST_", "OBJ_", "ITEM_")


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
        body.append([key, pt, en])
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(header)
    w.writerows(body)
    cpath.write_text(buf.getvalue(), encoding="utf-8")
    print(f"ok: {len(dialogues)} diálogos, {len(texts)} textos")


if __name__ == "__main__":
    main()
