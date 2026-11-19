# Sista kubben

Läskig (men mest rolig) roguelike-kubb i PS1-stil. Haunted midsommar: en äng i skymningen under en blodröd måne, och Vedgubben väntar på andra sidan planen.

Det här är **kastprototypen**: en runda med 6 pinnar mot Vedgubbens 5 baslinjekubbar, med kungen i mitten. Allt annat (kort, tänder, akter, fler motståndare, motståndarens kast) byggs ovanpå.

## Kör spelet

1. Ladda ner [Godot 4.3 eller senare](https://godotengine.org/download) (vanliga versionen, inte .NET).
2. Öppna Godot, välj **Import** och peka på `project.godot` i den här mappen.
3. Tryck **F5** (eller Play uppe till höger).

## Så kastar du

| Gör | Vad händer |
| --- | --- |
| Flytta musen i sidled | Sikta (den ljusa linjen på marken) |
| Håll vänster knapp och dra **ner** | Armen svingar bakåt, du tar sats |
| Svep **upp** och släpp | Kastet. Snabbare svep = hårdare kast |
| Släpp tidigt i svepet | Lågt, platt kast |
| Släpp sent | Högt lobbkast (släpp för sent och den åker mot månen) |
| Sneda/ryckiga svep | Sidofart och snurr runt lodlinjen, i värsta fall **helikopterkast** som är ogiltigt |
| Höger musknapp | Zooma blicken |
| A / D | Gå längs baslinjen |
| + / - | Musens känslighet |
| R | Ny runda |
| L | Byt språk (svenska/engelska) |

Regler som redan gäller: helikopterkast är ogiltiga (kubbar som fälldes av kastet ställs tillbaka), och fäller du kungen innan alla baskubbar ligger så förlorar du.

## Hur det är byggt

- `scripts/throw_controller.gd`: armen och kastet. Armvinkeln följer musen, och vid släpp får pinnen armens fart och vinkel, plus ände-över-ände-snurr. Allt efter det är ren fysik (Godots RigidBody, 120 fysiktick per sekund).
- `scripts/baton.gd`: kastpinnen (30 cm, 4,4 cm diameter) som räknar hur mycket den snurrar runt lodlinjen i luften för att upptäcka helikopterkast.
- `scripts/kubb.gd`: kubbar (7x7x15 cm) och kungen (9x9x30 cm) med riktiga mått och vikter.
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
