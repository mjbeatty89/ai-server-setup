## 2024-05-18 - Optimized Apt Installation
**Learning:** `apt update` is a network-heavy operation. Running it multiple times for each repository addition (1Password, Docker, PPA) significantly slows down the setup script. Grouping repository additions and running a single update is a major performance win.
**Action:** When adding multiple repositories, consolidate them into a single block and run `apt update` only once afterwards. Also, use `xargs` with a larger batch size (e.g., 500) for bulk package installations to reduce `apt` invocation overhead.

## 2024-05-20 - Further Apt Optimization
**Learning:** `add-apt-repository` runs `apt update` by default, creating hidden redundancy even when we manually update later. Also, `apt install` has significant startup overhead; batching 500 packages still results in multiple heavy invocations for large lists (1200+ packages).
**Action:** Always use `add-apt-repository -n` when followed by an explicit update. Increase `xargs` batch size to the system limit (or safe high value like 3000) to minimize `apt` invocations to 1 whenever possible.
