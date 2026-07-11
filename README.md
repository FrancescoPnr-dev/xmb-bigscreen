[![Buy me a coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-☕-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/francescopnr)
❤️

# XMB BigScreen

A console-like fullscreen launcher for KDE Plasma, inspired by the PlayStation 3 / PSP
**XrossMediaBar** — built for the living room: TV, couch and gamepad, with Plasma
Bigscreen as the target shell. Born as an independent fork of
[XMB Dashboard](https://github.com/FrancescoPnr-dev/xmb-dashboard). 
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

- KDE Plasma 6.7+ with **plasma-bigscreen** installed (XMB BigScreen reuses its
  session backend: controller/remote input, TV settings modules, environment).
- Qt6 Multimedia QML module, used for the sounds. Most distros ship it with
  Plasma; if not: `qt6-multimedia` (Arch/Solus), `qml6-module-qtmultimedia`
  (Debian/Ubuntu), `qt6-qtmultimedia` (Fedora/openSUSE).

## Install

> **Recommended:** install the [YAMIS](https://store.kde.org/p/2303161) monochrome
> icon theme first (KDE Store, GPL-3.0, by DIRN) and set it in *System Settings →
> Colors & Themes → Icons*. XMB BigScreen is designed around its clean adaptive
> look, and the whole cross stays visually coherent. (Thanks DIRN, awesome set) 

```bash
sudo ./install.sh     # remove with: sudo ./uninstall.sh
```

Log out and pick **XMB BigScreen** at the login manager, next to your normal
Plasma and Plasma Bigscreen sessions. The installer deploys the homescreen
containment, a thin shell profile on top of Bigscreen's, the Wayland session,
and the optional stick-swap tool.

> **Note:** the `tools/` and `po/` folders are development sources only (sound
> generators, translation files, packaging). Nothing from them ever runs on
> your machine.

## Usage

The XMB is the session's homescreen — always there, with apps launching on top.

- **Arrows / D-pad / left stick / wheel / screen edges** — move between apps and categories.
- **Enter / South button or left-click** the highlighted app, or **middle-click anywhere** — launch it.
- **Start typing** — search; Enter or middle-click runs the top result.
- **PS/Guide button or Meta** — home overlay over the running app: open apps,
  power actions, volume/brightness, quick settings.
- **Back / Esc** — close the overlay.

### Swapping the analog sticks

By default the Bigscreen input handler moves the mouse pointer with the **right**
stick and navigates lists with the left. If you prefer the pointer on the left
stick (and list scrolling plus L3-as-click accordingly):

```bash
xmb-bigscreen-stick-swap        # with the controller connected
xmb-bigscreen-stick-swap --off  # back to the physical layout
```

Takes effect at the next XMB session login. Only the system input handler sees
the swap — games keep the physical stick layout. Run it once per controller and
connection type (USB and Bluetooth count as different controllers).

## Configuration

From the home overlay pick *Settings → XMB settings*, or hover the top edge with
a mouse. Sections for appearance, behaviour, the wave background and colour,
sounds, and visible categories. Each section has its own "reset to defaults".

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
