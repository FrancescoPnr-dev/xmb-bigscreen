[![Buy me a coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-☕-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/francescopnr)
❤️

# XMB BigScreen

A console-like fullscreen launcher for KDE Plasma, inspired by the PlayStation 3 / PSP
**XrossMediaBar** built for the living room: TV, couch and gamepad.

> Built and tested on Plasma BigScreen 6.7 / Qt 6.


<img width="3723" height="1433" alt="2" src="https://github.com/user-attachments/assets/7c113a95-f20d-4587-b197-651b6ee3ae72" />


## Requirements

- KDE Plasma **6.7+** with **plasma-bigscreen** installed from your distro's
  repositories (XMB BigScreen reuses its session backend: controller input,
  TV settings, environment).
- The Qt6 Multimedia QML module, for the sounds. Most distros ship it with Plasma;
  if not: `qt6-multimedia` (Arch), `qml6-module-qtmultimedia` (Debian/Ubuntu),
  `qt6-qtmultimedia` (Fedora/openSUSE).
- Optional: `plasma-keyboard`, so text fields inside regular apps also get a compact
  pad-navigable keyboard.

## Install

```bash
git clone https://github.com/FrancescoPnr-dev/xmb-bigscreen.git
cd xmb-bigscreen
sudo ./install.sh
```

Then log out and pick **XMB BigScreen** at the login manager, next to your normal
Plasma session. The installer deploys the homescreen, a thin shell profile on top of
Bigscreen's, the Wayland session and the pad-mapping tool. Remove everything with
`sudo ./uninstall.sh`.

> **Tip:** the [YAMIS](https://store.kde.org/p/2303161) monochrome icon theme
> (KDE Store, GPL-3.0, by DIRN) fits the XMB look perfectly. Install it, then pick it
> in *XMB settings → Icons* — it applies to the XMB session only (need logout-login), your desktop keeps
> its own theme.

> **Note:** the `tools/` and `po/` folders are development sources only (sound
> generators, translation files, packaging). Nothing from them ever runs on
> your machine.

## Using it

The XMB is the session's homescreen always there, with apps launching on top.

- **D-pad / left stick / arrows / wheel / screen edges**, move around the cross.
- **Cross / Enter / click**, launch the highlighted app.
- **Triangle**, search: the on-screen keyboard opens, **Cross** types,
  **Square** deletes, **L1/R1** move through the results, **Circle** closes.
  On a real keyboard, just start typing.
- **PS/Guide button or Meta**, home overlay over the running app: switch or close
  apps, volume, brightness, power actions, quick settings.
- **Circle / Back / Esc**, go back, one layer at a time.
- **Text fields in apps**, with `plasma-keyboard` installed, a compact keyboard
  pops up on the focused field and the d-pad drives it.


### Autologin (couch mode)

A login screen cannot be driven by a controller, so a living-room machine should
boot straight into the XMB. Enable autologin from *System Settings → Login Screen*
picking the *XMB BigScreen* session.

The XMB session never locks the screen by itself (no idle lock, no lock on resume)
and the power menu has no Lock entry, a password prompt is a dead end on a TV.
Logging out still reaches the login screen: the overlay warns first, and rebooting
autologs back in.

## For contributors

- `contents/` is the homescreen (a Plasma containment), `shell/` the thin shell
  profile, `session/` the Wayland session script and the pad-mapping tool.
- **Translations** live in `po/`. To add a language, create `po/<lang>.po` from
  `po/plasma_applet_org.kde.plasma.xmbbigscreen.pot`, translate it, then run
  `tools/build-i18n.sh` to regenerate the template and compile the catalogs.
- CI checks licensing (REUSE), metadata, translations and the package build on
  every push and pull request.

## Credits & licence
[![Buy me a coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-☕-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/francescopnr)

- The wave background is a Qt/QML port of **[PlayStation-3-XMB]** by Mart (linkev),
  used under its MIT licence. That project in turn credits [Alphardex]'s CodePen
  prototype and Sony's original XMB design.
- The settings window replicates the Plasma Bigscreen settings app UI
  (GPL-2.0-or-later, by the KDE contributors Marco Martin <mart@kde.org>, Aditya Mehra <aix.m@outlook.com>, Devin Lin <devin@kde.org>).
- All sounds are original synthesis (see `tools/`); no PlayStation audio is bundled.
- App data comes from Plasma's own menu model (the same one Kickoff uses).

All the repo is licensed under **GPL-3.0** (see the `LICENSES/` folder).

[PlayStation-3-XMB]: https://github.com/linkev/PlayStation-3-XMB
[Alphardex]: https://codepen.io/alphardex/pen/poPZNwE


<img width="1408" height="768" alt="5" src="https://github.com/user-attachments/assets/5ab9fe31-f96f-43e9-9fbc-7e72241cfa5b" />
