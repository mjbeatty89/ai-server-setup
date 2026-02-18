## 2024-05-18 - Optimized Apt Installation
**Learning:** `apt update` is a network-heavy operation. Running it multiple times for each repository addition (1Password, Docker, PPA) significantly slows down the setup script. Grouping repository additions and running a single update is a major performance win.
**Action:** When adding multiple repositories, consolidate them into a single block and run `apt update` only once afterwards. Also, use `xargs` with a larger batch size (e.g., 500) for bulk package installations to reduce `apt` invocation overhead.

## 2024-05-24 - Parallel Repository Setup & Optimized Batch Size
**Learning:** Even when grouped, sequential repository setup (downloading keys, adding sources) is I/O bound. Parallelizing these operations using background subshells `(...) &` can save significant time. Additionally, `add-apt-repository` runs `apt update` by default, which is redundant if a consolidated update follows. Using `-n` prevents this. Finally, `xargs` batch size can be safely increased to ~3000 to minimize `apt` invocations to a single call for most package lists.
**Action:** Always check for implicit updates in repository management tools and suppress them if manual update follows. Utilize parallel execution for independent network/IO tasks in shell scripts. Maximize batch sizes within ARG_MAX limits.
