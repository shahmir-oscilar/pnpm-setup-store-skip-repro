# pnpm/setup store-skip repro

pnpm/setup v3.1.0+ skips saving the store cache when the restored store is unchanged. This repo checks that skip in two kinds of job, using pnpm/setup v3.1.1 and pnpm 12.4.1.

| Job | Container | Store (`pnpm store path`) |
|---|---|---|
| `runner-seed`, `runner-check` | none | `~/setup-pnpm/store/v11`, inside pnpm/setup's install directory |
| `container-seed`, `container-check` | `node:24-bookworm` | `/__w/.pnpm-store/v11` |

Each seed job saves the store. The check job after it restores that store (an exact lockfile match), changes nothing, and should log this in the post step of "Run pnpm/setup":

```
The store has not changed since it was restored, not saving cache.
```

The check jobs also run `scripts/fingerprint.sh` after setup, after `pnpm -v`, and after `pnpm run`. It records the same entries pnpm/setup fingerprints (size and mtime of `index.db`, `index.db-wal` and each `files/xx` directory) and prints any that changed since the previous step.
