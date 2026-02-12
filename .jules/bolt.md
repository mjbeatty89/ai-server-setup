## 2025-02-12 - Shell Script Optimization
**Learning:** Shell scripts installing many packages can be bottlenecked by repeated 'apt update' calls and small 'xargs' batch sizes. Consolidating repository additions and increasing batch sizes (e.g., from 50 to 500) significantly reduces overhead.
**Action:** Look for repeated package manager invocations and batch them wherever possible. Check xargs constraints but prefer larger batches for package managers.
