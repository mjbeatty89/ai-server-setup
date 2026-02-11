## 2026-02-11 - Batching APT Repository Updates
**Learning:** `add-apt-repository` triggers `apt update` by default, which can be redundant when adding multiple repositories.
**Action:** Use the `-n` flag with `add-apt-repository` to suppress immediate updates, and run a single `sudo apt update` after configuring all repositories to minimize network operations and improve setup time.
