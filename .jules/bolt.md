## 2025-02-12 - Shell Script Optimization
**Learning:** Shell scripts installing many packages can be bottlenecked by repeated 'apt update' calls and small 'xargs' batch sizes. Consolidating repository additions and increasing batch sizes (e.g., from 50 to 500) significantly reduces overhead.
**Action:** Look for repeated package manager invocations and batch them wherever possible. Check xargs constraints but prefer larger batches for package managers.
## 2024-05-18 - Optimized Apt Installation
**Learning:** `apt update` is a network-heavy operation. Running it multiple times for each repository addition (1Password, Docker, PPA) significantly slows down the setup script. Grouping repository additions and running a single update is a major performance win.
**Action:** When adding multiple repositories, consolidate them into a single block and run `apt update` only once afterwards. Also, use `xargs` with a larger batch size (e.g., 500) for bulk package installations to reduce `apt` invocation overhead.

## 2024-05-24 - Implicit Apt Updates
**Learning:** `add-apt-repository` runs `apt update` automatically by default, which can cause redundant network operations even if you manually run `apt update` later. Using the `-n` flag prevents this implicit update.
**Action:** Always use `-n` with `add-apt-repository` when you plan to run a consolidated `apt update` afterwards. Also, modern Linux systems support very large command lines (2MB+), so `xargs` batch sizes can be significantly increased (e.g., 3000) to minimize package manager invocation overhead.
## 2026-02-23 - Suppressing Implicit Apt Updates
**Learning:** `add-apt-repository` implicitly runs `apt update` unless the `-n` flag is used. In scripts that add multiple repositories and then run a consolidated `apt update`, this implicit behavior causes redundant network operations and slows down execution.
**Action:** Always use `add-apt-repository -n` when adding repositories in a script that includes a subsequent explicit `apt update`. Also, consolidating small package installs into larger lists (like `ESSENTIALS`) reduces the overhead of multiple `apt install` invocations.
## 2024-04-17 - Removed redundant `apt update` and duplicate `xargs` batch installs
**Learning:** Repositories can have `apt update` implicitly happen during `add-apt-repository` unless passed the `-n` flag. Duplicated code to execute `apt update` introduces massive network latency overhead when grouped updates can execute efficiently. Furthermore, running `xargs` without `-r` and duplicating it completely redundantly doubles execution time unnecessarily, and not filtering packages present in an already-installed `ESSENTIALS` list re-installed core packages.
**Action:** When creating setup or configuration scripts, always execute package list updates as few times as possible, ensure conditional repository adds use the `-n` flag to skip internal updates, use `-r` with `xargs` to avoid running on empty input, optimize the batch size limit, and use `grep -vFxf` with a temporary file to cleanly exclude pre-installed packages from bulk processing steps.
## 2024-04-17 - Avoid Temporary Files with Process Substitution
**Learning:** Hardcoded temporary files (e.g. `/tmp/essentials.txt`) in bash scripts can lead to concurrency and permission issues when run by multiple users or scripts.
**Action:** When creating setup or configuration scripts, always use process substitution (e.g., `<(echo "$ESSENTIALS" | tr ' ' '\n')`) when piping output into commands that expect a file, rather than managing a temporary file. This improves script performance, avoids leftover artifacts, and solves permission collision bugs.
