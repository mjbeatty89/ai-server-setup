## 2026-02-10 - Consolidating apt updates with add-apt-repository
**Learning:** `add-apt-repository` automatically triggers `apt update` on recent Ubuntu versions, causing redundant updates in sequential repo additions.
**Action:** Use the `-n` flag with `add-apt-repository` to skip updates, then consolidate all repository additions before a single `apt update`.
