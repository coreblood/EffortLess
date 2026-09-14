# EffortLess - Usage Guide

**One press: deposit all eligible items to the Uncapped Vault, then log out.**

## What it does

EffortLess is a single-action convenience addon for the Uncapped realm. When you
activate it, it:

1. Sends the server's **deposit-all** command, which banks every deposit-eligible
   item from your bags into the Uncapped Vault in one server-side call.
2. Waits briefly for those deposits to land.
3. Logs you out.

No banker and no open vault window are required - the Uncapped Vault is a custom
server system addressed directly, so this works anywhere in the world.

## How to activate

Any one of these:

- Type **`/el`** (or `/effortless`).
- Click the **minimap button** (a bag icon on the minimap rim).

By default a confirmation prompt appears first - answer **Yes** to deposit and log
out, **No** to cancel.

## Commands

| Command | Effect |
|---|---|
| `/el` or `/effortless` | Deposit all & log out (shows the confirm prompt if enabled). |
| `/el now` | Deposit all & log out **immediately**, skipping the prompt. |
| `/el confirm on` / `off` | Turn the confirmation prompt on or off. |
| `/el button` | Show or hide the minimap button. |
| `/el options` | Open the options panel. |
| `/el arm on` / `off` | Arm or disarm auto-run on login. |
| `/el cancel` | Cancel a pending armed countdown (this login only). |

## The minimap button

- **Left-click** activates EffortLess.
- **Drag** it anywhere; the exact position is saved between sessions.
- **Right-click** opens the options panel.
- Hide it with `/el button` if you prefer slash-only use.

## Options panel

Open it from **Interface -> AddOns -> EffortLess**, by **right-clicking** the minimap
button, or with **`/el options`**. Two toggles:

- **Confirm before depositing & logging out** - the Yes/No prompt (same as `/el confirm`).
- **Show minimap button** - the draggable bag icon (same as `/el button`).

## Armed auto-run on login

Turn on **Auto-run on login (armed)** (checkbox in the options panel, or `/el arm on`)
and EffortLess will **deposit all & log out about 9 seconds after every login**. This is
the addon half of a hands-off loop: pair it with an external key-sender that presses
Enter at the character-selection screen, and the cycle runs itself. Armed is **OFF by
default**.

During those 9 seconds an on-screen countdown shows with a **Cancel this login** button
(`/el cancel` does the same). Cancelling skips only that login - the addon stays armed
for the next one. To stop entirely, untick the box or `/el arm off`.

The 9-second wait is deliberate: it is your cancel window, and it also lets the vault
pipe come up after login (a deposit sent too early is silently dropped).

**Escape hatch:** while armed, every login logs you out after the countdown, so you
cannot idle on that character. If you ever get stuck, break the loop from the desktop by
deleting the `EffortLess` addon folder or its SavedVariables file.

## What "all items" means

The **server** decides what is eligible to deposit. Quest items, soulbound items,
and anything the realm keeps by rule (reagents, keys, world-use items, and so on)
stay in your bags on purpose. EffortLess does not filter anything itself - it asks
the server to bank everything eligible and the server prints its own message for
anything it refuses. Items left behind are expected, not a failure.

## About the logout delay

The 20-second logout countdown is enforced by the server, not the addon. Logout is
near-instant only when you are resting (in a city or inn) or if the realm has
instant logout enabled. EffortLess deposits first regardless, so your items are
banked even while the countdown runs.

## Notes & limits

- One action at a time. Triggering again while a deposit/logout is in progress does
  nothing.
- There is **no auto-relogin loop**. Once you reach the character-selection screen,
  no addon is running, so nothing can press a key or log back in for you. That part
  is simply not possible from inside WoW.
- Safe by nature: deposits are reversible (withdraw from the Vault) and logout is
  reversible (log back in). The confirmation prompt exists only to prevent an
  accidental click.

## Changelog

See the changelog section of this guide (folded in below) or the accompanying
`EffortLess Changelog.txt`.
