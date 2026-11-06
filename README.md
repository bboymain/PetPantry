# Pet Pantry

One-click Hunter pet feeding and pet chatter for **WoW Forever 1.60.1**.

[CurseForge](https://www.curseforge.com/wow/addons/pet-pantry) · [GitHub Releases](https://github.com/bboymain/PetPantry/releases)

## Use

Install the packaged `PetPantry` folder in your Forever client's `Interface/AddOns`.
Open `/pantry`, add food from your bags, and click your pet portrait to feed it.
Choose a different click or a keybind in settings. Feeding is disabled during combat.
Only listed foods are consumed, in priority order. `/pantry debug` saves a diagnostic snapshot.

## Update on GitHub

This repository is the source of truth. Edit the Lua/source files here and commit
changes to `main`; GitHub Actions tests and builds a preview ZIP automatically.
Ordinary commits do **not** publish to CurseForge.

When the update is tested in game:

1. Update `## Version:` in `PetPantry.toc` and add that version's section to `CHANGELOG.md`.
2. Open **Releases → Draft a new release**, create the matching tag (for example `v1.0.2`), and publish it.
3. GitHub Actions runs tests, validates the ZIP, and uploads it to CurseForge project **1720041** and the GitHub release.

The tag must exactly match `v` plus the TOC version. Draft releases do not upload.
Use a version containing `-beta` and a GitHub prerelease when publishing a beta.
Check the Actions result and CurseForge receipt/moderation status before calling a release live.
Do not also enable a CurseForge repository webhook: this workflow already handles uploads.

## One-time CurseForge connection

Create an upload token for the CurseForge account that owns Pet Pantry at
[CurseForge API tokens](https://www.curseforge.com/account/api-tokens).
Save it in **GitHub → Settings → Secrets and variables → Actions → New repository secret**
with the exact name **`CF_API_TOKEN`**. Keep it out of source files, issues, and chat.
GitHub's built-in `GITHUB_TOKEN` handles release assets; no additional GitHub token is needed.

## Development checks

```sh
python -m pip install -r requirements-dev.txt
python tests/test_release.py
```

Tests execute the addon with a simulated WoW UI in Lua 5.1, including a regression
that reproduces the public 1.0.0 vendor crash at line 817. The original ZIP is a
test fixture, excluded from release packages. Real feeding, frame appearance,
and protected-action/taint behavior still require an in-game test.

Version **1.0.1** contains the Forever compatibility fixes. Automated checks pass;
the in-game smoke test has not yet been confirmed. The CurseForge upload secret
is configured. Check GitHub Actions and CurseForge for the release delivery status.

Local working copy: `C:\Users\Matt\Documents\PetPantry`.

## Translations

Version **1.0.2** adds separate text files. German translators can edit
[`Locales/deDE.lua`](Locales/deDE.lua); English defaults are in
[`Locales/enUS.lua`](Locales/enUS.lua). German clients automatically use the
German overrides, and unfinished entries stay in English. A few German labels
are provided as examples; the full German translation is still open for contributions.

Read [TRANSLATING.md](TRANSLATING.md) for examples and formatting rules. Both locale
files and the guide ship inside the addon ZIP, so translators do not need access
to this private repository. The text covers controls, tooltips, warnings, moods,
titles, species sounds, and pet dialogue. Game-provided names stay localized by WoW.
