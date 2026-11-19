## Alla kort. Varje kort har modifierare som Run.mod() summerar.
## Nycklar:
##   batons_add        +/- pinnar per tur
##   meter_time_mult   kraftmätarens tid (högre = långsammare = lättare)
##   acc_time_mult     precisionsmarkörens tid
##   green_mult        bredd på gröna fältet
##   power_mult        kastkraft
##   push_mult         hur hårt träffar knuffar kubbar
##   teeth_kubb_add    tänder per fälld kubb
##   combo_mult        multiplikator för kombotänder
##   king_shield       antal gånger kungen tål en träff per match
##   opp_error_mult    motståndarens fel
##   no_aim_line       ingen siktlinje (1 = på)
##   no_move           kan inte gå längs baslinjen
##   last_baton_mult   tandmultiplikator på turens sista pinne
##   other_baton_mult  tandmultiplikator på övriga pinnar
##   perfect_teeth     extra tänder för perfekt kast
##   bell              var tredje tur välter en slumpad motståndarkubb
##   toss_forgive      kubbar du kastar över utanför planen läggs in ändå
##   win_teeth_add     extra tänder när du vinner en match
class_name Cards
extends RefCounted

const DEFS := {
	# ---------------------------------------------------------- vanliga
	"bjorkpinne": {"sv": ["Björkkvist", "+1 pinne per tur."], "en": ["Birch Twig", "+1 baton per turn."],
		"price": 6, "mods": {"batons_add": 1}},
	"krakfjader": {"sv": ["Kråkfjäder", "Precisionsmarkören går 30 % långsammare."], "en": ["Crow Feather", "Accuracy cursor moves 30% slower."],
		"price": 4, "mods": {"acc_time_mult": 1.3}},
	"midsommarstang": {"sv": ["Midsommarstång", "Gröna fältet är 50 % bredare."], "en": ["Maypole", "The green zone is 50% wider."],
		"price": 5, "mods": {"green_mult": 1.5}},
	"ostkaka": {"sv": ["Ostkaka", "Kraftmätaren fylls 25 % långsammare."], "en": ["Cheesecake", "The power meter fills 25% slower."],
		"price": 3, "mods": {"meter_time_mult": 1.25}},
	"tjarpinne": {"sv": ["Tjärdoppad pinne", "Träffar knuffar dubbelt så hårt."], "en": ["Tar-Dipped Baton", "Hits push twice as hard."],
		"price": 5, "mods": {"push_mult": 2.0}},
	"sill": {"sv": ["Sill i fickan", "+1 tand per fälld kubb. Luktar."], "en": ["Herring in Pocket", "+1 tooth per felled kubb. Smells."],
		"price": 4, "mods": {"teeth_kubb_add": 1}},
	"dubbelklonk": {"sv": ["Dubbelklonk", "Kombotänder x2."], "en": ["Double Clonk", "Combo teeth x2."],
		"price": 6, "mods": {"combo_mult": 2.0}},
	"kungens_nad": {"sv": ["Kungens nåd", "Kungen tål en träff per match."], "en": ["King's Mercy", "The king forgives one hit per match."],
		"price": 7, "mods": {"king_shield": 1}},
	"grannens_oga": {"sv": ["Grannens öga", "Motståndaren kastar 40 % sämre. Han känner sig iakttagen."], "en": ["Neighbour's Eye", "Opponent throws 40% worse. He feels watched."],
		"price": 6, "mods": {"opp_error_mult": 1.4}},
	"perfektionist": {"sv": ["Perfektionist", "+2 tänder för varje PERFEKT kast."], "en": ["Perfectionist", "+2 teeth for every PERFECT throw."],
		"price": 4, "mods": {"perfect_teeth": 2}},
	"nubbe": {"sv": ["Nubbe", "+10 % kastkraft. Hej tomtegubbar."], "en": ["Schnapps", "+10% throw power. Skål."],
		"price": 3, "mods": {"power_mult": 1.1}},
	"myrstack": {"sv": ["Myrstack", "Kubbar du kastar utanför planen läggs in ändå."], "en": ["Anthill", "Kubbs you toss out of bounds are placed in anyway."],
		"price": 3, "mods": {"toss_forgive": 1}},
	# ---------------------------------------------------------- upplåsbara
	"kyrkklocka": {"sv": ["Kyrkklocka", "Var tredje tur välter en slumpad motståndarkubb."], "en": ["Church Bell", "Every third turn a random enemy kubb falls."],
		"price": 8, "mods": {"bell": 1}, "locked": true},
	"guldtand": {"sv": ["Guldtand", "+6 tänder när du vinner en match."], "en": ["Gold Tooth", "+6 teeth when you win a match."],
		"price": 5, "mods": {"win_teeth_add": 6}, "locked": true},
	"dalahast": {"sv": ["Dalahäst", "+2 pinnar per tur. Den sparkas."], "en": ["Dala Horse", "+2 batons per turn. It kicks."],
		"price": 11, "mods": {"batons_add": 2}, "locked": true},
	# ---------------------------------------------------------- förbannade
	"din_tumme": {"sv": ["Din tumme", "FÖRBANNAD. +3 tänder per kubb, men markören går 40 % fortare."], "en": ["Your Thumb", "CURSED. +3 teeth per kubb, but the cursor is 40% faster."],
		"price": 0, "cursed": true, "mods": {"teeth_kubb_add": 3, "acc_time_mult": 0.6}},
	"sista_pinnen": {"sv": ["Den sista pinnen", "FÖRBANNAD. Turens sista pinne ger x4 tänder, alla andra ger 0."], "en": ["The Last Baton", "CURSED. Last baton of a turn gives x4 teeth, all others 0."],
		"price": 0, "cursed": true, "mods": {"last_baton_mult": 4.0, "other_baton_mult": 0.0}},
	"gammal_sill": {"sv": ["Gammal sill", "FÖRBANNAD. -1 pinne per tur, men +4 tänder per fälld kubb."], "en": ["Old Herring", "CURSED. -1 baton per turn, but +4 teeth per felled kubb."],
		"price": 0, "cursed": true, "mods": {"batons_add": -1, "teeth_kubb_add": 4}},
	"grot_i_skon": {"sv": ["Gröt i skon", "FÖRBANNAD. Du kan inte gå längs baslinjen, men +1 pinne."], "en": ["Porridge in Shoe", "CURSED. You can't walk the baseline, but +1 baton."],
		"price": 0, "cursed": true, "mods": {"no_move": 1, "batons_add": 1}},
	"mormors_glasogon": {"sv": ["Mormors glasögon", "FÖRBANNAD. Ingen siktlinje, men gröna fältet är dubbelt så brett."], "en": ["Grandma's Glasses", "CURSED. No aim line, but the green zone is twice as wide."],
		"price": 0, "cursed": true, "mods": {"no_aim_line": 1, "green_mult": 2.0}},
	"vedgubbens_skuld": {"sv": ["Vedgubbens skuld", "FÖRBANNAD. +8 tänder per vinst, men motståndaren kastar 20 % bättre."], "en": ["The Woodman's Debt", "CURSED. +8 teeth per win, but the opponent throws 20% better."],
		"price": 0, "cursed": true, "mods": {"win_teeth_add": 8, "opp_error_mult": 0.8}},
}

## Pinnar man väljer vid start av en run.
const BATONS := {
	"vanlig": {"sv": ["Vanlig pinne", "Ek. Pålitlig. Tråkig."], "en": ["Plain Baton", "Oak. Reliable. Boring."],
		"mass": 0.42, "power": 1.0, "push": 1.0},
	"jarnpinne": {"sv": ["Järnpinne", "Tung. Kortare kast, men allt den rör välter."], "en": ["Iron Baton", "Heavy. Shorter throws, but everything it touches falls."],
		"mass": 0.9, "power": 0.9, "push": 2.2, "locked": true},
	"bjorkpinne": {"sv": ["Björkpinne", "Lätt. Flyger långt, knuffar lite."], "en": ["Birch Baton", "Light. Flies far, pushes little."],
		"mass": 0.3, "power": 1.12, "push": 0.8, "locked": true},
	"benpinne": {"sv": ["Benpinne", "Gjord av något. +1 pinne per tur, men varje kast kostar en tand."], "en": ["Bone Baton", "Made of something. +1 baton per turn, but every throw costs a tooth."],
		"mass": 0.45, "power": 1.0, "push": 1.3, "batons_add": 1, "tooth_cost": 1, "locked": true},
}


static func title(id: String) -> String:
	var d: Dictionary = DEFS.get(id, BATONS.get(id, {}))
	return d.get(Lang.current, ["?", ""])[0]


static func desc(id: String) -> String:
	var d: Dictionary = DEFS.get(id, BATONS.get(id, {}))
	return d.get(Lang.current, ["?", ""])[1]
