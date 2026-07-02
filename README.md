[![Buy me a coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-☕-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/francescopnr)
❤️

# XMB Dashboard

A fullscreen app launcher for KDE Plasma 6, inspired by the PlayStation 3 / PSP
**XrossMediaBar**. 
Navigable by keyboard, controller, mouse wheel and mouse edges, with the classic wave
background, type-to-search and subtle sounds.

> Built and tested on Plasma 6.7 / Qt 6.

<img width="640" height="360" alt="output_compresso" src="https://github.com/user-attachments/assets/50e8aa85-5891-46c0-b3a4-89c56a1cb6be" />



## Features

- XMB-style cross navigation (categories horizontal, apps vertical).
- Animated wave background with monthly colour presets and particles.
- Type anywhere to search (KRunner results).
- Mouse: wheel scrolls apps, screen edges scroll categories, middle-click launches
  the highlighted app.
- Navigation "tick" sound and an optional ambient background loop (both original,
  configurable, off by default where relevant); both can be replaced with your
  own sound files from the settings.
- Lots of tunables in the settings: icon sizes, cross position, scroll feel,
  wave look, sounds, and which categories to show.

  <img width="3723" height="1433" alt="2" src="https://github.com/user-attachments/assets/7c113a95-f20d-4587-b197-651b6ee3ae72" />


## Requirements

- KDE Plasma 6 (6.7+ for native controller support), any distribution.
- Qt6 Multimedia QML module, used for the sounds. Most distros ship it with
  Plasma; if not: `qt6-multimedia` (Arch/Solus), `qml6-module-qtmultimedia`
  (Debian/Ubuntu), `qt6-qtmultimedia` (Fedora/openSUSE).

## Install

> **Recommended:** install the [YAMIS](https://store.kde.org/p/2303161) monochrome
> icon theme first (KDE Store, GPL-3.0, by DIRN) and set it in *System Settings →
> Colors & Themes → Icons*. XMB Dashboard is designed around its clean adaptive
> look, and the whole cross stays visually coherent. (Thanks DIRN, awesome set) 

From the folder containing `metadata.json`:

```bash
# install
kpackagetool6 --type Plasma/Applet --install .
# update after changes
kpackagetool6 --type Plasma/Applet --upgrade .
# remove
kpackagetool6 --type Plasma/Applet --remove org.kde.plasma.xmbdashboard
```

Then add it from *Add Widgets…* and click its panel icon to open the dashboard.
For quick iteration during development, `plasmoidviewer --applet .` (from
`plasma-sdk`) loads straight from source.

> **Note:** the `tools/` and `po/` folders are development sources only (sound
> generators, translation files, packaging). They are not part of the installed
> widget and nothing from them ever runs on your machine.

## Usage

The widget is just a panel button: the XMB itself opens as a fullscreen
overlay on top of your desktop, and closes with Esc — nothing sits on the
desktop permanently.

- **Arrows / wheel / screen edges** — move between apps and categories.
- **Enter or left-click** the highlighted app, or **middle-click anywhere** — launch it.
- **Start typing** — search; Enter or middle-click runs the top result.
- **Esc or click empty space** — close.

## Configuration

Right-click the widget → *Configure*. Sections for appearance, behaviour, the
mouse category bar, the wave background and colour, particles, sounds, and visible
categories. Each section has its own "reset to defaults".

<img width="3554" height="2069" alt="4" src="https://github.com/user-attachments/assets/c402e973-104d-451d-b1d1-cb7f422db742" />


## Credits & licence
[![Buy me a coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-☕-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/francescopnr)

- The wave background is a Qt/QML port of **[PlayStation-3-XMB]** by Mart (linkev),
  used under its MIT licence. That project in turn credits [Alphardex]'s CodePen
  prototype and Sony's original XMB design.
- All sounds are original synthesis (see `tools/`); no PlayStation audio is bundled.
- App data comes from Plasma's own menu model (the same one Kickoff uses).

All the repo is licensed under **GPL-3.0** (see the `LICENSES/` folder). 

[PlayStation-3-XMB]: https://github.com/linkev/PlayStation-3-XMB
[Alphardex]: https://codepen.io/alphardex/pen/poPZNwE


<img width="1408" height="768" alt="5" src="https://github.com/user-attachments/assets/5ab9fe31-f96f-43e9-9fbc-7e72241cfa5b" />
