## 2024-05-18 - Optimized Apt Installation
**Learning:** `apt update` is a network-heavy operation. Running it multiple times for each repository addition (1Password, Docker, PPA) significantly slows down the setup script. Grouping repository additions and running a single update is a major performance win.
**Action:** When adding multiple repositories, consolidate them into a single block and run `apt update` only once afterwards. Also, use `xargs` with a larger batch size (e.g., 500) for bulk package installations to reduce `apt` invocation overhead.

## 2024-05-20 - Further Apt Optimization
**Learning:** `add-apt-repository` runs `apt update` by default, creating hidden redundancy even when we manually update later. Also, `apt install` has significant startup overhead; batching 500 packages still results in multiple heavy invocations for large lists (1200+ packages).
**Action:** Always use `add-apt-repository -n` when followed by an explicit update. Increase `xargs` batch size to the system limit (or safe high value like 3000) to minimize `apt` invocations to 1 whenever possible.
## 2024-05-24 - Implicit Apt Updates
**Learning:** `add-apt-repository` runs `apt update` automatically by default, which can cause redundant network operations even if you manually run `apt update` later. Using the `-n` flag prevents this implicit update.
**Action:** Always use `-n` with `add-apt-repository` when you plan to run a consolidated `apt update` afterwards. Also, modern Linux systems support very large command lines (2MB+), so `xargs` batch sizes can be significantly increased (e.g., 3000) to minimize package manager invocation overhead.
## 2026-02-23 - Suppressing Implicit Apt Updates
**Learning:** `add-apt-repository` implicitly runs `apt update` unless the `-n` flag is used. In scripts that add multiple repositories and then run a consolidated `apt update`, this implicit behavior causes redundant network operations and slows down execution.
**Action:** Always use `add-apt-repository -n` when adding repositories in a script that includes a subsequent explicit `apt update`. Also, consolidating small package installs into larger lists (like `ESSENTIALS`) reduces the overhead of multiple `apt install` invocations.
