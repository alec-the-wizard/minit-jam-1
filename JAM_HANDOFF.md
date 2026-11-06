# Deal With It — Jam Handoff

Updated 2026-11-06, after P2 (all of it). Self-contained: read this, then
`AGENTS.md`.
**The next step is the final phone test and the Post update.** All P0, P1 and P2
are done and tested.

**Starter prompt for the next session:**

> Read `JAM_HANDOFF.md` in the repo root, then run the **final phone test and
> Post update** (§5). Read `AGENTS.md` before editing. The jam Post is already
> published, so changes ship by deleting and recreating that Post — never create
> a second entry. Ask me before changing game rules that are not in the task
> list. Work task by task, keep the packager green, and show me the diff of each
> task.

---

## 1. Mission

The game is an entry in **Defold Game Jam #1** (Minit Games), theme **"One More
Try"**. The Post is already published; the remaining phase is polish, re-test,
and ship the final build by deleting and recreating that Post.

Key dates (from the jam page's Jam Rules dialog):

| Event | When |
|---|---|
| Submissions close | **Nov 11, 2026, 08:00 GMT-3** |
| Games go live, voting opens | Nov 12, 2026, 08:00 GMT-3 |
| Voting closes | Nov 19, 2026, 08:00 GMT-3 |
| Winners announced | Nov 24, 2026 |

**Games cannot be changed once they go live.** Submissions close Nov 11 at
08:00 GMT-3 and games go live Nov 12, so every change must be uploaded and
re-tested before the deadline. The dashboard has **no in-place update**: to
change a published Post you delete it and recreate it. A jam organizer confirmed
this is allowed until the final date, and the UI enforces one entry per person
(so a second Post is not possible). See §5.

Prize structure: **Best Game $400** (judges, from a 10-game shortlist) plus six
$100 **player-voted** categories: Beautiful, Funny, Brain Burner, High Score
Fever, Zen Mode, Clever Twist. A game can win more than one award.

## 2. The game

A memory game on a card table. Cards are dealt face up for a short peek, flip
down, and then **slide across the felt and bounce off each other and the walls**
while you tap pairs. Clearing a table deals one more pair. A 60-second round,
then the platform result screen.

Intended fantasy / pitch: *the cards refuse to sit still*.

- Engine: Defold (release wasm-web), Minit SDK v1.17.0, template-based.
- All gameplay is in `main/game.script`; geometry in `main/field.lua`, card
  simulation in `main/cards.lua`, face pool in `main/deck.lua` (52 faces kept),
  deal randomness in `main/rng.lua`.
- A table picks **distinct ranks**: the same number or letter never appears
  twice, so two 5s of different suits cannot be confused. The deal is seeded
  (`seed` config), so everyone on a Post gets the same tables.
- HUD is label game objects spawned from factories (score, clock, best, hint);
  the hint shows the play reminder "Match pairs" between tables and flashes
  `+10`/`+12` for 0.6 s on each match; match pop is
  `main/pop.go` + `main/pop.script`; tutorial halo is
  `main/hint_ring.go` + `main/hint_ring.script`.
- Font: **Quicksand Bold** (`assets/fonts/quicksand_bold.ttf`), SIL OFL 1.1;
  its notice ships in `THIRD-PARTY-NOTICES.txt`.
- Audio goes through `minit_platform/audio.lua` (do not edit it). Music is
  `assets/music/theme.ogg` (114 KB, loops), SFX are the WAVs in `assets/sfx/`.
- Personal best is stored in the single user-data slot as `v1:<score>` and shown
  in the HUD.

## 3. Current state (verified 2026-11-06)

- The P2 batch is committed: `Deal each table with unique card ranks`,
  `Seed the deal and fix config parsing`, `Pause the round while the game is
  off-screen`, `Show the points at each match`, `Align the config bounds with
  the table`, `Keep layout reflows off the deal stream`. Working tree is
  **clean**.
- Build passes. Package is green: `dist/Deal With It.zip` is **2.08 MB**
  (2,184,154 bytes), written 2026-11-06 15:43.
- The ZIP contains `meta.json` with `"title": "Deal With It"`. Its
  `THIRD-PARTY-NOTICES.txt` contains the SDK/Defold notices **plus the Quicksand
  Bold OFL 1.1 section** (see §6).
- `game.project` has `title = Deal With It`; default **linear** texture
  filtering (the two `default_texture_*_filter = nearest` lines are gone).
- `meta.json` description/controls/logic are the **new player copy** (P1-7,
  1111 chars total). The config block now matches the code: `start_pairs` 2–5,
  `max_pairs` 3–6, `card_speed` 0.6–5, plus the new `seed` 0–999999.
- **Config values now actually work.** A pre-existing bug made `number_config`
  read `get_config_value(<the value>)` instead of the raw string, so every key
  silently fell back to its default while packaging stayed green. Fixed in P2-1;
  verified with `?round_seconds=15` (0:15 clock) and clamps
  (`start_pairs=9` → 5 pairs).
- The deal is seeded: `?seed=7` twice dealt the same table (Q♥, 2♣, 7♥ at the
  same cells); `?seed=8` dealt 2♥, 3♦, 4♠. Ranks are unique per table.
- **Pause while hidden** is wired with `minit.on_viewable_change`; verified with
  a fake `window.minit.isViewable` host: the clock froze at 0:41 and resumed
  afterwards. `MAX_DT = 0.25` caps the first frame after a long stall.
- A match flashes its points in the hint ("+10"); a browser bot made a match and
  the run ended at score 10 with one `reportResult`.
- **The jam Post is published.** The upload title is locked. Store User Data is
  enabled and the best survived a restart in testing. This is an intentional
  test build (no gameplay, technical or legal problems); updating it means
  deleting and recreating the Post (§5).
- **Tested on a real phone (P0-4)** — loading, first tap, audio, result screen,
  vote screen and `?tutorial=0` behaved. Backgrounding was the old behaviour
  then; P2-2 is browser-tested only so far. The P1/P2 changes are tested in a
  browser at 400×600 and 320×600/640, not yet on the phone.
- `assets/cards/card_back.png` is the **new identity back** (P1-8): deep blue,
  cream pinstripe frame and a fanned pair emblem, still 139×208.
- HUD is retuned to the Quicksand metrics (P1-8): labels render at the old
  nominal size, the best line sits under the score without overlap.
- The editor is running with the project open (port in `.internal/editor.port`,
  token in `.internal/editor.token`).

## 4. Ground rules

- **Never edit `minit_platform/` or `.deps/`.** `minit_platform` is the SDK glue
  that makes the game work inside the Minit app.
- **Never publish a second jam Post.** Update the entry by deleting the
  published Post and recreating it (§5); the UI enforces one entry per person.
- Lua: 4 spaces, `snake_case`, LuaCATS annotations, instance state in `self`,
  local functions only at module scope, `require("module")` with parentheses,
  no metatables/classes.
- Exactly one `minit.report_result()` per run, from `finish()`.
- `minit.loading_done()` at the end of `init()`.
- `layout.refresh()` in `update()`; rebuild from `layout.width/height/unit`.
- Commit messages: short, English.
- Verify Defold API usage with the `defold-api-fetch` skill if unsure.

## 5. Build, package, test

The Defold editor must be open on this project.

```powershell
# build (also refreshes the editor's view of files edited outside the editor)
$port = Get-Content .internal\editor.port
Invoke-RestMethod -Uri "http://127.0.0.1:$port/command/build" -Method Post

# package for upload (this is the same validation minit.studio runs)
$token = Get-Content .internal\editor.token
$body = 'return require("minit.editor.minit_package").run().ok'
Invoke-RestMethod -Uri "http://127.0.0.1:$port/eval" -Method Post `
  -Headers @{ Authorization = "Bearer $token" } -Body $body
```

Expected tail of the report (current size, 2026-11-06):
`Ready to upload: dist/Deal With It.zip (2.08 MB)`,
`Release build, single-threaded wasm, meta.json included.` and `=> true`.

**Shipping an update after the Post is published:**

1. Build + package (above), and confirm the report is green.
2. On minit.studio, **delete the current Defold Game Jam #1 Post and recreate
   it from the new ZIP**, with the updated details and caption (the new
   `meta.json` copy). There is no in-place update; the organizer confirmed this
   flow is allowed until the final date. The UI prevents a second entry per
   person. Check the config dials on the Post now that they actually reach the
   game (round 60, start 3, max 5, seed 1).
3. Open the recreated Post's preview link (QR → *Generate preview link*, valid
   15 minutes) and run the P0-4 checklist on the phone again, including the
   first-result and best-score flow on the fresh Post.
4. Stop before **Nov 11, 08:00 GMT-3**. After the Nov 12 go-live, the build is
   frozen.

**Gotcha:** the packager reads scripts through the editor's resource cache. After
editing files outside the editor, run **Project > Build first**, otherwise the
packager validates stale code (this is what hid a fix during the earlier review).

**Gotcha:** `.internal/editor.port` changes when the editor restarts.

## 6. The packaging blocker (already fixed — do not reintroduce it)

The packager statically greps scripts for **literal** config keys:
`get_config_value%(%s*"([^"]+)"` (and the single-quote form), in
`.deps/minit/editor/minit_package.lua:449`. It also fails if `meta.json`
declares a key no script reads literally.

`read_config()` must pass the **value** to `number_config`, not a key. The
packager only greps for the literal `get_config_value("key", "")` call, so a
helper that reads the config itself passes the grep while every value falls back
to its default at runtime. That bug was real until P2-1 and packaging stayed
green throughout. Current shape (keep it):

```lua
local function number_config(raw, fallback, low, high)
    local value = tonumber(raw)
    if not value then return fallback end
    return math.max(low, math.min(high, value))
end

local config = {
    round_seconds = number_config(minit.get_config_value("round_seconds", ""), 60, 15, 180),
    start_pairs = math.floor(number_config(minit.get_config_value("start_pairs", ""), 3, 2, 5)),
    -- ...one literal key per entry
}
```

Any new config key needs a literal `get_config_value("key", ...)` call and a
matching `meta.json` entry, or packaging fails. **Also test it in a build**
(`?round_seconds=15` must show 0:15); the packager cannot tell that a value is
ignored.

The packager also checks: `report_result` is referenced, the HTML shell is the
Minit one, the wasm is single-threaded release, ZIP ≤50 MB / ≤2000 files, and
`meta.json` config ≤25 entries with descriptions ≤100 chars.

**Notices are optional but used.** `notices()` in `minit_package.lua` appends
the root `THIRD-PARTY-NOTICES.txt` only if the file exists. The ZIP always keeps
the SDK/Defold notices. The root file now contains **only the Quicksand Bold
OFL 1.1 notice**: the CC0 card art requires no attribution, but the font's
license does. Verified in the ZIP: the custom section is present and follows the
SDK text.

## 7. How the jam is scored (what to optimise)

- Players vote **once**, after their **first completion**, on a screen offering
  up to 3 of the 6 categories. The screen advances after **6 seconds**.
- **Category Score = awards × award rate**, where award rate =
  awards ÷ **all unique completions** (players who skip voting still dilute it).
- **Best Game** shortlist = the **sum of all six Category Scores**, top 10, then
  judges pick on fun, originality and theme fit.
- Only the **first** completion per player counts. Replays add nothing.

Implications:

1. **Breadth beats depth** for the $400: be credible in Brain Burner, Clever
   Twist, High Score Fever, and presentable in Beautiful. Funny is cheap to earn
   with flavor text. Zen Mode is not a fit.
2. **The ending must leave a clean, positive impression** for 6 seconds — every
   finish that does not vote hurts the rate. P1-6 did this ("Time's up!", the
   reveal, and a caption with a best/near-miss hook); keep it intact.
3. Reach matters: share the published Post link (Discord etc.) after Nov 12.
   Asking players to vote is allowed; offering anything in exchange is not, and
   can get the game disabled.

## 8. Platform requirements — status

| Requirement | Status |
|---|---|
| ZIP, `index.html` at root, wasm-web release, single-threaded | ✅ verified by packager |
| Bundle < 5 MB recommended | ✅ 2.08 MB |
| Portrait, touch-only, delta time, any aspect ratio | ✅ |
| No localStorage/fetch/cookies/external assets/navigation | ✅ |
| `loading_done()` | ✅ |
| `report_result()` exactly once | ✅ |
| `meta.json` config keys match literal reads | ✅ |
| Same challenge per Post (seed) | ✅ P2-1, `?seed=7` twice = same table |
| Pause when off-screen | ✅ P2-2, browser-tested with a fake viewability host |
| Match points visible | ✅ P2-3, `+10` flashes in the hint |
| Config values applied and bounded | ✅ P2-4, plus the `number_config` fix |
| First-play tutorial gated on `should_show_tutorial()` | ✅ P1-4, tested with `?tutorial=0` |
| Personal best via userData | ✅ P1-5, Store User Data on and tested |
| Flavor text ≤64 chars | ✅ P1-6 rewrite; longest string is 32 chars |
| Licensing/notices | ✅ CC0 art needs no notice; Quicksand OFL 1.1 notice is in `THIRD-PARTY-NOTICES.txt` |
| Jam Post published | ✅ title locked; updates = delete + recreate |

## 9. Priority queue

### Done (do not redo)

| Task | Outcome |
|---|---|
| P0-1 | Title `Deal With It` in `game.project`; linear filtering committed. |
| P0-2 | Notices trimmed to what the assets need: CC0 card art needs no attribution. |
| P0-2b | `THIRD-PARTY-NOTICES.txt` restored with the Quicksand Bold OFL 1.1 text; packaging includes it. |
| P0-3 | Build + package green; ZIP verified (2.08 MB now). |
| P0-4 | Real-phone test passed: loading, first tap, audio, result, vote, `?tutorial=0`. Backgrounding then ran the clock; P2-2 added the pause, so retest it on the phone. |
| P0-5 | Jam Post published on minit.studio; title is locked. |
| P1-1 | First tap skips the opening peek (`cards.skip_peek`). |
| P1-2 | First table deals 3 pairs. |
| P1-3 | Clock starts only when the deal is face down. |
| P1-4 | Gated first-play tutorial: "Memorize!", hint + halos, HUD hidden until the first flip. |
| P1-5 | Personal best: `v1:<score>` userData, `BEST n` line, `NEW BEST!` flash. Store User Data enabled and tested. |
| P1-6 | Ending: `Time's up!` hint, reveal and 1 s delay kept; 5 outcome-specific captions (new best, zero pairs, near miss, tables, streak), all ≤32 chars. One `report_result` path. |
| P1-7 | `meta.json` rewritten for players: 3 sentences per section, 1111 chars total, no hardcoded points/minutes, every table dealt face up, tap-only controls, best and streak described. |
| P1-8a | Quicksand Bold font swapped in for the HUD. |
| P1-8 | Card back redesigned (139×208); HUD divisor fixed to `game.font` size 56; hint advance 0.58. Felt left as is (it already has a vignette). |
| P1-9 | HUD hint shows the play reminder "Match pairs" instead of the table difficulty; `difficulty_name` removed. |
| P2-5a | Music converted to OGG (1.92 MB → 114 KB; bundle 3.69 → 2.10 MB). |
| Deck | Each table picks distinct ranks, so the same number or letter never appears twice. |
| P2-1 | Seeded deal on a dedicated `main/rng.lua` stream and a `seed` config (default 1); table 7 reproduced, table 8 differed. Fixed `number_config`, so config values actually apply. |
| P2-2 | Pause via `minit.on_viewable_change`; `final()` unsubscribes; `MAX_DT` caps the first frame after a stall. |
| P2-3 | A match flashes its points ("+10") in the hint for 0.6 s, then "Match pairs" returns. |
| P2-4 | Bounds: start 2–5, max 3–6, speed 0.6–5; `meta.json` matches the code. |
| P2-5 | Bundle 2.08 MB; card trimming cancelled. |

### P3 — after the jam

- Turn the dials into a numbered series of Posts (`Daily Shuffle #12`) with a
  fixed seed per Post; schedule up to 4 weeks ahead; alternate easy/hard; at
  most 2 Posts per Game per day.
- Keep the personal best across Posts (same userData key).
- Consider `sound`/`music` preferences in userData (`audio.configure` already
  exists and is unused).
- Keep every Post self-contained for first-timers.

## 10. Decisions already made

- Name: **Deal With It** — uploaded, title locked on minit.studio.
- Jam Post: **published**. Updates are delete + recreate (organizer-confirmed,
  allowed until the final date); the dashboard has no in-place update and the UI
  prevents a second entry.
- The current published build is a **deliberate test build** with no gameplay,
  technical or legal problems.
- Card faces: *Card Asset Pack* by natomarcacini, **CC0** → no attribution file
  required; `license: "proprietary"` stays; credits line kept in `meta.json`.
- `THIRD-PARTY-NOTICES.txt` ships with **only the Quicksand Bold OFL 1.1
  notice**. The CC0 card art needs no attribution; the SDK notices are
  generated by the packager.
- Music and SFX: generated for this game → own work.
- Music format: **OGG** (`theme.ogg`), not WAV.
- Font: **Quicksand Bold** (`quicksand_bold.ttf`), SIL OFL 1.1. `game.font` stays
  at `size: 56`; `FONT_SIZE` is 56 too, so labels render at the old Vera Mono em
  size with no per-label fudge. `HINT_CHAR_EM` is 0.58 (Quicksand's proportional
  advance plus a margin).
- Card back: **redesigned** (P1-8). Deep blue panel with a cream double pinstripe
  frame and a fanned pair emblem, plus a thin white card edge so it matches the
  faces. Still 139×208 with transparent rounded corners.
- Felt: **left as is**. The shipped texture already has a soft vignette; warmer
  felt was declined to avoid changing the established look.
- Deal: **seeded** by the Post's `seed` config (default 1) on a dedicated
  Park-Miller stream in `main/rng.lua`. Cosmetic pitch calls stay on
  `math.random`, so they cannot perturb the deal; a layout reflow uses its own
  stream from the same seed, so a resize cannot either.
- Ranks are unique per table: a table never holds two suits of the same number
  or letter.
- Pause: `minit.on_viewable_change` flips `self.paused`; `update()` returns while
  paused and `final()` unsubscribes. `MAX_DT = 0.25` caps the first frame after a
  stall.
- Scoring feedback: a match flashes `+10`/`+12` in the hint for 0.6 s; a table
  clear or the ending cancels the flash so "Cleared!"/"Time's up!" win.
- Config bounds: the marketable values from P2-4 are in both the code clamps and
  `meta.json` (start 2–5, max 3–6, speed 0.6–5). The table can still lower the
  pair count.
- No "enjoyed it? vote below" nudge before the result.
- Texture filtering: **linear** (the art is anti-aliased; nearest produced
  jaggies at ~1.57×).
- All **52 card faces** stay in the atlas.
- Personal best: own HUD line under the score; Store User Data enabled and
  tested.
- Theme read: memory game + moving cards = "One More Try" and "Clever Twist".
- Target categories: Brain Burner, Clever Twist, High Score Fever, plus
  Beautiful/Funny as breadth for the Best Game sum.
- 60-second default run stays (platform's ~1 minute rhythm).

## 11. Open decisions (ask the user)

Non-blocking:
- Whether to keep the repo name/folder as is.

## 12. Reminders / gotchas

- The Post is published. Updating it means **deleting it and recreating it**
  with the new build; there is no in-place update. The organizer confirmed this
  is allowed until the final date, and the UI prevents a second entry.
- The current published build is a deliberate test build with no known gameplay,
  technical or legal problems.
- The upload title is locked to *Deal With It*.
- Every change must be re-uploaded and re-tested before **Nov 11, 08:00 GMT-3**.
- The packager validates the **editor's cached** scripts: build before packaging.
- `report_result` fires exactly once; do not add a second ending path.
- `flavor_text` is truncated silently at 64 chars.
- Deal randomness goes through `main/rng.lua`, not `math.random`; the global
  stream is for cosmetics only. Reflows use a fresh stream from the Post's seed.
  `seed` 0 is mapped to 1, so it is a valid seed.
- The HUD hint shares its row with the score and clock. It reads `"Match pairs"`
  (P1-9) and briefly `"+N"` (P2-3); keep any play hint near that length (about 11
  characters) or it collides with the clock on a 320 px slot.
- Pause is wired to `minit.on_viewable_change`; the browser Review pane keeps
  background tabs "visible", so test it with a fake host (`window.minit` with
  `isViewable`/`addEventListener`) instead of tab switching.
- Card config values are only trustworthy after a runtime check
  (`?round_seconds=15` → 0:15); the packager only sees literal reads (§6).
- userData writes are ignored on a Post's replays (first result only) and on
  oversized values (>1024 bytes).
- Do not call `report_result` before `loading_done`.
- The app's game slot is ~2:3, not the 960×1480 design surface; layout is
  derived from `window.get_size()` via `minit_platform/layout.lua`.
- Labels are ASCII-only: the font character set has no em dash, curly quotes or
  ellipsis. Use `-`, `'`, `...`.
- Keep `THIRD-PARTY-NOTICES.txt` in sync with the font. The Quicksand OFL 1.1
  section is appended to the SDK notices in the ZIP.
- Re-test the first-result and best-score flow on the recreated Post.
- Jam rules: no edits after going live, no vote incentives, rights must be
  clean, a moderator reviews the entry.
- The jam page said "9 submissions" at review time.

## 13. Reference

Files:
`game.project`, `meta.json`, `main/game.script`, `main/cards.lua`,
`main/field.lua`, `main/deck.lua`, `main/rng.lua`, `main/pop.script`,
`main/hint_ring.script`, `main/uncompressed/cards.atlas`,
`assets/fonts/game.font`, `assets/fonts/quicksand_bold.ttf`,
`assets/music/theme.ogg`, `THIRD-PARTY-NOTICES.txt`, `tools/make_music.py`.

Docs (all under https://minit.studio/docs/):
`platform-requirements`, `playbook-the-minit-games-format`,
`playbook-land-the-ending`, `playbook-play-instantly`, `playbook-build-to-post`,
`playbook-daily-habit`, `playbook-how-posts-find-players`,
`playbook-turn-players-into-fans`, `playbook-remember-your-players`,
`reporting-results`, `saving-user-data`, `game-ui`, `interactive-tutorials`,
`defold`, `meta-json-reference`, `writing-your-description`.
Jam page: https://minit.studio/events/defold-game-jam-1 (rules in a dialog).

SDK facade available in v1.17.0: `loading_done`, `report_result`,
`get_config_value`, `get_user_data`, `should_show_tutorial`, `is_viewable`,
`on_viewable_change`. No seeded-random helper, no device-tier getters.
