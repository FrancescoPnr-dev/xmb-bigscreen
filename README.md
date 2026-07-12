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
and the pad-mapping tool.

> **Note:** the `tools/` and `po/` folders are development sources only (sound
> generators, translation files, packaging). Nothing from them ever runs on
> your machine.

## Usage

The XMB is the session's homescreen — always there, with apps launching on top.

- **Arrows / D-pad / left stick / wheel / screen edges** — move between apps and categories.
- **Enter / South button or left-click** the highlighted app, or **middle-click anywhere** — launch it.
- **Start typing** — search; Enter or middle-click runs the top result.
- **Triangle** — search with an on-screen keyboard: d-pad moves the key
  highlight, **Cross** inserts, **Square** deletes, **L1/R1** move through
  the results, **Circle** closes.
- **Text fields in regular apps** — with the optional `plasma-keyboard`
  package installed, a compact keyboard pops up on the focused field and the
  d-pad navigates it: **Cross** types, its ⏎/hide keys finish.
- **PS/Guide button or Meta** — home overlay over the running app: open apps,
  power actions, volume/brightness, quick settings.
- **Back / Esc** — close the overlay.

### Pad mapping

Controllers work out of the box: the session refreshes the pad mapping at every
login and whenever a controller connects, so Triangle (search) and Square
(delete) are always wired — plug in or pair a pad and it just works. Only the
system input handler sees the mapping — games keep the physical layout.

By default the Bigscreen input handler moves the mouse pointer with the
**right** stick and navigates lists with the left. To put the pointer on the
left stick (with list scrolling and L3-as-click accordingly), flip *Settings →
XMB settings → Controller → Pointer on the left stick*, or run
`xmb-bigscreen-stick-swap --on` (`--off` to go back). It applies from the next
login.

## Configuration

Open the system band (PS/Guide button, Meta, or hover the top edge) and pick
*Settings → XMB settings*. The settings window is styled after Plasma Bigscreen's
own TV settings — a sidebar of sections (appearance, wave background with live
RGB preview, clock, sounds, visible categories, favorites, language, icons) and
native delegates, fully navigable by controller or remote. Changes apply live.

The **icon theme** chosen there applies to the XMB session only, from the next
login, and never touches your desktop session's theme.

### Autologin (couch mode)

The login screen cannot be driven by a controller, so a living-room machine
should boot straight into the XMB. With Plasma Login Manager (or SDDM), either
enable it from *System Settings → Login Screen* picking the *XMB BigScreen*
session, or drop a file as root:

```ini
# /etc/plasmalogin.conf.d/xmb-autologin.conf  (SDDM: /etc/sddm.conf.d/)
[Autologin]
User=YOUR_USER
Session=plasma-xmbbigscreen-wayland
```

The XMB session never locks the screen by itself (no idle lock, no lock on
resume from sleep), and the power menu carries no Lock entry — a password
prompt is a dead end on a TV. Logging out still reaches the login screen:
the overlay warns first, and rebooting the machine autologs back in.

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
