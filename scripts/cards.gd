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
	# ======================================================== poängkubbar (v0.11)
	# score: poäng när kubben fälls (chips = marker, mult = +multi, xmult = x multi)
	#   grow_chips / grow_mult: växer permanent varje gång den fälls
	#   per_cursed_mult, teeth_mult (per 5 tänder), last_xmult, first_xmult,
	#   all_enh_mult, perfect_xmult, per_felled_mult, miss_grow
	# toss: när kubben kastas in och landar (av dig eller honom)
	#   teeth, grow_chips, grow_mult, charge (+multi nästa kast), baton_next, rune
	"snoboll": {"sv": ["Snöbollskubben", "FÄLLD: +4 marker, och växer med +4 varje gång den fälls. Snö i juni."], "en": ["Snowball Kubb", "FELLED: +4 chips, and grows by +4 every time it's felled. Snow in June."],
		"price": 5, "col": Color(1.5, 1.6, 1.7), "score": {"chips": 4, "grow_chips": 4}},
	"myrstack": {"sv": ["Myrstacken", "INKAST: +1 multi för alltid när den landar. Myrorna bygger."], "en": ["The Anthill", "TOSSED: +1 mult forever each time it lands. The ants build."],
		"price": 5, "col": Color(1.0, 0.6, 0.4), "toss": {"grow_mult": 1}},
	"skata": {"sv": ["Skatans kubb", "INKAST: snor 2 tänder från motståndaren. Den gillar blankt."], "en": ["Magpie Kubb", "TOSSED: steals 2 teeth from the opponent. It likes shiny things."],
		"price": 4, "col": Color(0.3, 0.3, 0.45), "toss": {"teeth": 2}},
	"raknekubb": {"sv": ["Räknekubben", "FÄLLD: +1 multi för varje kubb du fällt i matchen. Den räknar högt."], "en": ["Counting Kubb", "FELLED: +1 mult for every kubb you've felled this match. It counts out loud."],
		"price": 6, "col": Color(1.2, 1.2, 0.7), "score": {"per_felled_mult": 1}},
	"fyrverkeri": {"sv": ["Fyrverkerikubben", "TRÄFF: konfetti och x2 multi på hela kastet. Pang."], "en": ["Firework Kubb", "HIT: confetti and x2 mult on the whole throw. Bang."],
		"price": 7, "col": Color(1.6, 0.6, 1.2), "hit": {"xmult": 2.0}},
	"pantkubb": {"sv": ["Pantkubben", "FÄLLD: +25 marker och +1 tand. Två kronor styck."], "en": ["Deposit Kubb", "FELLED: +25 chips and +1 tooth. Recycled."],
		"price": 4, "col": Color(0.7, 1.2, 0.9), "score": {"chips": 25}, "fell": {"teeth": 1}},
	"kyrkogard": {"sv": ["Kyrkogårdskubben", "FÄLLD: +3 multi för varje förbannad kubb i din lek."], "en": ["Churchyard Kubb", "FELLED: +3 mult for every cursed kubb in your deck."],
		"price": 5, "col": Color(0.55, 0.5, 0.6), "score": {"per_cursed_mult": 3, "mult": 1}},
	"midnatt": {"sv": ["Midnattskubben", "FÄLLD med turens sista pinne: x3 multi. Klockan slår tolv."], "en": ["Midnight Kubb", "FELLED with the turn's last baton: x3 mult. The clock strikes twelve."],
		"price": 6, "col": Color(0.3, 0.25, 0.6), "score": {"last_xmult": 3.0}},
	"gryning": {"sv": ["Gryningskubben", "FÄLLD med turens första pinne: x2 multi. Tuppen är död."], "en": ["Dawn Kubb", "FELLED with the turn's first baton: x2 mult. The rooster is dead."],
		"price": 5, "col": Color(1.6, 1.0, 0.6), "score": {"first_xmult": 2.0}},
	"girig": {"sv": ["Giriga kubben", "FÄLLD: +1 multi per 5 tänder du har. Den vill ha mer."], "en": ["Greedy Kubb", "FELLED: +1 mult per 5 teeth you hold. It wants more."],
		"price": 6, "col": Color(1.7, 1.5, 0.4), "score": {"teeth_mult": 1}},
	"eko": {"sv": ["Ekokubben", "INKAST: nästa kast som fäller får +4 multi. ...multi ...multi."], "en": ["Echo Kubb", "TOSSED: your next scoring throw gets +4 mult. ...mult ...mult."],
		"price": 5, "col": Color(0.9, 1.0, 1.5), "toss": {"charge": 4}},
	"sparbossa": {"sv": ["Sparbössan", "INKAST: +1 tand. FÄLLD: +marker lika med dina tänder. Pling."], "en": ["Piggy Bank", "TOSSED: +1 tooth. FELLED: +chips equal to your teeth. Clink."],
		"price": 6, "col": Color(1.6, 0.8, 0.9), "toss": {"teeth": 1}, "score": {"teeth_chips": 1}},
	"haxring": {"sv": ["Häxringen", "FÄLLD: +8 multi om alla 5 kubbar bär en runa. Svamparna vet."], "en": ["Fairy Ring", "FELLED: +8 mult if all 5 kubbs carry a rune. The mushrooms know."],
		"price": 5, "col": Color(0.9, 0.5, 1.4), "score": {"all_enh_mult": 8, "mult": 2}},
	"perfektionist": {"sv": ["Perfektionisten", "FÄLLD med ett PERFEKT kast: x2,5 multi. Annars sur."], "en": ["The Perfectionist", "FELLED with a PERFECT throw: x2.5 mult. Otherwise sulks."],
		"price": 6, "col": Color(1.4, 1.4, 1.4), "score": {"perfect_xmult": 2.5}},
	"kedjekubb": {"sv": ["Kedjekubben", "FÄLLD: +2 multi för varje kubb som faller i samma kast."], "en": ["Chain Kubb", "FELLED: +2 mult for every kubb that falls on the same throw."],
		"price": 6, "col": Color(0.8, 0.8, 0.9), "score": {"combo_mult": 2}},
	"tornet": {"sv": ["Kyrktornet", "Väger dubbelt. FÄLLD: +100 marker. Dong."], "en": ["The Steeple", "Weighs double. FELLED: +100 chips. Dong."],
		"price": 6, "col": Color(0.8, 0.75, 0.7), "mass": 2.0, "score": {"chips": 100}},
	"envis": {"sv": ["Envisa kubben", "+1 multi för varje kast som inte fäller något. Allt släpps loss när den fälls."], "en": ["Stubborn Kubb", "+1 mult for every throw that fells nothing. All of it is released when it falls."],
		"price": 5, "col": Color(1.1, 0.7, 0.6), "score": {"miss_grow": 1, "mult": 1}},
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
	"bumerang": {"sv": ["Bumerangen", "Svänger i luften. Missar du alla kubbar kommer den tillbaka och du får kasta igen."], "en": ["The Boomerang", "Curves in the air. Miss every kubb and it comes back so you can throw again."],
		"mass": 0.36, "power": 1.0, "push": 0.9, "boomerang": 1, "len": 0.9, "col": Color(1.4, 0.9, 0.5), "band": Color(0.2, 0.6, 1.0), "trail": Color(0.4, 0.8, 1.0)},
	"trepinnen": {"sv": ["Trepinnen", "MULTIKAST: varje kast blir tre pinnar i en solfjäder. -2 pinnar per tur."], "en": ["The Triple Stick", "MULTISHOT: every throw becomes three batons in a fan. -2 batons per turn."],
		"mass": 0.36, "power": 0.97, "push": 0.9, "multishot": 3, "batons_add": -2, "col": Color(1.0, 1.2, 0.8), "band": Color(0.9, 0.2, 0.9), "trail": Color(1.0, 0.5, 1.0)},
	"granatpinne": {"sv": ["Granatpinnen", "Exploderar när den slår i något. Vad som helst. Även marken."], "en": ["The Grenade Stick", "Explodes when it hits something. Anything. Even the ground."],
		"mass": 0.45, "power": 0.97, "push": 1.0, "grenade": 1.0, "col": Color(0.45, 0.55, 0.35), "band": Color(1.0, 0.4, 0.1), "trail": Color(1.0, 0.55, 0.2), "glow": 0.3, "unlock": ["wins", 1]},
	"malsokare": {"sv": ["Målsökaren", "Svänger själv mot närmaste kubb du får träffa. Lite fusk. Mycket kul."], "en": ["The Seeker", "Steers itself toward the nearest kubb you may hit. A bit of cheating. A lot of fun."],
		"mass": 0.4, "power": 1.0, "push": 1.0, "homing": 1.0, "col": Color(0.9, 0.4, 0.4), "band": Color(0.2, 1.0, 0.4), "trail": Color(0.4, 1.0, 0.5), "glow": 0.5, "unlock": ["kubbs", 25]},
	"sista_pinnen": {"sv": ["Den sista pinnen", "Bättre på allt. +1 pinne. Den viskar ditt namn."], "en": ["The Last Baton", "Better at everything. +1 baton. It whispers your name."],
		"mass": 0.5, "power": 1.05, "push": 1.5, "batons_add": 1, "green_mult": 1.2, "glow": 1.0, "col": Color(0.4, 0.1, 0.12), "band": Color(1.0, 0.85, 0.3), "trail": Color(1.0, 0.1, 0.1), "unlock": ["best_night", 4]},
}


## RUNOR sitter på dina 5 kubbar ovanpå kubbens kort, som Balatros
## förstärkningar, utgåvor och sigill. En av varje sort per kubb.
## Följer med hela runnen. Börjar slumpat.
##   kind: enh (förstärkning), ed (utgåva), seal (sigill)
##   chips/mult/xmult: poäng när kubben fälls
##   stand_xmult: så länge kubben står kvar (x multi på varje kast)
##   stand_teeth: tänder när din tur slutar om den står kvar
##   shatter: chans att krossas när den fälls (glas)
##   lucky, blood, risk, retrigger, draw, teeth
##   toss: när den kastas in (teeth, grow_chips, charge, baton_next, rune)
##   frost: motståndaren kastar sämre resten av matchen
const RUNES := {
	# förstärkningar
	"glas": {"kind": "enh", "price": 4, "col": Color(0.7, 1.1, 1.6), "xmult": 2.0, "shatter": 0.25,
		"sv": ["Glas", "x2 multi när den fälls. 1 på 4 att den krossas."], "en": ["Glass", "x2 mult when felled. 1 in 4 to shatter."]},
	"stal": {"kind": "enh", "price": 5, "col": Color(0.75, 0.8, 0.9), "stand_xmult": 1.5,
		"sv": ["Stålbeslag", "Så länge den STÅR: x1,5 multi på varje kast."], "en": ["Steel Plated", "While it STANDS: x1.5 mult on every throw."]},
	"guld": {"kind": "enh", "price": 4, "col": Color(1.8, 1.4, 0.3), "stand_teeth": 2,
		"sv": ["Guld", "+2 tänder när din tur slutar om den står kvar."], "en": ["Gold", "+2 teeth at the end of your turn if it still stands."]},
	"lycka": {"kind": "enh", "price": 4, "col": Color(0.5, 1.5, 0.6), "lucky": 1,
		"sv": ["Fyrklöver", "FÄLLD: 1 på 4 för +15 multi, 1 på 12 för +10 tänder."], "en": ["Four-Leaf", "FELLED: 1 in 4 for +15 mult, 1 in 12 for +10 teeth."]},
	"sten": {"kind": "enh", "price": 3, "col": Color(0.5, 0.5, 0.55), "chips": 50, "mass": 1.8,
		"sv": ["Sten", "+50 marker. Tung som en gravsten."], "en": ["Stone", "+50 chips. Heavy as a gravestone."]},
	"bonus": {"kind": "enh", "price": 2, "col": Color(0.5, 0.75, 1.6), "chips": 30,
		"sv": ["Bonus", "+30 marker när den fälls."], "en": ["Bonus", "+30 chips when felled."]},
	"multi": {"kind": "enh", "price": 3, "col": Color(1.6, 0.4, 0.35), "mult": 4,
		"sv": ["Multi", "+4 multi när den fälls."], "en": ["Mult", "+4 mult when felled."]},
	"barnsten": {"kind": "enh", "price": 4, "col": Color(1.6, 0.9, 0.3), "toss": {"grow_chips": 8},
		"sv": ["Bärnsten", "INKAST: +8 marker för alltid varje gång den landar."], "en": ["Amber", "TOSSED: +8 chips forever each time it lands."]},
	"blod": {"kind": "enh", "price": 4, "col": Color(1.2, 0.1, 0.12), "blood": 1,
		"sv": ["Blod", "FÄLLD: +1 multi per kubb du fällt i matchen."], "en": ["Blood", "FELLED: +1 mult per kubb you've felled this match."]},
	"fjader": {"kind": "enh", "price": 5, "col": Color(1.5, 1.5, 1.5), "toss": {"baton_next": 1},
		"sv": ["Fjäder", "INKAST: +1 pinne nästa tur."], "en": ["Feather", "TOSSED: +1 baton next turn."]},
	"ekorre": {"kind": "enh", "price": 3, "col": Color(1.3, 0.6, 0.3), "toss": {"teeth": 2},
		"sv": ["Ekorre", "INKAST: +2 tänder. Den hade dem i kinderna."], "en": ["Squirrel", "TOSSED: +2 teeth. It kept them in its cheeks."]},
	"frost": {"kind": "enh", "price": 4, "col": Color(0.8, 1.3, 1.8), "frost": 1.12, "chips": 10,
		"sv": ["Frost", "FÄLLD: +10 marker, och han kastar 12 % sämre resten av matchen."], "en": ["Frost", "FELLED: +10 chips, and he throws 12% worse for the rest of the match."]},
	"mane": {"kind": "enh", "price": 4, "col": Color(1.4, 0.3, 0.3), "toss": {"charge": 3},
		"sv": ["Blodmåne", "INKAST: nästa kast som fäller får +3 multi."], "en": ["Blood Moon", "TOSSED: your next scoring throw gets +3 mult."]},
	# utgåvor
	"folie": {"kind": "ed", "price": 4, "col": Color(0.6, 0.8, 1.6), "chips": 50,
		"sv": ["Folie", "UTGÅVA. +50 marker. Glittrar som en sjö."], "en": ["Foil", "EDITION. +50 chips. Glitters like a lake."]},
	"holo": {"kind": "ed", "price": 5, "col": Color(1.4, 0.6, 1.6), "mult": 10,
		"sv": ["Holografisk", "UTGÅVA. +10 multi. Den skiftar färg när du inte tittar."], "en": ["Holographic", "EDITION. +10 mult. It shifts colour when you look away."]},
	"poly": {"kind": "ed", "price": 7, "col": Color(1.6, 1.6, 0.6), "xmult": 1.5,
		"sv": ["Polykrom", "UTGÅVA. x1,5 multi. Alla färger samtidigt."], "en": ["Polychrome", "EDITION. x1.5 mult. Every colour at once."]},
	"negativ": {"kind": "ed", "price": 5, "col": Color(0.3, 0.3, 0.35), "xmult": 2.0, "risk": 3,
		"sv": ["Negativ", "UTGÅVA. x2 multi, men 1 på 6 att den biter dig för 3 tänder."], "en": ["Negative", "EDITION. x2 mult, but 1 in 6 it bites you for 3 teeth."]},
	# sigill
	"rott": {"kind": "seal", "price": 6, "col": Color(1.6, 0.2, 0.2), "retrigger": 1,
		"sv": ["Rött sigill", "SIGILL. Allt kubben ger när den fälls triggar två gånger."], "en": ["Red Seal", "SEAL. Everything the kubb gives when felled triggers twice."]},
	"blatt": {"kind": "seal", "price": 5, "col": Color(0.3, 0.5, 1.6), "draw": 1,
		"sv": ["Blått sigill", "SIGILL. FÄLLD: du får dra ett extra kort."], "en": ["Blue Seal", "SEAL. FELLED: you draw an extra card."]},
	"guldsigill": {"kind": "seal", "price": 4, "col": Color(1.7, 1.3, 0.2), "teeth": 3,
		"sv": ["Guldsigill", "SIGILL. FÄLLD: +3 tänder."], "en": ["Gold Seal", "SEAL. FELLED: +3 teeth."]},
	"lila": {"kind": "seal", "price": 5, "col": Color(1.0, 0.3, 1.5), "toss": {"rune": 1},
		"sv": ["Lila sigill", "SIGILL. INKAST: kubben får en ny slumpad förstärkning."], "en": ["Purple Seal", "SEAL. TOSSED: the kubb gets a new random enhancement."]},
}

## FÖRSVARSKORT sitter på dina 5 kubbar på DIN baslinje (den han kastar på).
## Triggar bara när HAN träffar eller fäller kubben.
##   hit: taggar (han tappar en pinne), spegel (pinnen studsar tillbaka),
##        mossa (pinnen fastnar), spoke (kubben flyttar sig)
##   fell: skold (reser sig en gång per tur), hamnd (+multi laddat),
##         falla (blixt fäller en av hans), blackfisk (han tappar en pinne)
##   after: rotter (reser sig efter hans tur, 1 på 2)
##   passiv: vakt (han kastar sämre medan den står), ek (tung),
##           bastion (tänder om alla försvarskubbar står efter hans tur)
const DEFENSE := {
	"skold": {"price": 6, "col": Color(0.6, 0.75, 1.5), "sv": ["Sköld", "Första gången han fäller den varje tur reser den sig igen."], "en": ["Shield", "The first time he fells it each turn, it stands back up."]},
	"ek": {"price": 4, "col": Color(0.7, 0.5, 0.3), "mass": 3.0, "sv": ["Ek", "Väger tre gånger så mycket. Han får svettas."], "en": ["Oak", "Weighs three times as much. Let him sweat."]},
	"taggar": {"price": 5, "col": Color(0.4, 0.9, 0.35), "sv": ["Taggar", "När han träffar den tappar han en av sina pinnar."], "en": ["Thorns", "When he hits it he loses one of his batons."]},
	"spegel": {"price": 6, "col": Color(1.4, 1.4, 1.6), "sv": ["Spegel", "Hans pinne studsar tillbaka mot honom. Han ser sig själv."], "en": ["Mirror", "His baton bounces back at him. He sees himself."]},
	"rotter": {"price": 5, "col": Color(0.5, 0.35, 0.2), "sv": ["Rötter", "Ligger den efter hans tur reser den sig själv, 1 på 2."], "en": ["Roots", "If it's down after his turn, it stands up by itself, 1 in 2."]},
	"hamnd": {"price": 4, "col": Color(1.4, 0.2, 0.2), "sv": ["Hämnd", "När han fäller den: ditt nästa kast som fäller får +6 multi."], "en": ["Revenge", "When he fells it: your next scoring throw gets +6 mult."]},
	"vakt": {"price": 6, "col": Color(1.2, 1.0, 0.4), "sv": ["Vakt", "Så länge den står kastar han 15 % sämre. Den stirrar."], "en": ["Sentry", "While it stands he throws 15% worse. It stares."]},
	"falla": {"price": 5, "col": Color(0.9, 0.6, 0.2), "sv": ["Fälla", "När han fäller den slår blixten ner på en av hans kubbar."], "en": ["Trap", "When he fells it, lightning strikes one of his kubbs."]},
	"blackfisk": {"price": 5, "col": Color(0.3, 0.3, 0.6), "sv": ["Bläckfisk", "När han fäller den sprutar den bläck. Han tappar en pinne."], "en": ["Squid", "When he fells it, it squirts ink. He loses a baton."]},
	"mossa": {"price": 4, "col": Color(0.45, 0.8, 0.4), "sv": ["Mossa", "Hans pinne fastnar i mossan och dör där."], "en": ["Moss", "His baton gets stuck in the moss and dies there."]},
	"spoke": {"price": 6, "col": Color(0.85, 0.9, 1.3), "sv": ["Spökkubb", "När han träffar den försvinner den och dyker upp någon annanstans."], "en": ["Ghost Kubb", "When he hits it, it vanishes and reappears elsewhere."]},
	"bastion": {"price": 5, "col": Color(0.8, 0.8, 0.85), "sv": ["Bastion", "+4 tänder om alla dina försvarskubbar står kvar efter hans tur."], "en": ["Bastion", "+4 teeth if all your defended kubbs still stand after his turn."]},
}


## Varje kubbkort har också ett försvar (när kortets kubb står på DIN
## baslinje och han kastar på den). Ett eget "def" i kortet vinner,
## annars väljs ett efter vad kortet gör.
static func def_of(id: String) -> String:
	if not DEFS.has(id):
		return ""
	var d: Dictionary = DEFS[id]
	if d.has("def"):
		return d.def
	var h: Dictionary = d.get("hit", {})
	var f: Dictionary = d.get("fell", {})
	var m: Dictionary = d.get("mods", {})
	if m.has("king_shield") or f.has("shield"):
		return "skold"
	if float(d.get("mass", 1.0)) > 1.0:
		return "ek"
	if m.has("opp_error_mult") or m.has("opp_batons_add"):
		return "vakt"
	if h.has("boom") or h.has("zap") or f.has("zap"):
		return "falla"
	if h.has("bounce") or h.has("chain"):
		return "spegel"
	if h.has("teleport") or h.has("wind"):
		return "spoke"
	if f.has("baton") or f.has("opp_skip"):
		return "blackfisk"
	if d.has("toss"):
		return "rotter"
	if d.has("score"):
		return "hamnd"
	if f.has("teeth") or f.has("steal") or f.has("gamble"):
		return "bastion"
	if d.get("cursed", false):
		return "taggar"
	var all := ["mossa", "taggar", "rotter", "skold", "vakt", "hamnd"]
	return all[absi(id.hash()) % all.size()]


static func def_title(id: String) -> String:
	return DEFENSE[id][Lang.current][0]


static func def_desc(id: String) -> String:
	return DEFENSE[id][Lang.current][1]


## PINNKORT: dras under matchen. Dina nästa pinnar blir specialpinnar.
const PINNKORT := {
	"pk_granat": ["granatpinne", 2], "pk_bumerang": ["bumerang", 2], "pk_tre": ["trepinnen", 1],
	"pk_malsok": ["malsokare", 2], "pk_krut": ["krutpinne", 2], "pk_ask": ["askpinne", 2],
	"pk_jarn": ["jarnpinne", 2], "pk_gummi": ["gummipinne", 3], "pk_istapp": ["istappen", 2],
	"pk_domino": ["dominopinne", 2], "pk_krak": ["kraknabb", 2], "pk_sista": ["sista_pinnen", 1],
}


static func rune_title(id: String) -> String:
	return RUNES[id][Lang.current][0]


static func rune_desc(id: String) -> String:
	return RUNES[id][Lang.current][1]


static func runes_of(kind: String) -> Array[String]:
	var out: Array[String] = []
	for id in RUNES:
		if RUNES[id].kind == kind:
			out.append(id)
	return out


static func pk_title(id: String) -> String:
	var p: Array = PINNKORT[id]
	return "%dx %s" % [p[1], title(p[0])]


static func pk_desc(id: String) -> String:
	var p: Array = PINNKORT[id]
	var sv := Lang.current == "sv"
	return ("Dina nästa %d pinnar: " if sv else "Your next %d batons: ") % p[1] + desc(p[0])


static func kdef(id: String) -> Dictionary:
	return DEFS.get(id, OPP_DEFS.get(id, {}))


static func title(id: String) -> String:
	var d: Dictionary = DEFS.get(id, OPP_DEFS.get(id, BATONS.get(id, {})))
	return d.get(Lang.current, ["?", ""])[0]


static func desc(id: String) -> String:
	var d: Dictionary = DEFS.get(id, OPP_DEFS.get(id, BATONS.get(id, {})))
	var t: String = d.get(Lang.current, ["?", ""])[1]
	if DEFS.has(id) and not d.has("score"):
		t += score_text(score_of(id))
	if DEFS.has(id):
		var df := def_of(id)
		t += (" FÖRSVAR: " if Lang.current == "sv" else " DEFENSE: ") + def_title(df) + "."
	return t


## Vad kubben ger till poängräkningen när den fälls. De nya poängkubbarna
## har egna värden, alla äldre kort får ett efter sin sort.
static func score_of(id: String) -> Dictionary:
	if not DEFS.has(id):
		return {}
	var d: Dictionary = DEFS[id]
	if d.has("score"):
		return d.score
	if d.get("cursed", false):
		return {"xmult": 2.0}
	if d.has("hit"):
		return {"chips": 20, "mult": 2}
	if d.has("fell"):
		return {"chips": 30}
	return {"mult": 3}


static func score_text(sc: Dictionary) -> String:
	var sv := Lang.current == "sv"
	var parts: Array[String] = []
	if sc.has("chips"):
		parts.append(("+%d marker" if sv else "+%d chips") % int(sc.chips))
	if sc.has("mult"):
		parts.append("+%d multi" % int(sc.mult) if sv else "+%d mult" % int(sc.mult))
	if sc.has("xmult"):
		parts.append("x%s multi" % str(sc.xmult) if sv else "x%s mult" % str(sc.xmult))
	if parts.is_empty():
		return ""
	return (" POÄNG: " if sv else " SCORE: ") + ", ".join(parts) + "."


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
