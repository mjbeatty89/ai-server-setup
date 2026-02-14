## 2024-05-23 - [Consolidating APT Operations]
**Learning:** Separate `apt-add-repository` calls followed by `apt update` for each repository adds significant overhead (network + processing time). Grouping all repository additions before a single `apt update` reduces execution time drastically.
**Action:** Always structure setup scripts to: 1. Install prerequisites (curl, gpg). 2. Add all keys and repos. 3. Run `apt update` ONCE. 4. Run `apt install` in a single transaction where possible.

## 2024-05-23 - [Xargs Batch Size Optimization]
**Learning:** Default `xargs` behavior or small batch sizes (e.g., `-n 50`) incurs high overhead for package managers like `apt` which have heavy startup costs (locking, reading DB).
**Action:** Use larger batch sizes (e.g., `-n 500` or `-n 1000`) for bulk package operations, as command-line limits on modern Linux are generous (megabytes), far exceeding the length of package lists.
