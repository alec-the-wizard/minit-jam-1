# Deal With It — Jam Handoff

Written 2026-11-04 at the end of a review session. Self-contained: read this, then
`AGENTS.md`, then start at the first unchecked P0 task.

**Starter prompt for the next session:**

> Read `JAM_HANDOFF.md` in the repo root, then continue with the first unchecked
> task in the priority queue. Read `AGENTS.md` before editing. Ask me before
> changing game rules that are not in the task list. Work task by task, keep the
> packager green, and show me the diff of each task.

---

## 1. Mission

The game is an entry in **Defold Game Jam #1** (Minit Games), theme **"One More
Try"**. The current phase is: polish, validate, upload, create the jam Post.

Key dates (from the jam page's Jam Rules dialog):

| Event | When |
|---|---|
| Submissions close | **Nov 11, 2026, 08:00 GMT-3** |
| Games go live, voting opens | Nov 12, 2026, 08:00 GMT-3 |
| Voting closes | Nov 19, 2026, 08:00 GMT-3 |
| Winners announced | Nov 24, 2026 |

**Games cannot be changed once they go live.** Everything must be final before
the deadline. One entry per person. The game was started on 2026-10-28 (jam
opening day), so it is eligible.

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
  simulation in `main/cards.lua`, face pool in `main/deck.lua`.
- HUD is three label game objects spawned from factories; pop effect is
  `main/pop.go` + `main/pop.script`.
- Audio goes through `minit_platform/audio.lua` (do not edit it).

## 3. Current state (verified at handoff)

- HEAD = `8226dc4 make meta.json config keys match code` — contains the
  packaging fix (see §6). Build passes.
- `dist/Card Rush.zip` exists from that build: **3.69 MB, packaging green**,
  but it is **stale**: it predates the filter change and the title change.
- Working tree: `game.project` is **modified and uncommitted**. The two
  `default_texture_*_filter = nearest` lines were removed, so the game now uses
  Defold's default `linear` filtering. Commit it.
- `game.project` still says `title = Card Rush`. The chosen name is **Deal With
  It** and it must be set before the first upload (the title is applied on the
  first upload only).
- No `THIRD-PARTY-NOTICES.txt` in the repo yet.
- `meta.json` still has the old description, `license: "proprietary"`, and a
  `credits` line that only mentions Defold.
- The editor was running with the project open (port in `.internal/editor.port`,
  token in `.internal/editor.token`).

## 4. Ground rules

- **Never edit `minit_platform/` or `.deps/`.** `minit_platform` is the SDK glue
  that makes the game work inside the Minit app.
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

Expected tail of the report: `Ready to upload: dist/Deal With It.zip (...)`,
`Release build, single-threaded wasm, meta.json included.` and `=> true`.

**Gotcha:** the packager reads scripts through the editor's resource cache. After
editing files outside the editor, run **Project > Build first**, otherwise the
packager validates stale code (this is what hid the fix during the review).

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
    start_pairs = math.floor(number_config(minit.get_config_value("start_pairs", ""), 2, 2, 12)),
    -- ...one literal key per entry
}
```

Any new config key needs a literal `get_config_value("key", ...)` call and a
matching `meta.json` entry, or packaging fails.

The packager also checks: `report_result` is referenced, the HTML shell is the
Minit one, the wasm is single-threaded release, ZIP ≤50 MB / ≤2000 files, and
`meta.json` config ≤25 entries with descriptions ≤100 chars.

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
   finish that does not vote hurts the rate.
3. Reach matters: share the published Post link (Discord etc.) after Nov 12.
   Asking players to vote is allowed; offering anything in exchange is not, and
   can get the game disabled.

## 8. Platform requirements — status

| Requirement | Status |
|---|---|
| ZIP, `index.html` at root, wasm-web release, single-threaded | ✅ verified by packager |
| Bundle < 5 MB recommended | ✅ 3.69 MB (will shrink with OGG music) |
| Portrait, touch-only, delta time, any aspect ratio | ✅ |
| No localStorage/fetch/cookies/external assets/navigation | ✅ |
| `loading_done()` | ✅ |
| `report_result()` exactly once | ✅ |
| `meta.json` config keys match literal reads | ✅ fixed |
| Same challenge per Post (seed) | ❌ P2-1 |
| Pause when off-screen | ❌ P2-2 |
| First-play tutorial gated on `should_show_tutorial()` | ❌ P1-4 |
| Personal best via userData | ❌ P1-5 (also needs a console toggle) |
| Flavor text ≤64 chars | ⚠️ check after rewrite |
| Licensing/notices for art | ❌ P0-2 |

## 9. Priority queue

Do in order. Each task ends with a build + package run when it touches code.

### P0 — must happen before upload (blocking)

**P0-1 — Commit the filter change and set the title.**
- `game.project`: commit the removed filter lines (defaults to linear).
- Set `title = Deal With It` under `[project]` (≤50 chars). The packager uses
  it; minit.studio reads it on the **first upload only**.
- The dist file will be named `dist/Deal With It.zip`.
- Acceptance: `git status` clean; packaging green with the new title.

**P0-2 — Licensing notices and credits.**
- Card art: *Card Asset Pack* by **natomarcacini**, **CC0 1.0**. Music and SFX
  were generated for this game (own work).
- Create `THIRD-PARTY-NOTICES.txt` at the repo **root**. The packager appends it
  to the Defold/SDK notices and ships it as `THIRD-PARTY-NOTICES.txt`
  (`minit_package.lua:565-576`). Add the pack name, author, CC0, and the source
  URL if available.
- `meta.json`:
  - keep `"license": "proprietary"` (it covers the game as a whole);
  - `credits` should read roughly: `Card art: Card Asset Pack by natomarcacini
    (CC0 1.0). Music and sound effects generated for this game. Built with
    Defold (Defold License 1.0).`
  - add `sourceUrl` only if there is a real URL (it must start with http/https).
- Acceptance: packaging green; ZIP contains the notices; no guessed URLs.

**P0-3 — Rebuild, package, verify the ZIP.**
- Run the build + package commands (§5). The old `Card Rush.zip` is stale and
  must be ignored.
- Confirm `meta.json` inside the ZIP has `"title": "Deal With It"`.
- Expected size ≈3.7 MB.

**P0-4 — Test on a real phone before the deadline.**
- Upload the ZIP, open the game's page, QR button → *Generate preview link*
  (valid 15 minutes), scan with the Minit app.
- Checklist:
  - first frame is not half-drawn; `loading_done` works;
  - the **first tap** produces sound/cards (see P1-1);
  - audio is audible (the packager cannot check this);
  - the run ends and the **result screen appears**;
  - the **vote screen** appears and advances after ~6s;
  - backgrounding the app behaves acceptably (after P2-2, the clock pauses);
  - `?tutorial=0` in a web preview hides the tutorial (returning-player path).

**P0-5 — Create the jam Post (deadline: Nov 11, 08:00 GMT-3).**
- Upload → Game details → Post. In the Post step choose **Defold Game Jam #1**
  from the drop-down before publishing.
- The caption is the only thing a player sees before the first move (≤80 chars).
  Write it as a challenge, e.g. *"The cards don't hold still. How many pairs can
  you find in a minute?"*
- One entry. Do not publish a second jam Post.

### P1 — before the freeze (highest score impact)

**P1-1 — Make the first tap do something.**
- Today every card is in phase `peek` during the reveal and
  `cards.pick()` only accepts `hidden` (`main/cards.lua:303-310`), so the first
  tap is ignored (`main/game.script:322-335`).
- Add `M.skip_peek(world)`: for every card with `phase == "peek"`, set
  `card.timer = 0`; return true if any card was peeking.
- In `on_input`, before `cards.pick`: `if cards.skip_peek(self.cards) then ...
  return end`. The tap should also start the clock (P1-3).
- Acceptance: tapping during the opening reveal flips the whole table down; the
  next tap picks a card; no double-pick.

**P1-2 — Start with 3 pairs, not 2.**
- `meta.json` `start_pairs` default 3 (min 2); `read_config()` fallback 3.
- Reason: 4 cards on a 25-cell felt looks empty; 6 cards sell the twist at once.
- Acceptance: first table has 6 cards.

**P1-3 — The clock starts when the deal is face down.**
- Add `self.clock_started`. Do not decrement `time_left` until the first table
  is fully face down (or the player skipped the peek with P1-1).
- Acceptance: the HUD reads 1:00 on the first tappable frame; the reveal is
  free.

**P1-4 — First-play tutorial, gated.**
- Capture **once** at init: `self.tutorial = minit.should_show_tutorial()`.
- When true, on the first table only: hint `"Memorize!"` during the peek, then
  `"Tap two matching cards"` plus a pulsing glow ring on one hidden card (a
  small new GO + script is fine; `assets/ui/glow.png` already exists). Remove
  the hint/ring on the first successful pick.
- Keep it short; do not block input. No tutorial for returning players.
- Acceptance: default web preview shows it; `?tutorial=0` does not; app hides
  it after the first recorded result.

**P1-5 — Personal best.**
- Console: Game → Edit → tick **Store User Data**, key e.g.
  `dealwithit-best` (1–64 chars). Without this, reads return nil and writes are
  silently dropped.
- Read at init with `minit.get_user_data()`, store a versioned string
  `v1:<score>`; ignore unparsable values.
- Write at the end of the run: `report_result(score, { user_data = ("v1:%d"):format(best) })`.
- Show `BEST 563` in the HUD (a 4th small label under the score, or reuse the
  hint on table 1) and flash `NEW BEST!` when beaten.
- Note: the platform only writes a Post's **first** result; replays do not update
  the slot. Keep an in-session best as well.
- Acceptance: best survives app restart; a first-time player sees no fake value;
  the result still reports exactly once.

**P1-6 — Land the ending.**
- In `finish()`: `set_hint(self, "Time's up!")`; keep the reveal and
  `delay = 1000`.
- Rewrite `flavour_text(stats)` into 3–5 outcome-specific lines with personality
  and a near-miss/challenge hook (≤64 chars, e.g. `"27 pairs. One more try?"`,
  `"New best: 640 — beat that."`, `"Zero pairs. The cards won."`).
- Acceptance: ≤64 chars each (the SDK warns), result screen shows ~1s after the
  last table.

**P1-7 — Rewrite `meta.json` for players.**
- Lead with the twist and the name; keep 2–4 sentences per section; total
  description+controls+logic ≤2500 chars.
- Remove the hardcoded `10 points`, `1 minute`, and the **wrong** claim that the
  opening reveal is the only free look — every table is dealt face up.
- Keep the controls text accurate for touch.
- Config values stay aligned with code (see P2-4 table).
- Acceptance: valid JSON, packaging green, description matches what the game
  actually does in a 60s Post.

**P1-8 — Card back and table identity.**
- `assets/cards/card_back.png` is a flat blue rectangle with a diagonal seam
  (139×208). Give it a pattern/emblem so it reads as the game's identity.
- Optional: warmer felt, a vignette; a custom OFL font for the HUD (add it to
  `THIRD-PARTY-NOTICES.txt`).
- Acceptance: still 139×208 (atlas unchanged), readable at ~1.5× on screen.

### P2 — if time remains (also long-term value)

**P2-1 — Seed: same challenge for every player of a Post.**
- `meta.json`: add `seed` (number, default 1, min 0, max 999999).
- `game.script`: `local seed = tonumber(minit.get_config_value("seed", "")) or os.time()`
  then `math.randomseed(seed)`; delete `math.randomseed(os.time())` at line ~251.
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
Marketable values (also use them in `meta.json` and the code clamps):

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

**P2-5 — Shrink the bundle.**
- `assets/music/theme.wav` is 1.92 MB (22s mono). Export OGG (≈250 KB), point
  `main/game.go` at it, keep the loop seamless. The bundle should drop to ≈2.5 MB.
- Optional: trim the deck (52 faces, only ≤6 used per table; the atlas is 8.4 MB
  uncompressed). Keep at least ~20 faces for variety.

### P3 — after the jam

- Turn the dials into a numbered series of Posts (`Daily Shuffle #12`) with a
  fixed seed per Post; schedule up to 4 weeks ahead; alternate easy/hard; at
  most 2 Posts per Game per day.
- Keep the personal best across Posts (same userData key).
- Consider `sound`/`music` preferences in userData (`audio.configure` already
  exists and is unused).
- Keep every Post self-contained for first-timers.

## 10. Decisions already made

- Name: **Deal With It** (must be in `game.project` before the first upload).
- Card art: *Card Asset Pack* by natomarcacini, **CC0** → keep `license:
  "proprietary"`, add notices/credits.
- Music and SFX: generated for this game → own work.
- Texture filtering: **linear** (the art is anti-aliased; nearest produced
  jaggies at ~1.57×).
- Theme read: memory game + moving cards = "One More Try" and "Clever Twist".
- Target categories: Brain Burner, Clever Twist, High Score Fever, plus
  Beautiful/Funny as breadth for the Best Game sum.
- 60-second default run stays (platform's ~1 minute rhythm).

## 11. Open decisions (ask the user)

Blocking before upload:
- The exact source URL of the CC0 card pack (or confirmation to ship without
  one).
- The final jam **caption** (≤80 chars).
- Confirmation that *Store User Data* was enabled with the chosen key (P1-5).

Non-blocking:
- Convert music to OGG (needs an encoder) or keep WAV.
- Add a custom OFL font for the HUD, or keep Defold's Vera Mono Bold.
- Keep all 52 card faces or trim the atlas.
- Whether to show the best score as its own HUD label or reuse the hint.
- Whether to keep the repo name/folder as is.
- Whether to add a tasteful "enjoyed it? vote below" nudge before the result
  (allowed; no incentives).

## 12. Reminders / gotchas

- `game.project` is dirty at handoff — commit the filter change.
- Title is still `Card Rush`; the first upload locks it.
- `dist/Card Rush.zip` is stale; delete/ignore it after rebuilding.
- The packager validates the **editor's cached** scripts: build before packaging.
- `report_result` fires exactly once; do not add a second ending path.
- `flavor_text` is truncated silently at 64 chars.
- userData writes are ignored on a Post's replays (first result only) and on
  oversized values (>1024 bytes).
- Do not call `report_result` before `loading_done`.
- The app's game slot is ~2:3, not the 960×1480 design surface; layout is
  derived from `window.get_size()` via `minit_platform/layout.lua`.
- Jam rules: no edits after going live, no vote incentives, rights must be
  clean, a moderator reviews the entry.
- The jam page said "9 submissions" at review time.

## 13. Reference

Files:
`game.project`, `meta.json`, `main/game.script`, `main/cards.lua`,
`main/field.lua`, `main/deck.lua`, `main/pop.script`, `main/uncompressed/cards.atlas`,
`assets/fonts/game.font` (Vera Mono Bold DF), `tools/make_music.py`.

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
