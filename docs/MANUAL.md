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

## The minimap button

- **Left-click** activates EffortLess.
- **Drag** it anywhere; the exact position is saved between sessions.
- Hide it with `/el button` if you prefer slash-only use.

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
