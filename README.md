# EffortLess

One press: deposit **all eligible items** to the Uncapped Vault, then **log out**.
A single-action convenience addon for the Uncapped WotLK 3.3.5a realm.

- Trigger: `/el`, `/effortless`, or a draggable minimap button.
- Confirmation prompt (default ON); `/el now` skips it, `/el confirm off` disables it.
- Deposits via the server's `VLTDEPALL` verb; the server decides eligibility
  (quest/bound/kept items stay by design). Works anywhere - no banker needed.
- After depositing, waits for bags to settle, then logs out. The 20s logout
  countdown is server-side (near-instant when resting or if the realm enables it).
- No auto-relogin loop - not possible from an addon once you hit character select.

## Install
Extract the `EffortLess` folder into `Interface\AddOns`. A new addon file was added,
so a full client restart is required (not just `/reload`).

## Releases
Each tagged release carries four deliverables: the addon zip, the **Guide** PDF
(with changelog folded in), the **in a nutshell** quick reference, and the plain
changelog. If GitHub asset upload is unavailable, the same four files are committed
under `releases/<tag>/`.

Author: Mhortai
