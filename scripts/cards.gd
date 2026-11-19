## Kubbleken och pinnarna.
##
## KUBBLEKEN: istället för kort samlar du specialkubbar (max 5). Varje match
## ställs dina kubbar upp på motståndarens baslinje, och när du träffar eller
## fäller dem händer saker. Vissa har också en passiv effekt så länge de
## finns i leken. Kubbarna följer med när de kastas in som fältkubbar, så
## samma kubb kan ge effekt flera gånger per match.
##
## Fält per kubb:
##   sv/en   [namn, beskrivning]
##   price   pris i tänder (förbannade är gratis)
##   col     färgton på träet
##   mods    passiva modifierare (summeras av Run.mod)
##   hit     effekter när din pinne träffar kubben:
##             boom (kraft)   sprängs och knuffar grannar
##             chain (n)      de n närmaste stående kubbarna faller också
##             zap (n)        blixten fäller n slumpade kubbar på samma sida
##             bounce         pinnen studsar upp igen
##             wind           en vindpust knuffar alla kubbar på sidan bakåt
##             teleport       kubben försvinner och dyker upp någon annanstans
##   fell    effekter när kubben fälls giltigt av dig:
##             teeth (n), mult (x tänder för kastet), baton (+n pinnar),
##             opp_skip (n färre pinnar för honom nästa tur), opp_plus (n fler),
##             shield (+n kungens nåd), gamble (n: +n eller -n/2),
##             steal (natt x 3 tänder), zap (n), reraise (n av hans fällda reses)
##   mass    massa-multiplikator (tyngre = svårare att fälla)
##   cursed  förbannad
##   unlock  [statistik, värde] för att låsas upp (runs, wins, kubbs,
##           best_night, leffe_beaten, perfect, combos, teeth)
##
## Passiva nycklar (mods): batons_add, meter_time_mult, acc_time_mult,
## green_mult, power_mult, push_mult, teeth_kubb_add, combo_mult, king_shield,
## opp_error_mult, no_aim_line, no_move, last_baton_mult, other_baton_mult,
## perfect_teeth, bell, toss_forgive, win_teeth_add, interest (tänder per 5
## sparade vid vinst), shop_discount, theirs_mass_mult, opp_batons_add,
## field_teeth (extra tänder per fälld fältkubb)
class_name Cards
extends RefCounted

const DEFS := {
	# ======================================================== passiva
	"bjorkkubb": {"sv": ["Björkkubben", "+1 pinne per tur. Vit som en spökbrud."], "en": ["Birch Kubb", "+1 baton per turn. White as a ghost bride."],
		"price": 6, "col": Color(1.5, 1.45, 1.3), "mods": {"batons_add": 1}},
	"krakkubb": {"sv": ["Kråkkubben", "Precisionsmarkören går 30 % långsammare. Den kraxar."], "en": ["Crow Kubb", "Accuracy cursor 30% slower. It caws."],
		"price": 4, "col": Color(0.35, 0.33, 0.4), "mods": {"acc_time_mult": 1.3}},
	"stangkubb": {"sv": ["Midsommarkubben", "Gröna fältet är 50 % bredare. Blommor i håret."], "en": ["Midsummer Kubb", "Green zone 50% wider. Flowers in its hair."],
		"price": 5, "col": Color(0.9, 1.4, 0.8), "mods": {"green_mult": 1.5}},
	"ostkubb": {"sv": ["Ostkubben", "Kraftmätaren fylls 25 % långsammare. Väldigt hålig."], "en": ["Cheese Kubb", "Power meter 25% slower. Very holey."],
		"price": 3, "col": Color(1.6, 1.35, 0.5), "mods": {"meter_time_mult": 1.25}},
	"tjarkubb": {"sv": ["Tjärkubben", "Alla träffar knuffar dubbelt så hårt."], "en": ["Tar Kubb", "All hits push twice as hard."],
		"price": 5, "col": Color(0.3, 0.25, 0.22), "mods": {"push_mult": 2.0}},
	"sillkubb": {"sv": ["Sillkubben", "+1 tand per fälld kubb. Luktar midsommar."], "en": ["Herring Kubb", "+1 tooth per felled kubb. Smells of midsummer."],
		"price": 4, "col": Color(1.1, 1.2, 1.4), "mods": {"teeth_kubb_add": 1}},
	"klonkkubb": {"sv": ["Dubbelklonken", "Kombotänder x2."], "en": ["Double Clonk", "Combo teeth x2."],
		"price": 6, "col": Color(1.3, 0.9, 0.6), "mods": {"combo_mult": 2.0}},
	"kronkubb": {"sv": ["Kronkubben", "Kungen tål en träff per match. Han är skyldig dig."], "en": ["Crown Kubb", "The king forgives one hit per match. He owes you."],
		"price": 7, "col": Color(1.6, 1.3, 0.4), "mods": {"king_shield": 1}},
	"ogonkubb": {"sv": ["Grannkubben", "Motståndaren kastar 40 % sämre. Kubben har ett öga."], "en": ["Neighbour Kubb", "Opponent throws 40% worse. The kubb has an eye."],
		"price": 6, "col": Color(1.2, 1.0, 1.0), "mods": {"opp_error_mult": 1.4}},
	"linjalkubb": {"sv": ["Linjalkubben", "+2 tänder för varje PERFEKT kast."], "en": ["Ruler Kubb", "+2 teeth for every PERFECT throw."],
		"price": 4, "col": Color(1.3, 1.3, 1.0), "mods": {"perfect_teeth": 2}},
	"nubbekubb": {"sv": ["Nubbekubben", "+10 % kastkraft. Hej tomtegubbar."], "en": ["Schnapps Kubb", "+10% throw power. Skål."],
		"price": 3, "col": Color(1.0, 1.3, 1.4), "mods": {"power_mult": 1.1}},
	"myrkubb": {"sv": ["Myrkubben", "Kubbar du kastar in utanför planen läggs in ändå. Myrorna bär."], "en": ["Ant Kubb", "Kubbs you toss out of bounds are placed in anyway. The ants carry."],
		"price": 3, "col": Color(1.2, 0.7, 0.5), "mods": {"toss_forgive": 1}},
	"klockkubb": {"sv": ["Klockkubben", "Var tredje tur välter en slumpad motståndarkubb. Dong."], "en": ["Bell Kubb", "Every third turn a random enemy kubb falls. Dong."],
		"price": 8, "col": Color(1.4, 1.2, 0.7), "mods": {"bell": 1}, "unlock": ["wins", 1]},
	"guldkubb": {"sv": ["Guldtandskubben", "+6 tänder när du vinner en match."], "en": ["Gold Tooth Kubb", "+6 teeth when you win a match."],
		"price": 5, "col": Color(1.8, 1.4, 0.3), "mods": {"win_teeth_add": 6}, "unlock": ["best_night", 2]},
	"dalakubb": {"sv": ["Dalakubben", "+2 pinnar per tur. Röd. Den sparkas."], "en": ["Dala Kubb", "+2 batons per turn. Red. It kicks."],
		"price": 11, "col": Color(1.6, 0.4, 0.3), "mods": {"batons_add": 2}, "unlock": ["leffe_beaten", 1]},
	"rantekubb": {"sv": ["Räntekubben", "Vid vinst: +1 tand per 5 tänder du har (max 5). Banken på ängen."], "en": ["Interest Kubb", "On a win: +1 tooth per 5 you hold (max 5). The meadow bank."],
		"price": 5, "col": Color(0.8, 1.4, 0.8), "mods": {"interest": 1}},
	"snalkubb": {"sv": ["Snålkubben", "Allt i boden kostar 1 tand mindre. Kråkmor muttrar."], "en": ["Stingy Kubb", "Everything in the shop costs 1 tooth less. Crow Mother mutters."],
		"price": 4, "col": Color(0.9, 0.9, 0.8), "mods": {"shop_discount": 1}},
	"balsakubb": {"sv": ["Balsakubben", "Alla hans kubbar väger 25 % mindre. De känner sig lätta i själen."], "en": ["Balsa Kubb", "All his kubbs weigh 25% less. Light of soul."],
		"price": 6, "col": Color(1.5, 1.4, 1.1), "mods": {"theirs_mass_mult": 0.75}},
	"sotkubb": {"sv": ["Sotkubben", "Motståndaren får en pinne mindre per tur. Han hittar den aldrig."], "en": ["Soot Kubb", "The opponent gets one baton less per turn. He never finds it."],
		"price": 9, "col": Color(0.25, 0.22, 0.22), "mods": {"opp_batons_add": -1}, "unlock": ["wins", 3]},
	"faltkubb": {"sv": ["Fältmarskalken", "+2 tänder för varje fältkubb du fäller."], "en": ["Field Marshal", "+2 teeth for every field kubb you fell."],
		"price": 4, "col": Color(0.9, 1.1, 0.6), "mods": {"field_teeth": 2}},
	"mosskubb": {"sv": ["Mosskubben", "Gröna fältet 25 % bredare och markören 15 % långsammare. Mjuk."], "en": ["Moss Kubb", "Green zone 25% wider, cursor 15% slower. Soft."],
		"price": 6, "col": Color(0.6, 1.2, 0.5), "mods": {"green_mult": 1.25, "acc_time_mult": 1.15}},
	# ======================================================== träffeffekter
	"krutkubb": {"sv": ["Krutkubben", "TRÄFF: exploderar och knuffar omkull grannarna. Ingen rökning."], "en": ["Powder Kubb", "HIT: explodes and knocks over its neighbours. No smoking."],
		"price": 7, "col": Color(1.4, 0.5, 0.35), "hit": {"boom": 1.0}},
	"dominokubb": {"sv": ["Dominokubben", "TRÄFF: de 2 närmaste stående kubbarna faller också."], "en": ["Domino Kubb", "HIT: the 2 nearest standing kubbs fall too."],
		"price": 7, "col": Color(1.4, 1.4, 1.4), "hit": {"chain": 2}},
	"askkubb": {"sv": ["Åskkubben", "TRÄFF: blixten fäller en slumpad kubb på samma sida."], "en": ["Thunder Kubb", "HIT: lightning fells a random kubb on the same side."],
		"price": 8, "col": Color(0.8, 0.9, 1.6), "hit": {"zap": 1}, "unlock": ["kubbs", 30]},
	"studskubb": {"sv": ["Studsmattekubben", "TRÄFF: pinnen studsar högt upp igen och kan träffa mer."], "en": ["Trampoline Kubb", "HIT: the baton bounces high again and can hit more."],
		"price": 5, "col": Color(1.5, 0.8, 1.3), "hit": {"bounce": 1}},
	"vindkubb": {"sv": ["Vindkubben", "TRÄFF: en vindpust knuffar alla kubbar på planhalvan."], "en": ["Wind Kubb", "HIT: a gust shoves every kubb in that half."],
		"price": 6, "col": Color(1.1, 1.3, 1.4), "hit": {"wind": 1}},
	"getingkubb": {"sv": ["Getingboet", "TRÄFF: getingar sprider kubbarna. FÄLLD: +2 tänder. Aj."], "en": ["Wasp Nest", "HIT: wasps scatter the kubbs. FELLED: +2 teeth. Ow."],
		"price": 8, "col": Color(1.6, 1.3, 0.3), "hit": {"wind": 1}, "fell": {"teeth": 2}, "unlock": ["runs", 2]},
	"hackkubb": {"sv": ["Hackspettskubben", "TRÄFF: närmaste kubb faller också. FÄLLD: +1 tand. Tock tock."], "en": ["Woodpecker Kubb", "HIT: the nearest kubb falls too. FELLED: +1 tooth. Tock tock."],
		"price": 6, "col": Color(1.2, 0.6, 0.5), "hit": {"chain": 1}, "fell": {"teeth": 1}},
	"elkubb": {"sv": ["Elstängselkubben", "TRÄFF: blixten fäller 2 kubbar. Kossorna har varnat dig."], "en": ["Electric Fence Kubb", "HIT: lightning fells 2 kubbs. The cows warned you."],
		"price": 11, "col": Color(0.9, 1.6, 1.6), "hit": {"zap": 2}, "unlock": ["leffe_beaten", 2]},
	"hoppkubb": {"sv": ["Hembränningskubben", "TRÄFF: ENORM explosion. Grannen ringer polisen."], "en": ["Moonshine Kubb", "HIT: HUGE explosion. The neighbour calls the police."],
		"price": 10, "col": Color(1.6, 1.0, 0.5), "hit": {"boom": 1.7}, "unlock": ["combos", 10]},
	# ======================================================== fällningseffekter
	"tandkubb": {"sv": ["Tandkubben", "FÄLLD: +4 tänder. Den är full av dem. Fråga inte."], "en": ["Tooth Kubb", "FELLED: +4 teeth. It is full of them. Don't ask."],
		"price": 4, "col": Color(1.6, 1.55, 1.4), "fell": {"teeth": 4}},
	"pinnkubb": {"sv": ["Pinnkubben", "FÄLLD: +1 pinne den här turen."], "en": ["Baton Kubb", "FELLED: +1 baton this turn."],
		"price": 5, "col": Color(1.1, 0.9, 0.7), "fell": {"baton": 1}},
	"trollkubb": {"sv": ["Trollkubben", "FÄLLD: kastets tänder x2. Den skrattar när den faller."], "en": ["Troll Kubb", "FELLED: that throw's teeth x2. It laughs as it falls."],
		"price": 6, "col": Color(0.7, 1.1, 0.7), "fell": {"mult": 2.0}},
	"sovkubb": {"sv": ["Sömnkubben", "FÄLLD: motståndaren tappar en pinne nästa tur. Han gäspar."], "en": ["Sleepy Kubb", "FELLED: the opponent loses a baton next turn. He yawns."],
		"price": 6, "col": Color(0.8, 0.8, 1.3), "fell": {"opp_skip": 1}},
	"skoldkubb": {"sv": ["Sköldkubben", "FÄLLD: kungen tål en träff till den här matchen."], "en": ["Shield Kubb", "FELLED: the king forgives one more hit this match."],
		"price": 6, "col": Color(1.2, 1.2, 1.5), "fell": {"shield": 1}},
	"lotterikubb": {"sv": ["Lotterikubben", "FÄLLD: 50 % chans till +6 tänder. Annars -3. Spela ansvarsfullt."], "en": ["Lottery Kubb", "FELLED: 50% for +6 teeth. Otherwise -3. Gamble responsibly."],
		"price": 3, "col": Color(1.5, 1.1, 1.5), "fell": {"gamble": 6}},
	"spegelkubb": {"sv": ["Spegelkubben", "FÄLLD: en till kubb faller av ren sympati."], "en": ["Mirror Kubb", "FELLED: another kubb falls out of pure sympathy."],
		"price": 8, "col": Color(1.4, 1.5, 1.6), "fell": {"zap": 1}, "unlock": ["combos", 5]},
	"gravkubb": {"sv": ["Gravkubben", "FÄLLD: du rånar graven på natt x 3 tänder."], "en": ["Grave Kubb", "FELLED: you rob the grave for night x 3 teeth."],
		"price": 7, "col": Color(0.6, 0.6, 0.65), "fell": {"steal": 1}, "unlock": ["best_night", 3]},
	"lussekubb": {"sv": ["Lussekubben", "FÄLLD: +1 pinne och +1 tand. Fel högtid, men ändå."], "en": ["Saffron Kubb", "FELLED: +1 baton and +1 tooth. Wrong holiday, still good."],
		"price": 8, "col": Color(1.7, 1.2, 0.3), "fell": {"baton": 1, "teeth": 1}, "unlock": ["runs", 3]},
	"stjarnkubb": {"sv": ["Stjärnfallskubben", "FÄLLD: +2 tänder, och PERFEKT-kast med den ger x3."], "en": ["Shooting Star Kubb", "FELLED: +2 teeth, and x3 if the throw was PERFECT."],
		"price": 7, "col": Color(1.6, 1.6, 1.0), "fell": {"teeth": 2, "perfect_mult": 3.0}, "unlock": ["perfect", 10]},
	# ======================================================== förbannade
	"tummkubb": {"sv": ["Din tumme", "FÖRBANNAD. +3 tänder per kubb, men markören går 40 % fortare."], "en": ["Your Thumb", "CURSED. +3 teeth per kubb, but the cursor is 40% faster."],
		"price": 0, "cursed": true, "col": Color(1.4, 0.8, 0.7), "mods": {"teeth_kubb_add": 3, "acc_time_mult": 0.6}},
	"sistakubb": {"sv": ["Den sista kubben", "FÖRBANNAD. Turens sista pinne ger x4 tänder, alla andra ger 0."], "en": ["The Last Kubb", "CURSED. Last baton of a turn gives x4 teeth, all others 0."],
		"price": 0, "cursed": true, "col": Color(0.5, 0.2, 0.3), "mods": {"last_baton_mult": 4.0, "other_baton_mult": 0.0}},
	"ruttenkubb": {"sv": ["Rutten sill", "FÖRBANNAD. -1 pinne per tur, men +4 tänder per fälld kubb."], "en": ["Rotten Herring", "CURSED. -1 baton per turn, but +4 teeth per felled kubb."],
		"price": 0, "cursed": true, "col": Color(0.7, 0.8, 0.5), "mods": {"batons_add": -1, "teeth_kubb_add": 4}},
	"grotkubb": {"sv": ["Grötkubben", "FÖRBANNAD. Du kan inte gå längs linjen, men +1 pinne."], "en": ["Porridge Kubb", "CURSED. You can't walk the line, but +1 baton."],
		"price": 0, "cursed": true, "col": Color(1.3, 1.2, 1.0), "mods": {"no_move": 1, "batons_add": 1}},
	"glasogonkubb": {"sv": ["Mormors glasögon", "FÖRBANNAD. Ingen siktlinje, men gröna fältet är dubbelt så brett."], "en": ["Grandma's Glasses", "CURSED. No aim line, but the green zone is twice as wide."],
		"price": 0, "cursed": true, "col": Color(1.0, 0.9, 1.2), "mods": {"no_aim_line": 1, "green_mult": 2.0}},
	"skuldkubb": {"sv": ["Vedgubbens skuld", "FÖRBANNAD. +8 tänder per vinst, men motståndaren kastar 20 % bättre."], "en": ["The Woodman's Debt", "CURSED. +8 teeth per win, but the opponent throws 20% better."],
		"price": 0, "cursed": true, "col": Color(0.6, 0.45, 0.35), "mods": {"win_teeth_add": 8, "opp_error_mult": 0.8}},
	"spokkubb": {"sv": ["Spökkubben", "FÖRBANNAD. TRÄFF: den försvinner och dyker upp någon annanstans. FÄLLD: +6 tänder."], "en": ["Ghost Kubb", "CURSED. HIT: it vanishes and reappears elsewhere. FELLED: +6 teeth."],
		"price": 0, "cursed": true, "col": Color(1.3, 1.4, 1.6), "hit": {"teleport": 1}, "fell": {"teeth": 6}},
	"blykubb": {"sv": ["Blykubben", "FÖRBANNAD. Väger tre gånger så mycket. FÄLLD: +8 tänder."], "en": ["Lead Kubb", "CURSED. Weighs three times as much. FELLED: +8 teeth."],
		"price": 0, "cursed": true, "col": Color(0.45, 0.45, 0.5), "mass": 3.0, "fell": {"teeth": 8}},
	"svaltkubb": {"sv": ["Svältkubben", "FÖRBANNAD. FÄLLD: kastets tänder x3, men han får en extra pinne nästa tur."], "en": ["Starving Kubb", "CURSED. FELLED: that throw's teeth x3, but he gets an extra baton next turn."],
		"price": 0, "cursed": true, "col": Color(0.7, 0.5, 0.5), "fell": {"mult": 3.0, "opp_plus": 1}},
	"vackarkubb": {"sv": ["Väckarkubben", "FÖRBANNAD. FÄLLD: +5 tänder, men en av hans fällda kubbar reser sig. RIIING."], "en": ["Alarm Kubb", "CURSED. FELLED: +5 teeth, but one of his felled kubbs stands back up. RIIING."],
		"price": 0, "cursed": true, "col": Color(1.5, 0.6, 0.6), "fell": {"teeth": 5, "reraise": 1}},
}

## Motståndarens specialkubbar. Han smyger in dem på sin baslinje (slump,
## fler senare nätter). De straffar DIG när du träffar eller fäller dem.
##   fell: lose_teeth (n), lose_baton (n), topple_mine (n av dina kubbar faller),
##         opp_plus (n)   hit: stick (pinnen fastnar), teleport
const OPP_DEFS := {
	"taggkubb": {"sv": ["Taggkubben", "HANS. FÄLLD: du tappar 2 tänder i taggarna."], "en": ["Thorn Kubb", "HIS. FELLED: you lose 2 teeth to the thorns."],
		"col": Color(0.55, 0.25, 0.2), "opp": true, "fell": {"lose_teeth": 2}},
	"tjuvkubb": {"sv": ["Tjuvkubben", "HANS. FÄLLD: den stjäl 4 tänder och springer."], "en": ["Thief Kubb", "HIS. FELLED: it steals 4 teeth and runs."],
		"col": Color(0.35, 0.3, 0.3), "opp": true, "fell": {"lose_teeth": 4}},
	"kadakubb": {"sv": ["Kådakubben", "HANS. TRÄFF: pinnen fastnar och dör där."], "en": ["Resin Kubb", "HIS. HIT: the baton sticks and dies there."],
		"col": Color(0.9, 0.6, 0.2), "opp": true, "hit": {"stick": 1}},
	"spegelvand": {"sv": ["Spegelvända kubben", "HANS. FÄLLD: en av DINA kubbar faller också."], "en": ["Reversed Kubb", "HIS. FELLED: one of YOUR kubbs falls too."],
		"col": Color(0.5, 0.4, 0.6), "opp": true, "fell": {"topple_mine": 1}},
	"skrikkubb": {"sv": ["Skrikkubben", "HANS. FÄLLD: den skriker. Han får en extra pinne nästa tur."], "en": ["Screaming Kubb", "HIS. FELLED: it screams. He gets an extra baton next turn."],
		"col": Color(0.7, 0.3, 0.35), "opp": true, "fell": {"opp_plus": 1}},
	"stenkubb": {"sv": ["Stenkubben", "HANS. Gjord av gravsten. Väger fyra gånger så mycket."], "en": ["Stone Kubb", "HIS. Made of a gravestone. Weighs four times as much."],
		"col": Color(0.5, 0.5, 0.52), "opp": true, "mass": 4.0},
	"smitaren": {"sv": ["Smitaren", "HANS. TRÄFF: den försvinner och står upp någon annanstans."], "en": ["The Dodger", "HIS. HIT: it vanishes and stands up somewhere else."],
		"col": Color(0.4, 0.45, 0.55), "opp": true, "hit": {"teleport": 1}},
	"slukkubb": {"sv": ["Slukaren", "HANS. FÄLLD: den äter en av dina pinnar den här turen."], "en": ["The Gulper", "HIS. FELLED: it eats one of your batons this turn."],
		"col": Color(0.45, 0.2, 0.25), "opp": true, "fell": {"lose_baton": 1}},
}


## 30 pinnar. Välj en vid start av en run.
##   mass, power, push   fysik (power och push är multiplikatorer)
##   len                 längd-multiplikator
##   col, band, trail    färger (trä, band, spår)
##   glow                självlysning 0..1
##   bounce, grav        studs och gravitationsskala
##   hit                 träffeffekt (samma som kubbarnas) på turens första kubbträff
##   tooth_cost          tänder per kast
##   unlock              som för kubbarna; saknas = upplåst från start
##   + alla passiva modnycklar (t.ex. batons_add, green_mult)
const BATONS := {
	"vanlig": {"sv": ["Vanlig pinne", "Ek. Pålitlig. Tråkig."], "en": ["Plain Baton", "Oak. Reliable. Boring."],
		"mass": 0.42, "power": 1.0, "push": 1.0},
	"stumpen": {"sv": ["Stumpen", "Kort och tjock. Gröna fältet 20 % bredare."], "en": ["The Stub", "Short and stout. Green zone 20% wider."],
		"mass": 0.32, "power": 1.05, "push": 0.9, "len": 0.72, "green_mult": 1.2, "col": Color(1.1, 0.9, 0.7)},
	"langa_lars": {"sv": ["Långa Lars", "Lång som en midsommarnatt. Knuffar mer, flyger lite kortare."], "en": ["Long Lars", "Long as a midsummer night. Pushes more, flies a bit shorter."],
		"mass": 0.55, "power": 0.95, "push": 1.3, "len": 1.35, "col": Color(0.9, 0.8, 0.7)},
	"gummipinne": {"sv": ["Gummipinnen", "Studsar som en galning. Knuffar lite."], "en": ["Rubber Baton", "Bounces like mad. Pushes a little."],
		"mass": 0.38, "power": 1.0, "push": 0.75, "bounce": 0.75, "col": Color(1.4, 0.5, 0.4), "band": Color(1, 1, 0.3), "trail": Color(1.0, 0.4, 0.3), "unlock": ["runs", 1]},
	"jarnpinne": {"sv": ["Järnpinnen", "Tung. Kortare kast, men allt den rör välter."], "en": ["Iron Baton", "Heavy. Shorter throws, but everything it touches falls."],
		"mass": 0.9, "power": 0.9, "push": 2.2, "col": Color(0.55, 0.58, 0.65), "band": Color(0.3, 0.3, 0.35), "trail": Color(0.7, 0.75, 0.8), "unlock": ["wins", 1]},
	"bjorkpinne": {"sv": ["Björkpinnen", "Lätt. Flyger långt, knuffar lite."], "en": ["Birch Baton", "Light. Flies far, pushes little."],
		"mass": 0.3, "power": 1.12, "push": 0.8, "col": Color(1.6, 1.55, 1.45), "band": Color(0.1, 0.1, 0.1), "unlock": ["best_night", 2]},
	"benpinne": {"sv": ["Benpinnen", "Gjord av något. +1 pinne per tur, men varje kast kostar en tand."], "en": ["Bone Baton", "Made of something. +1 baton per turn, but every throw costs a tooth."],
		"mass": 0.45, "power": 1.0, "push": 1.3, "batons_add": 1, "tooth_cost": 1, "col": Color(1.6, 1.5, 1.3), "band": Color(0.5, 0.1, 0.1), "unlock": ["kubbs", 40]},
	"svartpinne": {"sv": ["Svartpinnen", "Doppad i tjära. Knuffar 60 % hårdare. Lämnar svart spår."], "en": ["Black Baton", "Dipped in tar. Pushes 60% harder. Leaves a black trail."],
		"mass": 0.5, "power": 0.97, "push": 1.6, "col": Color(0.25, 0.22, 0.2), "trail": Color(0.15, 0.1, 0.1), "unlock": ["runs", 2]},
	"ronnpinne": {"sv": ["Rönnpinnen", "Skyddar mot troll. Kungen tål en träff per match."], "en": ["Rowan Baton", "Wards off trolls. The king forgives one hit per match."],
		"mass": 0.42, "power": 1.0, "push": 1.0, "king_shield": 1, "col": Color(1.2, 0.8, 0.6), "band": Color(1.0, 0.2, 0.1), "unlock": ["wins", 2]},
	"enris": {"sv": ["Enriset", "Doftar gott. Precisionsmarkören 20 % långsammare."], "en": ["Juniper Stick", "Smells nice. Accuracy cursor 20% slower."],
		"mass": 0.4, "power": 1.0, "push": 1.0, "acc_time_mult": 1.2, "col": Color(0.9, 1.1, 0.8), "trail": Color(0.6, 1.0, 0.6), "unlock": ["kubbs", 20]},
	"glaspinne": {"sv": ["Glaspinnen", "Lyser svagt. +1 tand per fälld kubb."], "en": ["Glass Baton", "Faint glow. +1 tooth per felled kubb."],
		"mass": 0.4, "power": 1.04, "push": 1.0, "teeth_kubb_add": 1, "glow": 0.7, "col": Color(1.0, 1.4, 1.6), "trail": Color(0.6, 0.9, 1.0), "unlock": ["perfect", 5]},
	"flaggstang": {"sv": ["Flaggstången", "Enorm. Knuffar som en traktor. -1 pinne per tur."], "en": ["The Flagpole", "Enormous. Pushes like a tractor. -1 baton per turn."],
		"mass": 0.7, "power": 0.88, "push": 1.9, "len": 1.55, "batons_add": -1, "col": Color(1.4, 1.4, 1.4), "band": Color(0.2, 0.3, 0.9), "unlock": ["combos", 3]},
	"kvastskaft": {"sv": ["Kvastskaftet", "Häxans. Svävar lite i luften."], "en": ["Broomstick", "The witch's. Floats a bit in the air."],
		"mass": 0.38, "power": 0.96, "push": 1.0, "grav": 0.82, "col": Color(0.9, 0.7, 0.5), "trail": Color(0.7, 0.3, 0.9), "unlock": ["best_night", 2]},
	"kanelstang": {"sv": ["Kanelstången", "Motståndaren blir hungrig och kastar 20 % sämre."], "en": ["Cinnamon Stick", "The opponent gets hungry and throws 20% worse."],
		"mass": 0.4, "power": 1.0, "push": 0.95, "opp_error_mult": 1.2, "col": Color(1.2, 0.65, 0.4), "trail": Color(0.9, 0.5, 0.2), "unlock": ["wins", 3]},
	"grillkorv": {"sv": ["Grillkorven", "Tjock-Leffe tittar bara på den. Han kastar 30 % sämre."], "en": ["The Sausage", "Fat Leffe only stares at it. He throws 30% worse."],
		"mass": 0.35, "power": 0.95, "push": 0.65, "len": 0.85, "opp_error_mult": 1.3, "col": Color(1.5, 0.6, 0.45), "band": Color(0.4, 0.15, 0.1), "unlock": ["leffe_beaten", 1]},
	"krutpinne": {"sv": ["Krutpinnen", "Första kubbträffen exploderar. Varje kast kostar en tand."], "en": ["Powder Baton", "The first kubb hit explodes. Every throw costs a tooth."],
		"mass": 0.45, "power": 1.0, "push": 1.0, "hit": {"boom": 0.8}, "tooth_cost": 1, "col": Color(0.6, 0.4, 0.35), "band": Color(1.0, 0.5, 0.1), "trail": Color(1.0, 0.6, 0.2), "glow": 0.3, "unlock": ["kubbs", 60]},
	"askpinne": {"sv": ["Åskpinnen", "Första kubbträffen kallar på blixten. -1 pinne per tur."], "en": ["Thunder Baton", "The first kubb hit calls down lightning. -1 baton per turn."],
		"mass": 0.42, "power": 1.0, "push": 1.0, "hit": {"zap": 1}, "batons_add": -1, "col": Color(0.8, 0.9, 1.5), "band": Color(1, 1, 0.4), "trail": Color(0.7, 0.8, 1.0), "glow": 0.5, "unlock": ["kubbs", 100]},
	"dominopinne": {"sv": ["Dominopinnen", "Första kubbträffen fäller också närmaste granne."], "en": ["Domino Baton", "The first kubb hit also fells its nearest neighbour."],
		"mass": 0.42, "power": 1.0, "push": 1.0, "hit": {"chain": 1}, "col": Color(1.3, 1.3, 1.3), "band": Color(0.05, 0.05, 0.05), "unlock": ["combos", 6]},
	"fjaderpinne": {"sv": ["Fjäderpinnen", "Väger nästan inget. Svävar. Knuffar som en fjäder."], "en": ["Feather Baton", "Weighs almost nothing. Floats. Pushes like a feather."],
		"mass": 0.22, "power": 1.15, "push": 0.6, "grav": 0.8, "acc_time_mult": 1.15, "col": Color(1.5, 1.5, 1.6), "trail": Color(1, 1, 1), "unlock": ["perfect", 15]},
	"blypinne": {"sv": ["Blypinnen", "Väldigt tung. Kraftmätaren går långsamt. Allt dör."], "en": ["Lead Baton", "Very heavy. Slow power meter. Everything dies."],
		"mass": 1.3, "power": 0.8, "push": 3.0, "meter_time_mult": 1.2, "col": Color(0.45, 0.45, 0.5), "band": Color(0.2, 0.2, 0.2), "unlock": ["wins", 5]},
	"guldpinne": {"sv": ["Guldpinnen", "+4 tänder per vinst och +1 per PERFEKT kast. Glänser."], "en": ["Gold Baton", "+4 teeth per win and +1 per PERFECT throw. Shiny."],
		"mass": 0.5, "power": 1.0, "push": 1.1, "win_teeth_add": 4, "perfect_teeth": 1, "glow": 0.4, "col": Color(1.8, 1.4, 0.35), "trail": Color(1.0, 0.85, 0.3), "unlock": ["teeth", 150]},
	"tandpetare": {"sv": ["Tandpetaren", "Liten. +2 tänder per fälld kubb, men knuffar svagt."], "en": ["The Toothpick", "Tiny. +2 teeth per felled kubb, but pushes weakly."],
		"mass": 0.2, "power": 1.08, "push": 0.7, "len": 0.55, "teeth_kubb_add": 2, "col": Color(1.4, 1.3, 1.1), "unlock": ["teeth", 80]},
	"majstang": {"sv": ["Majstångspinnen", "Gröna fältet 40 % bredare. Lyser av blomkransar."], "en": ["Maypole Baton", "Green zone 40% wider. Glows with flower crowns."],
		"mass": 0.42, "power": 1.0, "push": 1.0, "green_mult": 1.4, "glow": 0.4, "col": Color(1.2, 1.4, 1.0), "band": Color(0.9, 0.3, 0.7), "trail": Color(1.0, 0.6, 0.9), "unlock": ["runs", 4]},
	"likkista": {"sv": ["Likkistebrädan", "+2 pinnar per tur, men motståndaren kastar 20 % bättre."], "en": ["Coffin Plank", "+2 batons per turn, but the opponent throws 20% better."],
		"mass": 0.5, "power": 0.97, "push": 1.1, "batons_add": 2, "opp_error_mult": 0.8, "col": Color(0.5, 0.35, 0.3), "band": Color(0.6, 0.6, 0.6), "trail": Color(0.4, 0.2, 0.3), "unlock": ["best_night", 3]},
	"kraknabb": {"sv": ["Kråknäbben", "Första kubbträffen blåser omkull resten av planhalvan."], "en": ["Crow Beak", "The first kubb hit blows the rest of the half over."],
		"mass": 0.4, "power": 1.0, "push": 1.0, "hit": {"wind": 1}, "col": Color(0.3, 0.3, 0.35), "band": Color(0.9, 0.8, 0.2), "trail": Color(0.2, 0.2, 0.25), "unlock": ["kubbs", 150]},
	"istappen": {"sv": ["Istappen", "Kall. Flyger 10 % längre, knuffar 40 % hårdare. Mitt i juni."], "en": ["The Icicle", "Cold. Flies 10% further, pushes 40% harder. In June."],
		"mass": 0.45, "power": 1.1, "push": 1.4, "glow": 0.6, "col": Color(1.0, 1.5, 1.8), "trail": Color(0.7, 0.95, 1.0), "unlock": ["wins", 8]},
	"vedgubbens_arm": {"sv": ["Vedgubbens arm", "+1 pinne per tur. Den rör sig ibland."], "en": ["The Woodman's Arm", "+1 baton per turn. It moves sometimes."],
		"mass": 0.5, "power": 0.97, "push": 1.2, "batons_add": 1, "len": 1.1, "col": Color(0.7, 0.5, 0.35), "band": Color(0.3, 0.6, 0.2), "unlock": ["wins", 10]},
	"leffes_revben": {"sv": ["Leffes revben", "Knuffar dubbelt och kombotänder x1,5. Han saknar det inte."], "en": ["Leffe's Rib", "Pushes double and combo teeth x1.5. He won't miss it."],
		"mass": 0.6, "power": 0.95, "push": 2.0, "combo_mult": 1.5, "col": Color(1.5, 1.35, 1.2), "band": Color(0.7, 0.1, 0.1), "trail": Color(0.9, 0.3, 0.3), "unlock": ["leffe_beaten", 2]},
	"manpinne": {"sv": ["Månpinnen", "Blodröd. +2 tänder per PERFEKT kast, gröna 20 % bredare."], "en": ["Moon Baton", "Blood red. +2 teeth per PERFECT throw, green 20% wider."],
		"mass": 0.42, "power": 1.02, "push": 1.1, "perfect_teeth": 2, "green_mult": 1.2, "glow": 0.8, "col": Color(1.6, 0.3, 0.25), "trail": Color(1.0, 0.2, 0.15), "unlock": ["perfect", 30]},
	"sista_pinnen": {"sv": ["Den sista pinnen", "Bättre på allt. +1 pinne. Den viskar ditt namn."], "en": ["The Last Baton", "Better at everything. +1 baton. It whispers your name."],
		"mass": 0.5, "power": 1.05, "push": 1.5, "batons_add": 1, "green_mult": 1.2, "glow": 1.0, "col": Color(0.4, 0.1, 0.12), "band": Color(1.0, 0.85, 0.3), "trail": Color(1.0, 0.1, 0.1), "unlock": ["best_night", 4]},
}


static func kdef(id: String) -> Dictionary:
	return DEFS.get(id, OPP_DEFS.get(id, {}))


static func title(id: String) -> String:
	var d: Dictionary = DEFS.get(id, OPP_DEFS.get(id, BATONS.get(id, {})))
	return d.get(Lang.current, ["?", ""])[0]


static func desc(id: String) -> String:
	var d: Dictionary = DEFS.get(id, OPP_DEFS.get(id, BATONS.get(id, {})))
	return d.get(Lang.current, ["?", ""])[1]


static func color(id: String) -> Color:
	var d: Dictionary = DEFS.get(id, OPP_DEFS.get(id, BATONS.get(id, {})))
	return d.get("col", Color(1.2, 1.15, 1.1))


## Text för hur något låses upp, t.ex. "Vinn 3 matcher".
static func unlock_text(id: String) -> String:
	var d: Dictionary = DEFS.get(id, BATONS.get(id, {}))
	if not d.has("unlock"):
		return ""
	var stat: String = d.unlock[0]
	var n: int = d.unlock[1]
	var t := {
		"runs": ["Spela %d runs", "Play %d runs"],
		"wins": ["Vinn %d matcher", "Win %d matches"],
		"kubbs": ["Fäll %d kubbar totalt", "Fell %d kubbs in total"],
		"best_night": ["Nå natt %d", "Reach night %d"],
		"leffe_beaten": ["Besegra Tjock-Leffe %d gånger", "Beat Fat Leffe %d times"],
		"perfect": ["Gör %d perfekta kast", "Make %d perfect throws"],
		"combos": ["Gör %d kombos", "Make %d combos"],
		"teeth": ["Tjäna %d tänder totalt", "Earn %d teeth in total"],
	}
	var pair: Array = t.get(stat, ["%d", "%d"])
	if stat == "best_night" and n > 3:
		return "Vinn en hel run" if Lang.current == "sv" else "Win a whole run"
	return (pair[0] if Lang.current == "sv" else pair[1]) % n


## Ödeskort: du har en egen ödeslek (Run.fate_deck) som byggs på i boden.
## Var tredje fälld kubb drar du två kort ur leken och väljer ett.
## main._apply_fate() avgör vad varje id gör.
const FATE := {
	"kubb": {"price": 6, "sv": ["Kråkmors gåva", "En slumpad kubb går med i din kubblek."], "en": ["Crow Mother's Gift", "A random kubb joins your kubb deck."]},
	"pinne": {"price": 4, "sv": ["Lånad pinne", "Du kastar med en annan pinne resten av matchen. Kanske en du inte låst upp."], "en": ["Borrowed Baton", "You throw with another baton for the rest of the match. Maybe one you haven't unlocked."]},
	"extra": {"price": 5, "sv": ["Fickpinne", "+1 pinne den här turen. Den låg i fickan hela tiden."], "en": ["Pocket Baton", "+1 baton this turn. It was in your pocket all along."]},
	"tander": {"price": 2, "sv": ["Tandfen", "+3 tänder. Hon frågade inte."], "en": ["Tooth Fairy", "+3 teeth. She didn't ask."]},
	"tander_stor": {"price": 5, "sv": ["Gammal käke", "+7 tänder ur en käke i gräset."], "en": ["Old Jaw", "+7 teeth from a jaw in the grass."]},
	"gront": {"price": 4, "sv": ["Midsommarvind", "Gröna fältet 40 % bredare resten av matchen."], "en": ["Midsummer Breeze", "Green zone 40% wider for the rest of the match."]},
	"lugn": {"price": 4, "sv": ["Lugna händer", "Mätarna går 25 % långsammare resten av matchen."], "en": ["Steady Hands", "Meters run 25% slower for the rest of the match."]},
	"dubbel": {"price": 4, "sv": ["Dubbla tänder", "Nästa kast med träff ger dubbla tänder."], "en": ["Double Teeth", "Your next throw that hits gives double teeth."]},
	"blixt": {"price": 5, "sv": ["Åskväder", "Blixten slår ner på en av hans kubbar. Nu."], "en": ["Thunderstorm", "Lightning strikes one of his kubbs. Now."]},
	"skakig": {"price": 5, "sv": ["Hans mardröm", "Motståndaren kastar 30 % sämre resten av matchen."], "en": ["His Nightmare", "The opponent throws 30% worse for the rest of the match."]},
	"nad": {"price": 6, "sv": ["Kungens öga", "Kungen tål en träff till den här matchen."], "en": ["The King's Eye", "The king forgives one more hit this match."]},
	"sovpiller": {"price": 6, "sv": ["Sömnpulver", "Motståndaren får en pinne mindre nästa tur."], "en": ["Sleeping Powder", "The opponent gets one baton less next turn."]},
	"ranta": {"price": 4, "sv": ["Ockraren", "+1 tand per 4 tänder du har (max 6)."], "en": ["The Usurer", "+1 tooth per 4 teeth you hold (max 6)."]},
	"forbannad_kubb": {"price": 0, "cursed": true, "sv": ["Något i gräset", "FÖRBANNAD. En förbannad kubb kryper in i din lek."], "en": ["Something in the Grass", "CURSED. A cursed kubb crawls into your deck."]},
	"darr": {"price": 0, "cursed": true, "sv": ["Darrhänt", "FÖRBANNAD. Precisionsmarkören går 20 % fortare resten av matchen."], "en": ["Shaky Hands", "CURSED. The accuracy cursor is 20% faster for the rest of the match."]},
	"hans_pinne": {"price": 0, "cursed": true, "sv": ["Han hittar en pinne", "FÖRBANNAD. Motståndaren får en extra pinne nästa tur."], "en": ["He Finds a Baton", "CURSED. The opponent gets an extra baton next turn."]},
}

## Ödesleken du börjar varje run med.
const FATE_START := ["tander", "tander", "extra", "gront", "lugn", "darr", "hans_pinne"]


static func fate_title(id: String) -> String:
	return FATE[id][Lang.current][0]


static func fate_desc(id: String) -> String:
	return FATE[id][Lang.current][1]
