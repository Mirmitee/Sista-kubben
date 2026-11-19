# Sista kubben

Läskig (men mest rolig) roguelike-kubb i PS1-stil. Haunted midsommar: en äng i skymningen under en blodröd måne, och Vedgubben väntar på andra sidan planen.

Version **v0.7**: runs över tre nätter med riktiga kubbregler, en kubblek med 50 specialkubbar, 30 pinnar att låsa upp och ett träningsläge där du kastar på Gösta, en ful hund som ingen äger.

## Kör spelet

1. Installera [Godot 4.3 eller senare](https://godotengine.org/download) (vanliga versionen, inte .NET). Testat mot 4.3, öppnas i 4.7.
2. Öppna Godot, välj **Import** och peka på `project.godot` i den här mappen.
3. Tryck **F5** (eller Play uppe till höger).

## En run

- **Tre nätter, två matcher per natt:** Vedgubben och sen bossen Tjock-Leffe, som äter upp en av dina pinnar varje tur. Natten gör motståndarna bättre. Förlorar du är hela runnen slut.
- **Riktiga kubbregler:** du kastar dina pinnar, motståndaren kastar in kubbarna du fällde på din planhalva (fältkubbar) och kastar sen sina pinnar på dig. Fältkubbar måste fällas först. Står fältkubbar kvar efter en tur får den andra kliva fram och kasta från linjen genom den fältkubb som står närmast mitten (röd linje på marken). Motståndaren går alltid på fältkubbarna först. Kubbar han fäller kastar du in på hans planhalva (ett klick för kraft). När alla kubbar på en planhalva ligger får man kasta på kungen. Rör man kungen för tidigt dör man, och gör han det vinner du.
- **Tänder:** för fällda kubbar, kombos (flera kubbar på ett kast), perfekta kast, kungen och vunna matcher.
- **Kubbleken (istället för kort):** upp till 5 specialkubbar. Varje match ställs de upp på motståndarens baslinje, och när du träffar eller fäller dem händer saker: Krutkubben exploderar, Dominokubben drar med sig grannarna, Åskkubben kallar på blixten, Tandkubben är full av tänder, Spökkubben flyr. Vissa har passiva effekter (fler pinnar, bredare grönt). Kubbarna följer med när de kastas in som fältkubbar, så samma kubb kan ge effekt flera gånger. 50 kubbar, varav 10 förbannade. Färg och runband visar vilken kubb det är; en spets ovanpå betyder träffeffekt, en platta betyder fällningseffekt.
- **Kråkmors bod** mellan matcherna: tre kubbar att köpa, en gratis förbannad kubb, nya kubbar för tänder, sälj kubbar.
- **30 pinnar** med egen vikt, längd, färg, spår, studs, svävning och specialeffekter (Krutpinnen, Åskpinnen, Fjäderpinnen, Leffes revben ...). De flesta låses upp mellan runs genom att vinna matcher, fälla kubbar, göra perfekta kast och kombos, tjäna tänder och besegra Leffe. Låsta pinnar visar vad som krävs.
- **Effekter:** träflisor vid träff, damm när pinnar och kubbar slår i marken, gnistor vid perfekta kast, explosioner, blixtar, konfetti när du vinner och ett blodrött utbrott när någon rör kungen.

## Så kastar du

**Mätare (standard), som i gamla RPG- och golfspel:** sikta med musen och klicka (eller mellanslag / A) tre gånger.
1. Första klicket: du tar sats och kraftmätaren fylls. Den töms igen om du väntar för länge.
2. Andra klicket: kraften låses. Det gröna fältet är kraften som når baslinjen.
3. Tredje klicket: en markör sveper över precisionsmätaren. Mitt i det gröna blir PERFEKT, längre ut blir kastet snett, och längst ut tappar du greppet (helikopter).

**Musdrag** (välj i Inställningar):

| Gör | Vad händer |
| --- | --- |
| Flytta musen i sidled | Sikta (den ljusa linjen på marken) |
| Håll vänster knapp och dra **ner** | Armen svingar bakåt, du tar sats |
| Svep **upp** och släpp | Kastet. Kraftmätaren visar hur hårt, sikta på det gröna fältet |
| Var i svepet du är snabbast | Bestämmer kastvinkeln. Det gör inget om du stannar innan du släpper |
| Sneda/ryckiga svep | Lite sidodrift, och riktigt sneda svep blir förbjudna **helikopterkast** |
| Höger musknapp | Zooma blicken |
| A / D | Gå längs baslinjen |
| Esc | Paus |
| R / H / L / F11 | Ny runda / tips / språk / helskärm |

Gamepad: vänster spak siktar, LB/RB går, håll A eller RT och dra höger spak ner och knuffa upp för att kasta. Start pausar.

Inställningar (sparas mellan gångerna): musens känslighet, kastkraft, volym, PS1-darr, helskärm, sikthjälp (markerar var förra pinnen landade), kraftmätare och tips.

## Hur det är byggt

- `scripts/throw_controller.gd`: armen och kastet. Armvinkeln följer musen, och vid släpp får pinnen armens fart och vinkel, plus ände-över-ände-snurr. Allt efter det är ren fysik (Godots RigidBody, 120 fysiktick per sekund).
- `scripts/baton.gd`: kastpinnen (30 cm, 4,4 cm diameter) som räknar hur mycket den snurrar runt lodlinjen i luften för att upptäcka helikopterkast.
- `scripts/kubb.gd`: kubbar (7x7x15 cm) och kungen (9x9x30 cm) med riktiga mått och vikter.
- `scripts/ui/menu.gd` och `scripts/ui/hud.gd`: menyer och allt på skärmen. `scripts/settings.gd` sparar inställningar, `scripts/sfx.gd` syntar alla ljud i kod.
- `scripts/dog.gd`: Gösta.
- `scripts/opponents/`: motståndare. `opponent.gd` är basen (repliker på två språk, huvudet följer pinnen), `vedgubben.gd` är den första. Tjock-Leffe, Birgit, Leif och Mummlan läggs till bredvid.
- `scripts/world.gd`: ängen, björkarna, midsommarstången, himlen och månen.
- `shaders/ps1.gdshader`: PS1-looken. Darrande vertexar, affin (skev) texturmappning, vertexljus, dimma och 15-bitars färg med dithering. Spelet renderas i 384x288 och skalas upp.
- Alla texturer ritas i kod (`scripts/ps1.gd`) i 32x32, så det finns inga bildfiler än.

## Testa utan att spela

```sh
godot --headless --fixed-fps 120 --path . -- --autotest          # några kast, skriver ut resultat
godot --headless --fixed-fps 120 --path . -- --autotest --sweep  # svep över kastfarter
godot --rendering-driver opengl3 --path . -- --shot=/tmp/bild     # tre skärmdumpar
```
