# Translating Pet Pantry

Edit the file matching your WoW client language. The addon selects its overrides
automatically. `Locales/enUS.lua` supplies English defaults on every client,
including English (US/UK). You do not need to edit `PetPantry.lua`.

| Language | File |
| --- | --- |
| English defaults | `Locales/enUS.lua` |
| German | `Locales/deDE.lua` |
| Spanish (Spain) | `Locales/esES.lua` |
| Spanish (Latin America) | `Locales/esMX.lua` |
| French | `Locales/frFR.lua` |
| Italian | `Locales/itIT.lua` |
| Korean | `Locales/koKR.lua` |
| Portuguese (Brazil) | `Locales/ptBR.lua` |
| Russian | `Locales/ruRU.lua` |
| Simplified Chinese | `Locales/zhCN.lua` |
| Traditional Chinese | `Locales/zhTW.lua` |

Every non-English file contains a commented entry for each interface string,
warning, tooltip, mood, title, sound description, and pet dialogue line. German
also includes a few starter labels. These are templates, not finished translations.
An unfinished or unknown client locale keeps English defaults.

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
The `FAMILY_KEYS` table maps localized family names to stable internal keys;
keep the values on the right in English. German mappings are already supplied.
Other templates include an example for adding mappings. If a family has no mapping,
the pet uses generic chatter/noises instead of an incorrect family-specific line.

## Test and send a translation

Run `python tests/test_release.py`, then test in a WoW Forever client using your language.
Open `/pantry`, inspect the controls/tooltips, feed a pet, visit a food vendor,
and check the speech bubble. Confirm long translations fit the window.

Send the edited locale file to the addon author, or submit a GitHub
pull request if you have repository access. The GitHub repository is currently
private; the template is also included in the addon ZIP, so GitHub access is
not required to translate it. Do not send your SavedVariables or account files.
