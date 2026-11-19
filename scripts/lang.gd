## Språk: svenska och engelska. Byt med L (senare i menyn).
## Repliker per motståndare ligger i opponent-skripten, UI-text här.
extends Node

signal changed

var current := "sv"

const UI := {
	"title": {"sv": "SISTA KUBBEN", "en": "THE LAST KUBB"},
	"subtitle": {"sv": "kastprototyp", "en": "throw prototype"},
	"hud": {"sv": "PINNAR %d/%d   FÄLLDA %d/%d", "en": "BATONS %d/%d   DOWN %d/%d"},
	"sens": {"sv": "KÄNSLIGHET %.1f", "en": "SENSITIVITY %.1f"},
	"last": {"sv": "SENASTE: %.1f m/s, %d°, %.1f m", "en": "LAST: %.1f m/s, %d°, %.1f m"},
	"hint1": {"sv": "Sikta med musen. Håll vänster knapp:", "en": "Aim with the mouse. Hold left button:"},
	"hint2": {"sv": "dra NER = ta sats, svep UPP = kasta", "en": "drag DOWN = wind up, swipe UP = throw"},
	"hint3": {"sv": "A/D flytta  högerklick zooma  +/- känslighet  R ny runda  L språk", "en": "A/D move  right-click zoom  +/- sensitivity  R new round  L language"},
	"heli": {"sv": "HELIKOPTERKAST! OGILTIGT", "en": "HELICOPTER THROW! INVALID"},
	"round_over": {"sv": "RUNDAN SLUT: %d/%d FÄLLDA\nR = NY RUNDA", "en": "ROUND OVER: %d/%d DOWN\nR = NEW ROUND"},
	"all_down": {"sv": "ALLA BASKUBBAR FÄLLDA!\nNu får du sikta på kungen.\nR = NY RUNDA", "en": "ALL BASE KUBBS DOWN!\nNow you may go for the king.\nR = NEW ROUND"},
	"king_early": {"sv": "DU FÄLLDE KUNGEN FÖR TIDIGT.\nDU FÖRLORAR.\nR = FÖRSÖK IGEN", "en": "YOU FELLED THE KING TOO EARLY.\nYOU LOSE.\nR = TRY AGAIN"},
	"king_win": {"sv": "KUNGEN ÄR FÄLLD. DU VANN.\n...den här gången.\nR = NY RUNDA", "en": "THE KING HAS FALLEN. YOU WIN.\n...this time.\nR = NEW ROUND"},
}


func t(key: String) -> String:
	var e: Dictionary = UI.get(key, {})
	return e.get(current, key)


func toggle() -> void:
	current = "en" if current == "sv" else "sv"
	changed.emit()
