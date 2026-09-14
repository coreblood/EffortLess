# EffortLess - Changelog

## v1.0.0
- Initial release.
- One press: deposit all eligible bag items to the Uncapped Vault, then log out.
- Trigger three ways: /effortless, /el, or a draggable minimap button.
- Confirmation dialog before acting (default ON). `/el now` acts immediately; `/el confirm off` turns the prompt off.
- Deposits via the server's VLTDEPALL verb over the REAGENTBANK transport. The server decides eligibility - quest, bound, and kept-rule items stay in your bags by design (not a bug). Works anywhere; no banker or open vault window needed.
- After sending the deposit, waits until bags stop changing (deposits landed) before logging out: 1.2s settle window, 6s hard cap.
- Note: the 20-second logout countdown is enforced server-side. Logout is near-instant only when resting (city/inn) or if the realm has instant logout enabled.
