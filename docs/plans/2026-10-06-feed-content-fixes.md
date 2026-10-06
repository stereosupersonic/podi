# Feed content fixes

Manual fixes in the admin for problems the RSS feed check found on 2026-10-06. The code side is done
(#215, #216, #217, #218); what remains is episode content that only an admin can change. Remove this
file once every box is ticked.

All steps happen in the admin: log in, open the edit page linked in each step, change the field, click
**Save**. Changes reach Apple Podcasts and Spotify within about an hour.

## 1. Broken links in the show notes

Podcast apps show the show notes from the feed and cannot open a link without a domain. Since #217 the
admin refuses to save these two episodes until the links are fixed, so do this first.

### 050 Rückblick – Geschichten aus der Wartenberger Geschichte

Edit: https://www.wartenberger.de/admin/episodes/050-rueckblick-geschichten-aus-der-wartenberger-geschichte/edit

In **Nodes**, replace

| Find | Replace with |
|---|---|
| `(025-maria-und-mathias-obermeier-zeitzeugen)` | `(https://www.wartenberger.de/episodes/025-maria-und-mathias-obermeier-zeitzeugen)` |
| `(028-max-kammerer-wartenberger-zeitzeuge)` | `(https://www.wartenberger.de/episodes/028-max-kammerer-wartenberger-zeitzeuge)` |

The link texts are "Episode 25: Maria und Mathias Obermeier" and "Episode 28:Max Kammerer" (the second
is missing a space after the colon; fix it while you are there).

- [ ] 050 links fixed

### 032 Wartenberger Online Museum

Edit: https://www.wartenberger.de/admin/episodes/032-wartenberger-online-museum/edit

In **Nodes**, replace `(dhm.de/lemo/)` with `(https://www.dhm.de/lemo/)`. The link text is
"Lebendiges Museum Online".

- [ ] 032 link fixed

## 2. Episode images that are not square

Spotify requires square (1:1) images. Make a square version of each image (Canva, 1400 × 1400 px, PNG
or JPEG; add a background instead of cutting faces off) and upload it in the **Image** field. An
uploaded image takes precedence over **Artwork url**, so the old S3 images do not need to be removed.

| Episode | Now | Edit |
|---|---|---|
| 061 | 1400 × 1120 | https://www.wartenberger.de/admin/episodes/061-wartenberger-musik-er-geschichten/edit |
| 050 | 1400 × 1114 | https://www.wartenberger.de/admin/episodes/050-rueckblick-geschichten-aus-der-wartenberger-geschichte/edit |
| 031 | 1137 × 1400 | https://www.wartenberger.de/admin/episodes/031-simon-grandinger-sen-wartenberger-zeitzeuge/edit |
| 028 | 1400 × 1144 | https://www.wartenberger.de/admin/episodes/028-max-kammerer-wartenberger-zeitzeuge/edit |
| 007 | 1599 × 1500 | https://www.wartenberger.de/admin/episodes/007-wartenbergs-kunstler-dr-heike-schmidt-kronseder/edit |
| 006 | 2417 × 2703 | https://www.wartenberger.de/admin/episodes/006-wartenberg-im-mittelalter-dr-heike-schmidt-kronseder/edit |
| 004 | 1500 × 1490 | https://www.wartenberger.de/admin/episodes/004-nicole-hartl-cafe-hartl/edit |
| 002 | 600 × 800 | https://www.wartenberger.de/admin/episodes/002-anton-muller-hotel-reiter-brau/edit |

061, 050, 031 and 028 are already uploads; 007, 006, 004 and 002 come from **Artwork url**. 050 can only
be saved after its links are fixed (step 1).

- [ ] 061
- [ ] 050
- [ ] 031
- [ ] 028
- [ ] 007
- [ ] 006
- [ ] 004
- [ ] 002

## 3. Descriptions over Apple's 4000 bytes

Apple allows 4000 bytes in an episode's `<description>`. podi builds it from **Description**, the
chapter list and **Nodes**, and appends the contact block. Shorten **Description** (or **Nodes**) by at
least the number of bytes below; add about 100 bytes of margin, because Markdown becomes slightly
longer HTML. Umlauts count as two bytes.

| Episode | Over by (after #218) | Edit |
|---|---|---|
| 041 Bürgerinitiative Wartenberg | 1058 | https://www.wartenberger.de/admin/episodes/041-buergerinitiative-wartenberg/edit |
| 023 News Sonderausgabe Bürgerversammlung 2021 | 300 | https://www.wartenberger.de/admin/episodes/023-news-sonderausgabe-buergerversammlung-2021/edit |
| 021 Henaheisl – 30 Jahre FC Bayern Fanclub | 165 | https://www.wartenberger.de/admin/episodes/021-henaheisl-30-jahre-fc-bayern-fanclub/edit |
| 033 KulturMarkt Wartenberg | 107 | https://www.wartenberger.de/admin/episodes/033-kulturmarkt-wartenberg/edit |
| 045 Josefsheim | 91 | https://www.wartenberger.de/admin/episodes/045-josefsheim/edit |

012 Max Kronseder is 4015 bytes today and drops to 3968 once #218 removes the empty Twitter link, so it
needs nothing. Merge #218 before measuring, otherwise every episode is 47 bytes longer.

- [ ] 041
- [ ] 023
- [ ] 021
- [ ] 033
- [ ] 045

## 4. Check

After all fixes, wait a minute for the cache, then run the W3C validator:
https://validator.w3.org/feed/check.cgi?url=https%3A%2F%2Fwww.wartenberger.de%2Fepisodes.rss

Expected: the only error is *Undefined channel element: itunes:title* (Apple allows it; the validator
does not know it), plus the warnings about the podlove namespace and HTML in `itunes:summary`. No more
*relative URL references*.

To measure a single episode, the podcast folder has `docs/feed-pruefen.py`
(`description_bytes` must be at most 4000).

- [ ] W3C check passed
