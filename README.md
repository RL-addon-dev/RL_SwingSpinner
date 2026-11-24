# RL: Weapon Swing Spinner

Swing timers as small spinning circles, one for each weapon. They look like the swing timer on
WoW Forever's gamepad reticle, and work with a mouse and keyboard or the gamepad UI.

**WoW Forever only.** It's the only version of the game with swing timer events.

## Getting started

1. Install it and log in. The main hand spinner is on by default, and shows while your next
   swing fills.
2. Open Edit Mode to drag each spinner where you want it.
3. Change the rest in the settings: `/wss`, `/swingspinner` or `/weaponswingspinner`, the
   minimap's addon drawer, or Esc → Options → AddOns → Weapon Swing Spinner.

## Features

### A spinner for each weapon

The main hand, off hand and ranged weapon each get their own spinner. A spinner fills as its next
swing comes round, with the same animation as the gamepad UI. The off hand and ranged spinners
only show while you have a weapon equipped there. The main hand shows unarmed too.

### Shown when you need them

Under `Spinner Visibility`, tick any mix of `Enemy Targeted`, `In Combat` and `Swing Recharging`,
or `Always`. By default, each spinner only shows while its swing recharges, like the gamepad UI's
timer.

`In Combat` turns on as soon as you start attacking, or as soon as an enemy attacks you. It
doesn't wait for the first hit to land.

### Your look

Each spinner keeps the game's own colors, or takes a color you pick, white included. Each has its
own size and opacity. Once a weapon is ready, its spinner can stay full, empty or faded, or hide.
Spinners can also start full and drain, and show the seconds left in the middle.

### One circle for both hands

With `Combine With Main Hand` on the off hand tab, both hands share one circle, like the gamepad
UI. The off hand is the left half and the main hand the right. Without an off hand weapon, the
main hand fills the whole circle.

### Edit Mode

Every spinner is placed in the game's Edit Mode. Click one there to change its size and opacity
in place. `Reset Positions` in the settings puts them all back.

### The gamepad UI

The spinners work in WoW Forever's gamepad UI too. While any spinner is turned on, the reticle's
own swing timer is hidden, so you don't get two. Turn every spinner off and it comes back.

The game's swing timer bars are left alone, so you can use them alongside the spinners.

## Reference

<details>
<summary><b>Settings</b></summary>

Everything is in `/wss` (also under Options → AddOns). The tables follow the tabs from top to
bottom.

**General: Spinner Visibility**

A spinner shows while any ticked option is true, and only for weapons you have equipped.

| Setting | Default | What it does |
|---|---|---|
| `Always` | Off | Spinners show all the time. The other options are turned off while it's ticked. |
| `Enemy Targeted` | Off | Spinners show while an enemy you can attack is targeted. |
| `In Combat` | Off | Spinners show while you're in combat, whether you start the fight or an enemy attacks you. |
| `Swing Recharging` | On | Each spinner shows while its next swing fills. |

**General**

| Setting | Option | Default | What it does |
|---|---|---|---|
| `Idle Style` | `Empty` |  | A ready spinner shows only its background ring. |
|  | `Fade` |  | A ready spinner shows a full circle at `Fade Opacity`. |
|  | `Full` |  | A ready spinner shows a full circle. |
|  | `Hidden` | Default | A ready spinner hides. |
| `Fade Opacity` | Percent | 35% | How faded a ready spinner is. Shown with `Idle Style` set to `Fade`. |
| `Spinner Behavior` | `Fill` | Default | A spinner fills as its swing comes round. |
|  | `Drain` |  | A spinner starts full and empties. |
| `Show Countdown` | On or off | Off | The seconds left, in the middle of each spinner. |

**General: Position**

| Setting | What it does |
|---|---|
| `Edit Mode` | Open Edit Mode to drag each spinner. Click one to change its size and opacity. |
| `Reset Positions` | Moves every spinner back to its default place. |

**Main Hand, Off Hand and Ranged**

Each tab has the same settings for its spinner.

| Setting | Option | Default | What it does |
|---|---|---|---|
| `Enable` | On or off | On | Whether this spinner is used. |
| `Combine With Main Hand` | On or off | Off | Off hand only. It shares the main hand's circle as its left half, with the main hand's place, size and opacity. |
| `Default Color` | On or off | On for the main hand | Uses the game's own colors. |
| `Color` | Color | Gold, orange, green | The spinner's color. Shown with `Default Color` off. |
| `Size` | Percent | 100% | From 50% to 300%. |
| `Opacity` | Percent | 100% | From 10% to 100%. |

</details>

## Moving from RL: QoL Tweaks

The spinners used to be part of RL: QoL Tweaks. The first time this addon loads, it takes over
their positions. If QoL Tweaks had turned the game's swing timer bars off, they're turned back on
once.

## Development

The settings libraries (`libs\AX_Modules`, `libs\AX_Settings`) live in their own repo,
[AX_Libs](https://github.com/RL-addon-dev/AX_Libs). The CurseForge packager pulls them in for each
release, at the tag in `.pkgmeta`. To work on the addon, clone them into `libs`:

```
git clone https://github.com/RL-addon-dev/AX_Libs.git libs
```

## Credits and license

RL: Weapon Swing Spinner is free software under the **GNU General Public License v3** (see
`LICENSE` and `NOTICE`).

- The settings window and its UI toolkit (`libs\AX_Settings`, `libs\AX_Modules`) are based on
  **WaypointUI** by **AdaptiveX** (GPLv3).
- The spinner's art and animation are the game's own, from the gamepad UI's swing timer.
