## Språk: svenska och engelska. Byt med L (senare i menyn).
## Repliker per motståndare ligger i opponent-skripten, UI-text här.
extends Node

signal changed

var current := "sv"

const UI := {
	"title": {"sv": "SISTA KUBBEN", "en": "THE LAST KUBB"},
	"subtitle": {"sv": "kastprototyp", "en": "throw prototype"},
	"hud": {"sv": "PINNAR KVAR %d/%d", "en": "BATONS LEFT %d/%d"},
	"kubbs": {"sv": "KUBBAR", "en": "KUBBS"},
	"training_hud": {"sv": "TRÄNING   TRÄFFAR PÅ GÖSTA: %d", "en": "PRACTICE   HITS ON GÖSTA: %d"},
	"meter": {"sv": "KRAFT   VINKEL %d°", "en": "POWER   ANGLE %d°"},
	"meter_idle": {"sv": "KRAFT", "en": "POWER"},
	"summary": {"sv": "Fällda %d på %d kast. Längsta %.1f m. Helikoptrar %d.", "en": "Felled %d in %d throws. Longest %.1f m. Helicopters %d."},
	"last": {"sv": "SENASTE: %.1f m/s, %d°, %.1f m", "en": "LAST: %.1f m/s, %d°, %.1f m"},
	"hint_meter1": {"sv": "Sikta med musen. Klicka (eller mellanslag) tre gånger:", "en": "Aim with the mouse. Click (or space) three times:"},
	"hint_meter2": {"sv": "1 ta sats, 2 lås kraften i gröna, 3 släpp mitt i.", "en": "1 wind up, 2 lock power in the green, 3 release dead centre."},
	"unlocked": {"sv": "UPPLÅST:", "en": "UNLOCKED:"},
	"night": {"sv": "NATT %d AV %d", "en": "NIGHT %d OF %d"},
	"bell": {"sv": "KYRKKLOCKAN SLÅR. EN KUBB FALLER.", "en": "THE CHURCH BELL TOLLS. A KUBB FALLS."},
	"king_mercy": {"sv": "KUNGENS NÅD! DEN HÄR GÅNGEN.", "en": "KING'S MERCY! THIS TIME."},
	"field_first": {"sv": "FÄLTKUBBAR FÖRST! BASKUBBEN RESES.", "en": "FIELD KUBBS FIRST! BASE KUBB RAISED."},
	"advance": {"sv": "FÄLTKUBBAR STÅR KVAR! DU KLIVER FRAM TILL LINJEN.", "en": "FIELD KUBBS STILL STANDING! YOU STEP UP TO THE LINE."},
	"opp_advance": {"sv": "DU MISSADE FÄLTKUBBARNA. HAN KLIVER FRAM.", "en": "YOU MISSED THE FIELD KUBBS. HE STEPS UP."},
	"combo": {"sv": "KOMBO x%d", "en": "COMBO x%d"},
	"king_bonus": {"sv": "KUNGEN!", "en": "THE KING!"},
	"teeth": {"sv": "TÄNDER", "en": "TEETH"},
	"teeth_hud": {"sv": "TÄNDER %d   NATT %d/%d", "en": "TEETH %d   NIGHT %d/%d"},
	"toss_out": {"sv": "UTANFÖR! OM IGEN.", "en": "OUT! AGAIN."},
	"toss_now": {"sv": "KASTA IN KUBBEN PÅ HANS PLANHALVA", "en": "TOSS THE KUBB INTO HIS HALF"},
	"win_title": {"sv": "VINST! +%d TÄNDER", "en": "VICTORY! +%d TEETH"},
	"lost_title": {"sv": "DU FÖRLORADE.", "en": "YOU LOST."},
	"lost_sub": {"sv": "Han fällde din kung. Ängen behåller dig.", "en": "He felled your king. The meadow keeps you."},
	"phase_you": {"sv": "DIN TUR: KASTA PINNAR", "en": "YOUR TURN: THROW BATONS"},
	"phase_toss_you": {"sv": "DIN TUR: KASTA IN KUBBAR (1 klick = kraft)", "en": "YOUR TURN: TOSS KUBBS (1 click = power)"},
	"phase_opp_toss": {"sv": "%s KASTAR IN KUBBAR", "en": "%s TOSSES KUBBS"},
	"phase_opp": {"sv": "%s KASTAR", "en": "%s THROWS"},
	"kubbs_line": {"sv": "HANS KUBBAR %d (FÄLT %d)   DINA %d (FÄLT %d)", "en": "HIS KUBBS %d (FIELD %d)   YOURS %d (FIELD %d)"},
	"death_title": {"sv": "DU DOG.", "en": "YOU DIED."},
	"death_restart": {"sv": "R = NY RUN    ESC = MENY", "en": "R = NEW RUN    ESC = MENU"},
	"grade_perfect": {"sv": "PERFEKT!", "en": "PERFECT!"},
	"grade_good": {"sv": "BRA", "en": "GOOD"},
	"grade_off": {"sv": "SNETT", "en": "WONKY"},
	"grade_fumble": {"sv": "TAPPADE GREPPET!", "en": "LOST YOUR GRIP!"},
	"meter_acc": {"sv": "PRECISION", "en": "ACCURACY"},
	"hint1": {"sv": "Sikta med musen. Håll vänster knapp:", "en": "Aim with the mouse. Hold left button:"},
	"hint2": {"sv": "dra NER, svep UPP. Sikta på gröna fältet.", "en": "drag DOWN, swipe UP. Aim for the green zone."},
	"hint3": {"sv": "A/D gå  högerklick zoom  Esc paus  H dölj tips", "en": "A/D walk  right-click zoom  Esc pause  H hide tips"},
	"heli": {"sv": "HELIKOPTERKAST! OGILTIGT", "en": "HELICOPTER THROW! INVALID"},
	"round_over": {"sv": "RUNDAN SLUT: %d/%d FÄLLDA\nR = NY RUNDA", "en": "ROUND OVER: %d/%d DOWN\nR = NEW ROUND"},
	"all_down": {"sv": "ALLA BASKUBBAR FÄLLDA!\nNu får du sikta på kungen.\nR = NY RUNDA", "en": "ALL BASE KUBBS DOWN!\nNow you may go for the king.\nR = NEW ROUND"},
	"king_early": {"sv": "DU FÄLLDE KUNGEN FÖR TIDIGT.\nDU FÖRLORAR.\nR = FÖRSÖK IGEN", "en": "YOU FELLED THE KING TOO EARLY.\nYOU LOSE.\nR = TRY AGAIN"},
	"king_win": {"sv": "KUNGEN ÄR FÄLLD. DU VANN.\n...den här gången.\nR = NY RUNDA", "en": "THE KING HAS FALLEN. YOU WIN.\n...this time.\nR = NEW ROUND"},
}


const POOLS := {
	"death_sub": {
		"sv": ["Du rörde kungen. Man rör inte kungen.", "Kungen tittade på dig. Sen var du borta.", "Dödsorsak: kubb.", "Din familj får en pinne och ett brev.", "Ängen tackar för din kropp. Den blir fin gödsel."],
		"en": ["You touched the king. One does not touch the king.", "The king looked at you. Then you were gone.", "Cause of death: kubb.", "Your family will receive a baton and a letter.", "The meadow thanks you for your body. It makes fine compost."],
	},
}


func pick(key: String) -> String:
	var arr: Array = POOLS.get(key, {}).get(current, [key])
	return arr[randi() % arr.size()]


func t(key: String) -> String:
	var e: Dictionary = UI.get(key, {})
	return e.get(current, key)


func toggle() -> void:
	current = "en" if current == "sv" else "sv"
	changed.emit()
