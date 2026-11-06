# Translating Pet Pantry

For German, edit **`Locales/deDE.lua`**. The addon loads it automatically when WoW's
language is German (`deDE`). `Locales/enUS.lua` supplies English defaults on every
client. You do not need to edit `PetPantry.lua`.

The German file contains a few starter labels and a commented entry for every
other interface string, warning, tooltip, mood, title, sound description, and
pet dialogue line. It is a translation template, not a finished German translation.

## Translate one line at a time

Remove the leading `-- ` and replace only the quoted text to the right of `=`:

```lua
-- Before
-- L.LEFT_CLICK = "Left-click"

-- After
L.LEFT_CLICK = "Linksklick"
```

Dialogue works the same way:

```lua
L.CHATTER[3][1] = "Bester Jäger aller Zeiten."
L.NOISES.Cat = "*schnurrt*"
```

Leave unfinished entries commented. They keep the English defaults, including
individual dialogue lines. Do not assign empty strings, `nil`, or `false`.
Do not rename keys, change indices, remove lines from arrays, or change the
meal thresholds in `L.MILESTONES`.

## Keep formatting intact

- Keep `%s` (text), `%d` (numbers), and `%%` (a percent sign) in their original order.
- Keep `{noise}` wherever the pet's species sound belongs.
- Keep WoW markup such as `|cffffd24d` and `|r` unchanged and paired.
- Escape quotes inside text as `\"`; save the file as **UTF-8** for umlauts and ß.
- Translate full format strings rather than joining translated word fragments.

Game item names, pet names, family names, and loyalty labels come from WoW itself.
The `FAMILY_KEYS` table maps German family names to stable internal keys; keep
the values on the right in English. Other client languages keep the English
catalog until a corresponding locale file is added.

## Test and send a translation

Run `python tests/test_release.py`, then test in a German WoW Forever client.
Open `/pantry`, inspect the controls/tooltips, feed a pet, visit a food vendor,
and check the speech bubble. Confirm long translations fit the window.

Send the edited `Locales/deDE.lua` file to the addon author, or submit a GitHub
pull request if you have repository access. The GitHub repository is currently
private; the template is also included in the addon ZIP, so GitHub access is
not required to translate it. Do not send your SavedVariables or account files.
