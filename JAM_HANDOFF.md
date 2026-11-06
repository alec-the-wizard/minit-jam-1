# Deal With It — Jam Handoff

Updated 2026-11-06, after P1-5. Self-contained: read this, then `AGENTS.md`.
**The next task is P1-6.** All of P0 and P1-1…P1-5 are done and tested.

**Starter prompt for the next session:**

> Read `JAM_HANDOFF.md` in the repo root, then start with **P1-6**. Read
> `AGENTS.md` before editing. The jam Post is already published, so changes ship
> as updates to that Post — never create a second one. Ask me before changing
> game rules that are not in the task list. Work task by task, keep the packager
> green, and show me the diff of each task.

---

## 1. Mission

The game is an entry in **Defold Game Jam #1** (Minit Games), theme **"One More
Try"**. The Post is already published; the remaining phase is polish, re-test,
and ship updates to that same Post.

Key dates (from the jam page's Jam Rules dialog):

| Event | When |
|---|---|
| Submissions close | **Nov 11, 2026, 08:00 GMT-3** |
| Games go live, voting opens | Nov 12, 2026, 08:00 GMT-3 |
| Voting closes | Nov 19, 2026, 08:00 GMT-3 |
| Winners announced | Nov 24, 2026 |

**Games cannot be changed once they go live.** Submissions close Nov 11 at
08:00 GMT-3 and games go live Nov 12, so every change must be uploaded and
re-tested before the deadline. One entry per person — update the existing Post,
do not publish a second jam Post. (Confirm the update flow on the dashboard; see
§11.)

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
  simulation in `main/cards.lua`, face pool in `main/deck.lua` (52 faces kept).
- HUD is label game objects spawned from factories (score, clock, best, hint);
  match pop is `main/pop.go` + `main/pop.script`; tutorial halo is
  `main/hint_ring.go` + `main/hint_ring.script`.
- Font: **Quicksand Bold** (`assets/fonts/quicksand_bold.ttf`), SIL OFL 1.1.
- Audio goes through `minit_platform/audio.lua` (do not edit it). Music is
  `assets/music/theme.ogg` (114 KB, loops), SFX are the WAVs in `assets/sfx/`.
- Personal best is stored in the single user-data slot as `v1:<score>` and shown
  in the HUD.

## 3. Current state (verified 2026-11-06)

- The last code commit is `5e8cd53 third party notices removed as not needed`;
  this handoff update is the only commit after it. Working tree is **clean**.
- Build passes. Package passes against the code at `5e8cd53`:
  `dist/Deal With It.zip` is **2.10 MB** (2,202,356 bytes), written
  2026-11-06 12:52.
- The ZIP contains `meta.json` with `"title": "Deal With It"`. Its
  `THIRD-PARTY-NOTICES.txt` contains **only the SDK/Defold notices** — there is
  no custom section any more (see §6).
- `game.project` has `title = Deal With It`; default **linear** texture
  filtering (the two `default_texture_*_filter = nearest` lines are gone).
- `meta.json` has been updated for the best-score feature, but its
  description/controls/logic are still the **old copy** (P1-7).
- **The jam Post is published.** The upload title is locked. Store User Data is
  enabled and the best survived a restart in testing.
- **Tested on a real phone (P0-4)** — loading, first tap, audio, result screen,
  vote screen and `?tutorial=0` behaved. Backgrounding is still the pre-P2-2
  behaviour (the clock keeps running while hidden).
- `assets/cards/card_back.png` is still the original flat blue 139×208 back
  (P1-8).
- The editor is running with the project open (port in `.internal/editor.port`,
  token in `.internal/editor.token`).

## 4. Ground rules

- **Never edit `minit_platform/` or `.deps/`.** `minit_platform` is the SDK glue
  that makes the game work inside the Minit app.
- **Never publish a second jam Post.** Upload the new build and update the
  existing Post.
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
`Ready to upload: dist/Deal With It.zip (2.10 MB)`,
`Release build, single-threaded wasm, meta.json included.` and `=> true`.

**Shipping an update after the Post is published:**

1. Build + package (above), and confirm the report is green.
2. On minit.studio, upload the new ZIP to **Deal With It** and update the
   **existing** Defold Game Jam #1 Post with the new build. Never create a new
   Post.
3. Open the Post's preview link (QR → *Generate preview link*, valid 15 minutes)
   and run the P0-4 checklist on the phone again.
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

`read_config()` originally passed keys through the `number_config(key, ...)`
helper, so all six keys failed. Current shape (keep it):

```lua
local config = {
    round_seconds = number_config(minit.get_config_value("round_seconds", ""), 60, 15, 180),
    start_pairs = math.floor(number_config(minit.get_config_value("start_pairs", ""), 3, 2, 12)),
    -- ...one literal key per entry
}
```

Any new config key needs a literal `get_config_value("key", ...)` call and a
matching `meta.json` entry, or packaging fails.

The packager also checks: `report_result` is referenced, the HTML shell is the
Minit one, the wasm is single-threaded release, ZIP ≤50 MB / ≤2000 files, and
`meta.json` config ≤25 entries with descriptions ≤100 chars.

**Notices are optional.** `notices()` in `minit_package.lua` appends the root
`THIRD-PARTY-NOTICES.txt` only if the file exists. The ZIP always keeps the
SDK/Defold notices; deleting the root file merely drops the custom section. That
file was removed deliberately (CC0 card art needs no attribution) — see §11 for
the remaining font-license question.

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
   finish that does not vote hurts the rate. This is what P1-6 is for.
3. Reach matters: share the published Post link (Discord etc.) after Nov 12.
   Asking players to vote is allowed; offering anything in exchange is not, and
   can get the game disabled.

## 8. Platform requirements — status

| Requirement | Status |
|---|---|
| ZIP, `index.html` at root, wasm-web release, single-threaded | ✅ verified by packager |
| Bundle < 5 MB recommended | ✅ 2.10 MB |
| Portrait, touch-only, delta time, any aspect ratio | ✅ |
| No localStorage/fetch/cookies/external assets/navigation | ✅ |
| `loading_done()` | ✅ |
| `report_result()` exactly once | ✅ |
| `meta.json` config keys match literal reads | ✅ |
| Same challenge per Post (seed) | ❌ P2-1 |
| Pause when off-screen | ❌ P2-2 |
| First-play tutorial gated on `should_show_tutorial()` | ✅ P1-4, tested with `?tutorial=0` |
| Personal best via userData | ✅ P1-5, Store User Data on and tested |
| Flavor text ≤64 chars | ⚠️ current strings fit, but need the P1-6 rewrite |
| Licensing/notices | ⚠️ CC0 art resolved; Quicksand OFL notice open (§11) |
| Jam Post published | ✅ title locked; update this Post only |

## 9. Priority queue

### Done (do not redo)

| Task | Outcome |
|---|---|
| P0-1 | Title `Deal With It` in `game.project`; linear filtering committed. |
| P0-2 | Custom notices file removed on purpose (CC0 needs no attribution). |
| P0-3 | Build + package green; ZIP verified (size now 2.10 MB). |
| P0-4 | Real-phone test passed: loading, first tap, audio, result, vote, `?tutorial=0`. Backgrounding still runs the clock (P2-2). |
| P0-5 | Jam Post published on minit.studio; title is locked. |
| P1-1 | First tap skips the opening peek (`cards.skip_peek`). |
| P1-2 | First table deals 3 pairs. |
| P1-3 | Clock starts only when the deal is face down. |
| P1-4 | Gated first-play tutorial: "Memorize!", hint + halos, HUD hidden until the first flip. |
| P1-5 | Personal best: `v1:<score>` userData, `BEST n` line, `NEW BEST!` flash. Store User Data enabled and tested. |
| P1-8a | Quicksand Bold font swapped in for the HUD. |
| P2-5a | Music converted to OGG (1.92 MB → 114 KB; bundle 3.69 → 2.10 MB). |

### P1 — remaining (before the freeze)

**P1-6 — Land the ending. (START HERE)**
- In `finish()`: call `set_hint(self, "Time's up!")` before/alongside the reveal;
  keep the reveal and `delay = 1000` (`REPORT_DELAY_MS` is already 1000).
- Rewrite `flavour_text(stats)` into **3–5 outcome-specific lines** with
  personality and a near-miss/challenge hook (≤64 chars each). Today the five
  branches are factual but interchangeable. Ideas (ASCII only, see §12):
  `"27 pairs. One more try?"`, `"New best: 640. Beat that."`,
  `"Zero pairs. The cards won."`, `"One pair short of a new best."`
- The best-score branch should fire when the run beat the stored best, and the
  zero-pairs branch should feel funny rather than scolding. `flavour_text` only
  receives `stats` today, so pass the score and stored best (or `self`) to make
  the "new best" line possible.
- Acceptance: every string ≤64 chars (the SDK warns/truncates), the hint reads
  "Time's up!" on the final table, and the result screen appears ~1 s later.
- No new `report_result()` path; still exactly one.

**P1-7 — Rewrite `meta.json` for players.**
- The Post is published on minit.studio, so this only takes effect after
  re-upload + updating the Post. Do it in the same batch as P1-6.
- Lead with the twist and the name; 2–4 sentences per section; total
  description+controls+logic ≤2500 chars.
- Remove the hardcoded `10 points`, `1 minute`, and the **wrong** claim that the
  opening reveal is the only free look — **every** table is dealt face up.
- Keep the controls text accurate for touch (tap only, no drag).
- Mention the best score and that streak bonuses make later matches worth more.
- Config values stay aligned with code (see P2-4 table).
- Acceptance: valid JSON, packaging green, description matches what the game
  actually does in a 60 s Post.

**P1-8 — Card back and table identity (font part is done).**
- `assets/cards/card_back.png` is a flat blue rectangle with a diagonal seam
  (139×208). Give it a pattern/emblem so it reads as the game's identity.
- Already done: **Quicksand Bold** replaced Vera Mono Bold. Note that the HUD
  math still uses `FONT_SIZE = 48` and `HINT_CHAR_EM = 0.61` (a Vera Mono
  advance), while `assets/fonts/game.font` now has `size: 56`. Labels render
  ~17 % larger than the old tuning and the hint-fit estimate is approximate.
  Check the score/best spacing and the longest hint on a narrow screen; retune
  those constants (and `HUD_BEST_UNITS` / `HUD_BEST_TOP_UNITS`) if needed.
- Optional: warmer felt, a vignette.
- Acceptance: card back still 139×208 (atlas unchanged), readable at ~1.5×; HUD
  does not overlap or overflow after the font swap.

### P2 — if time remains (also long-term value)

**P2-1 — Seed: same challenge for every player of a Post.**
- `meta.json`: add `seed` (number, default 1, min 0, max 999999).
- `game.script`: `local seed = tonumber(minit.get_config_value("seed", "")) or os.time()`
  then `math.randomseed(seed)`; delete `math.randomseed(os.time())` at line ~380.
- This makes deals, directions and spawn cells identical for everyone on a Post
  (cosmetics included), and unlocks daily seed Posts later.
- Test: `?seed=7` twice = same table; `?seed=8` = different.
- Acceptance: packaging green; config key is read literally.

**P2-2 — Pause while off-screen.**
- `self.unsubscribe = minit.on_viewable_change(function(viewable)
  self.paused = not viewable end)`; `self.paused = not minit.is_viewable()`;
  `if self.paused then return end` at the top of `update`; call the unsubscribe
  in a new `final(self)`.
- Acceptance: swiping away freezes the clock and cards; returning resumes; no
  result fires while hidden.

**P2-3 — Make scoring visible.**
- Show `+10` / `+12` at the matched pair (small floating label that rises and
  fades), or flash the hint. The streak bonus (+1 per earlier match) is currently
  invisible.
- Acceptance: a match gives immediate point feedback; no per-tap spam.

**P2-4 — Align config bounds with what the game can do.**
Marketable values (also use them in `meta.json`; the code clamps):

| key | type | default | min | max |
|---|---|---|---|---|
| `round_seconds` | number | 60 | 15 | 180 |
| `start_pairs` | number | 3 | 2 | 5 |
| `max_pairs` | number | 5 | 3 | 6 |
| `card_speed` | number | 2 | 0.6 | 5 |
| `reveal_seconds` | number | 1.5 | 0.4 | 5 |
| `score_per_pair` | number | 10 | 1 | 100 |
| `seed` | number | 1 | 0 | 999999 |

Facts: `field.MAX_PAIRS = 6`, and `field.capacity()` gives **5 pairs on a 2:3
slot** (the app slot), so declared values above 5–6 never happen. `card_speed`
is clamped at 0.0 in code today, which would freeze the cards; use 0.6.
`meta.json` currently advertises `start_pairs` up to 8 and `max_pairs` up to 12 —
both misleading.

**P2-5 — Shrink the bundle.**
- Music part is **done**: `theme.ogg` is 114 KB and the bundle is 2.10 MB.
- Card trimming is **cancelled by decision** — all 52 faces stay.

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
- Jam Post: **published**; ship updates to it only, never a second Post.
- Card art: *Card Asset Pack* by natomarcacini, **CC0** → no attribution file
  required; `license: "proprietary"` stays; credits line kept in `meta.json`.
- No custom `THIRD-PARTY-NOTICES.txt` in the repo. The ZIP still carries the
  SDK notices, which are generated by the packager.
- Music and SFX: generated for this game → own work.
- Music format: **OGG** (`theme.ogg`), not WAV.
- Font: **Quicksand Bold** (`quicksand_bold.ttf`), SIL OFL 1.1.
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

Blocking/legal before the final upload:
- **Quicksand OFL notice.** The font's name table says *SIL Open Font License
  1.1* and asks for the copyright/license to travel with the font. The current
  no-notices decision is fine for the CC0 card pack, but it leaves the font
  notice out. Cheapest clean fix: restore `THIRD-PARTY-NOTICES.txt` with just
  the Quicksand copyright + OFL 1.1 text, or confirm an acceptable alternative.
- Confirm the exact dashboard flow for **updating an already-published Post**
  with a new build (upload → update Post), and re-test the preview afterwards.

Non-blocking:
- Retune HUD `FONT_SIZE` / `HINT_CHAR_EM` / label sizes after the font swap
  (P1-8).
- Redesign the card back (P1-8).
- Whether to keep the repo name/folder as is.
- Whether to add a tasteful "enjoyed it? vote below" nudge before the result
  (allowed; no incentives).

## 12. Reminders / gotchas

- The Post is published: **update it, do not create another** (one entry per
  person).
- The upload title is locked to *Deal With It*.
- Every change must be re-uploaded and re-tested before **Nov 11, 08:00 GMT-3**.
- The packager validates the **editor's cached** scripts: build before packaging.
- `report_result` fires exactly once; do not add a second ending path.
- `flavor_text` is truncated silently at 64 chars.
- userData writes are ignored on a Post's replays (first result only) and on
  oversized values (>1024 bytes).
- Do not call `report_result` before `loading_done`.
- The app's game slot is ~2:3, not the 960×1480 design surface; layout is
  derived from `window.get_size()` via `minit_platform/layout.lua`.
- Labels are ASCII-only: the font character set has no em dash, curly quotes or
  ellipsis. Use `-`, `'`, `...`.
- Jam rules: no edits after going live, no vote incentives, rights must be
  clean, a moderator reviews the entry.
- The jam page said "9 submissions" at review time.

## 13. Reference

Files:
`game.project`, `meta.json`, `main/game.script`, `main/cards.lua`,
`main/field.lua`, `main/deck.lua`, `main/pop.script`, `main/hint_ring.script`,
`main/uncompressed/cards.atlas`, `assets/fonts/game.font`,
`assets/fonts/quicksand_bold.ttf`, `assets/music/theme.ogg`,
`tools/make_music.py`.

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
