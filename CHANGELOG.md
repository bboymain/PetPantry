# Pet Pantry

## 1.0.2 — Translation support
- Moved interface text, warnings, tooltips, and pet dialogue into Locales/enUS.lua.
- Added complete templates for German, French, Spanish (Spain and Latin America), Italian, Portuguese, Russian, Korean, and Simplified/Traditional Chinese.
- Automatically loads overrides for the active client locale; untranslated entries keep English defaults.
- German includes a few starter labels; other new templates initially display English until translated.
- Preserves family-specific sounds and chatter for German pet-family names.
- Added checks across every locale for loading, fallbacks, formatting placeholders, and packaged language files.

## 1.0.1 — WoW Forever compatibility fixes
- Fixed an error when opening a food vendor by using Forever's current merchant item API.
- Restored pet loyalty text and debug snapshots using the current pet API.
- Updated optional emote and group chat sharing to the current chat API.
- Made portrait and keybind disarming in combat use WoW's secure state handler; feeding rearms after combat.
- Keeps existing food priorities, settings, meal counts, and pet dialogue.

## 1.0.0 — first release
- Click your pet portrait (or press a keybind) to feed your pet.
- Food priority list: only foods you list are ever used, top of the list first. Drag food in or use "+ Add food from bags".
- Pet card: portrait, name, mood, loyalty, level, meal count, next meal and an animated XP bar.
- Hungry glow on the pet portrait.
- "Don't feed when Happy" option (with sassy jokes if you try anyway).
- Low food warning and vendor pet-food alert.
- Your pet talks: mood lines, idle chatter, combat lines (low health, death, healed), meal reactions — with species-specific noises and lines.
- Optional sharing of pet lines as an emote or in party/raid chat (off by default).
- Milestone titles at 10 / 50 / 100 / 250 / 500 / 1000 meals.
- Sounds: munch, whimper and milestone fanfare.
- Four themes: Forever, Obsidian, Teal, Crimson.
- Minimap button, movable speech bubble.
