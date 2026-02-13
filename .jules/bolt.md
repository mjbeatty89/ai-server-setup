## 2024-05-22 - [APT Batch Installation]
**Learning:** `xargs -n 50` for `apt install` creates significant overhead due to repeated dependency resolution and lock acquisition. Modern Linux systems handle large argument lists well.
**Action:** Use `-n 500` or higher for bulk package installations to minimize `apt` invocation overhead.
