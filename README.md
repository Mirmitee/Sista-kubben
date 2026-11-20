# Sista kubben

Läskig (men mest rolig) roguelike-kubb i PS1-stil. Haunted midsommar: en äng i skymningen under en blodröd måne, och Vedgubben väntar på andra sidan planen.

Version **v0.15**: runs över tre nätter med riktiga kubbregler, en kubblek med 67 specialkubbar, 34 pinnar att låsa upp och ett träningsläge där du kastar på Gösta, en ful hund som ingen äger.

Nytt i v0.12-0.13 (grafik): 16:9, 640x360 internt uppskalat exakt 3x till ett 1920x1080-fönster, procedurella pixelart-kort (ditherad bakgrund, ram med hörnprydnader, ikon per korttyp) i scripts/ui/art.gd, pixelramar på alla paneler och knappar, och ordnad 4x4-dithering över 3D-bilden (shaders/dither.gdshader).

Nytt i v0.11 (Balatro-poäng):
- Varje kast som fäller räknas som MARKER x MULTI, en kubb i taget med stigande ton, eld ur rutorna och 3D-eld på kubbarna. Blodmånen kräver en poäng per match, och varje nivå (x1, x2, x4, x8, x16) ger tänder.
- 21 runor på dina 5 kubbar: 13 förstärkningar (glas, stål, guld, fyrklöver, sten, bonus, multi, bärnsten, blod, fjäder, ekorre, frost, blodmåne), 4 utgåvor (folie, holo, polykrom, negativ) och 4 sigill (rött, blått, guld, lila). Slumpas vid start av varje run.
- 17 poängkubbar som växer, triggar vid inkast eller ger x multi under villkor.
- 12 pinnkort: dina nästa pinnar blir granat, bumerang, trepinne m.m.
- Efter varje kast som fäller väljer du 1 av 3: ödeskort, pinnkort, runa eller ny kubb.
- Hans tur går 30 % fortare, håll F för att snabbspola x3.
- v0.15: uppställning vid matchstart (kubbarna släpps ner en i taget med kort och runor, klick snabbspolar), alla gamla kort ger marker/multi/x multi.
- v0.14: håll Tab för spelplanen uppifrån: var varje kubb står, numrerade dina kubbar med runfärg, hans specialkubbar i rött, plus listan över allt kubbarna bär.

## Kör spelet

1. Installera [Godot 4.3 eller senare](https://godotengine.org/download) (vanliga versionen, inte .NET). Testat mot 4.3, öppnas i 4.7.
2. Öppna Godot, välj **Import** och peka på `project.godot` i den här mappen.
3. Tryck **F5** (eller Play uppe till höger).

## En run

- **Karta:** varje natt väljer du väg genom fem steg: match (Vedgubben eller Birgit), Kråkmors bod, Ödesstenen (gratis ödeskort), Gravgården (gräv efter tänder eller begrav en kubb), en elitmatch (svårare, 50 % fler tänder) och sist bossen Tjock-Leffe, som äter upp en av dina pinnar varje tur. Natten gör motståndarna bättre, och de är svåra. Förlorar du är hela runnen slut.
- **Den oändliga natten:** klarar du tre nätter kan du fortsätta in i natt 4, 5, 6 ... så länge du överlever.
- **Birgit:** tant i midsommarklänning som stickar och nynnar (kraftmätaren går fortare) och stickar en extra pinne åt sig natt 2 och 3.
- **Hans specialkubbar:** motståndaren smyger in egna kubbar på sin baslinje (slump, fler senare nätter). De straffar dig: Taggkubben tar tänder, Kådakubben stoppar pinnen, Spegelvända fäller en av dina egna, Slukaren äter en pinne.
- **Riktiga kubbregler:** du kastar dina pinnar, motståndaren kastar in kubbarna du fällde på din planhalva (fältkubbar) och kastar sen sina pinnar på dig. Fältkubbar måste fällas först. Står fältkubbar kvar efter en tur får den andra kliva fram och kasta från linjen genom den fältkubb som står närmast mitten (röd linje på marken). Motståndaren går alltid på fältkubbarna först. Kubbar han fäller kastar du in på hans planhalva (ett klick för kraft). När alla kubbar på en planhalva ligger får man kasta på kungen. Rör man kungen för tidigt dör man, och gör han det vinner du.
- **Tänder:** för fällda kubbar, kombos (flera kubbar på ett kast), perfekta kast, kungen och vunna matcher.
- **Dina 5 kubbar och korten:** du har alltid 5 kubbar på hans baslinje (samma platser, vänster till höger). Varje kubb kan bära ett uppgraderingskort, och samma kort får sitta på flera kubbar. Korten ger effekter när du träffar eller fäller kubben (Krutkubben exploderar, Dominokubben drar med sig grannarna, Åskkubben kallar på blixten ...) eller passiva effekter (fler pinnar, bredare grönt). 50 kort, varav 10 förbannade. I boden köper du ett kort och väljer vilken kubb det ska sitta på.
- **Ödesleken:** du har en egen lek med ödeskort som du bygger på i boden (köp nya, bränn dåliga). För varje kubb du fäller drar du två kort och väljer ett. Korten kan ge en ny kubb till leken, en lånad pinne resten av matchen (även låsta), en extra pinne, tänder, dubbla tänder, en blixt, välsignelser eller förbannelser för matchen. Håll **Tab** under matchen för att se din lek, pinne och aktiva effekter.
- **Kråkmors bod** mellan matcherna: tre kubbar att köpa, en gratis förbannad kubb, nya kubbar för tänder, sälj kubbar.
- **34 pinnar** med egen vikt, längd, färg, spår, studs, svävning och specialeffekter (Bumerangen som kommer tillbaka om du missar, Trepinnen som kastar tre på en gång, Granatpinnen som exploderar mot allt, Målsökaren som svänger mot kubbarna, Krutpinnen, Åskpinnen, Leffes revben ...). De flesta låses upp mellan runs genom att vinna matcher, fälla kubbar, göra perfekta kast och kombos, tjäna tänder och besegra Leffe. Låsta pinnar visar vad som krävs.
- **Musik:** en spöklik dragspelsvals som spelar för långsamt och saktar ner ännu mer vid slowmotion.
- **Effekter:** träflisor vid träff, damm när pinnar och kubbar slår i marken, gnistor vid perfekta kast, explosioner, blixtar, konfetti när du vinner och ett blodrött utbrott när någon rör kungen.

**Förenklade regler:** 8 pinnar per tur, och fällda kubbar kastas bort istället för att kastas in fram och tillbaka. Inga fältkubbar.

## Så kastar du

**Siktmagnet** (med Sikthjälp på): siktar du nära en kubb du får träffa dras siktet in mot den, linjen blir grön och en ring snurrar runt kubben.

**Mätare (standard), som i gamla RPG- och golfspel:** sikta med musen och klicka (eller mellanslag / A) tre gånger.
1. Första klicket: du tar sats och kraftmätaren fylls. Den töms igen om du väntar för länge.
2. Andra klicket: kraften låses. Medan kraften fylls visar ett kors på marken var pinnen landar (grönt = vid hans baslinje, gult = kort, rött = långt), och det gröna fältet på mätaren flyttar sig när du kliver fram.
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
