# fraktion_manager

FiveM-Resource für die Anbindung deines ESX-Servers an den
[Fraktion Manager](https://fraktionmanager.com).

Sie hält Fraktionen und ESX-Jobs zusammen: Mitglieder, Ränge und der
Online-Status wandern automatisch ins Dashboard, und Einstellungen aus dem
Fraktion Helper landen umgekehrt direkt im Spiel.

## Voraussetzungen

- ESX Framework (`es_extended`)
- `oxmysql` oder `mysql-async`
- Ein Server im Fraktion Manager mit aktivierter FiveM Integration

## Einrichtung

Am schnellsten über das Dashboard, dort ist dein Token schon eingetragen:

1. Dashboard öffnen, deinen Server auswählen
2. **Config**, Abschnitt **FiveM Integration**, Schalter aktivieren
3. **fraktion_manager.zip** herunterladen
4. Den enthaltenen Ordner `fraktion_manager` nach `resources/` entpacken
5. In die `server.cfg` eintragen:
   ```
   ensure fraktion_manager
   ```
6. Server neu starten

Alternativ von GitHub, dann trägst du den Token selbst ein:

1. Neueste Version holen, als ZIP unter
   [Releases](https://github.com/blokify11/fraktion-manager-fivem/releases)
   oder per Git:
   ```
   git clone https://github.com/blokify11/fraktion-manager-fivem.git
   ```
2. Den Ordner `fraktion_manager` nach `resources/` kopieren
3. Token im Dashboard unter **Config**, **FiveM Integration** kopieren und in
   `fraktion_manager/config.lua` eintragen:
   ```lua
   Config.ApiToken = 'DEIN_TOKEN'
   ```
4. `ensure fraktion_manager` in die `server.cfg`, Server neu starten

Der Token enthält deine Server-ID, du musst sie nicht separat angeben. Er gilt
nur für deinen Server: gib ihn nicht weiter und veröffentliche ihn nicht.

## Konfiguration

| Option | Beschreibung | Standard |
|---|---|---|
| `Config.Enabled` | Integration an oder aus | `true` |
| `Config.ApiToken` | Token deines Servers aus dem Dashboard | leer |
| `Config.TrackedJobs` | Welche ESX-Jobs synchronisiert werden (leer = alle) | `{}` |
| `Config.SyncJobsOnStart` | Jobs und Mitglieder beim Start abgleichen | `true` |
| `Config.OnlineSyncInterval` | Abstand des Online-Abgleichs in Sekunden (min. 30) | `60` |
| `Config.Debug` | Ausführliche Ausgaben in der Server-Konsole | `false` |

## Was die Resource macht

**Vom Spiel zum Fraktion Manager**

- **Job-Abgleich**: beim Start werden alle ESX-Jobs samt Rängen gemeldet, damit
  du Fraktionen im Dashboard einem Job zuordnen kannst.
- **Mitglieder**: wer welchen Job und welchen Rang hat, inklusive Charaktername
  und Discord-Verknüpfung, sofern der Spieler über Discord verbunden ist.
- **Online-Status**: regelmäßig und bei jedem Join, Leave und Job-Wechsel. Die
  Fraktionsliste in Discord zeigt damit "X von Y online".

**Vom Fraktion Manager ins Spiel**

- **Job setzen**: beim Einstellen, Befördern, Degradieren und Entlassen über das
  Helper-Dashboard, sofern der Spieler online ist.
- **Ränge abfragen**: das Dashboard liest die Grades deines Jobs direkt vom Server.
- **Spielerliste**: für die Ingame-Auswahl beim Einstellen.

**Im Spiel**

- `/fmdashboard` öffnet das Dashboard direkt im Spiel. Beim ersten Mal erscheint
  ein Login-Link, den du einmal im Browser öffnest, danach bleibt die Anmeldung
  erhalten.

## Fehlersuche

Setze `Config.Debug = true` und schau in die Server-Konsole. Die Resource meldet
jedes Problem im Klartext:

| Meldung | Ursache |
|---|---|
| `Config.ApiToken fehlt` | Token nicht eingetragen |
| `Config.ApiToken hat ein unbekanntes Format` | Token unvollständig kopiert |
| `Token wurde nicht akzeptiert` | Token gehört zu einem anderen Server oder ist veraltet |
| `FiveM-Integration ist ... deaktiviert` | Schalter im Dashboard ist aus |
| `ESX nicht gefunden` | `es_extended` läuft nicht oder startet nach dieser Resource |
| `Fraktion Manager nicht erreichbar` | Kein Netzzugang vom Spielserver nach außen |
| `Keine unterstützte Datenbank-Resource gefunden` | `oxmysql` bzw. `mysql-async` fehlt |

Die Resource spricht `fivem.fraktionmanager.com` an. Wenn gar nichts ankommt,
prüfe, ob dein Spielserver diese Adresse erreicht:

```
curl -I https://fivem.fraktionmanager.com/api/health
```

Damit der Fraktion Manager umgekehrt Jobs ingame setzen kann, muss er deinen
Spielserver erreichen. Trage die Adresse im Dashboard unter **FiveM Server-URL** ein, zum
Beispiel `http://123.45.67.89:30120`, und achte darauf, dass der Port erreichbar
ist. Ohne diese Angabe funktioniert alles andere weiterhin, nur das Setzen von
Jobs aus dem Dashboard nicht.

## Hinweise

Die Resource enthält bewusst keine Spiellogik: sie meldet Daten und nimmt
Befehle an, alles Weitere entscheidet der Fraktion Manager. Dadurch bleibt sie
klein und du kannst nachlesen, welche Daten deinen Server verlassen.

## Support

[discord.gg/fraktionmanager](https://discord.gg/fraktionmanager)
