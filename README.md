# pnpm/setup store-skip repro

pnpm/setup v3.1.0+ skips saving the store cache when the restored store is unchanged. This repo checks that skip in two kinds of job, using pnpm/setup v3.1.1 and pnpm 12.4.1.

| Job | Container | Store (`pnpm store path`) |
|---|---|---|
| `runner-seed`, `runner-check` | none | `~/setup-pnpm/store/v11`, inside pnpm/setup's install directory |
| `container-seed`, `container-check` | `node:24-bookworm` | `/__w/.pnpm-store/v11` |
| `runner-split-check` | none | `~/setup-pnpm/store/v11` |

Each seed job saves the store. The check job after it restores that store (an exact lockfile match), changes nothing, and should log this in the post step of "Run pnpm/setup":

```
The store has not changed since it was restored, not saving cache.
```

`runner-split-check` restores the runner store saved earlier in the run, with `install: false`, and runs `pnpm install --frozen-lockfile` as its own step, so the fingerprints before and after it show whether the install changes the store.

The check jobs also run `scripts/fingerprint.sh` after setup, after `pnpm -v`, and after `pnpm run`. It records the same entries pnpm/setup fingerprints (size and mtime of `index.db`, `index.db-wal` and each `files/xx` directory) and prints any that changed since the previous step.

## Results

From run [38620545293](https://github.com/shahmir-oscilar/pnpm-setup-store-skip-repro/actions/runs/38620545293):

| Job | Runtime install | Post step |
|---|---|---|
| `runner-check` | `reused 1` from the restored store | `Cache saved with the key: …` |
| `container-check` | `downloaded 1` into `/github/home/setup-pnpm/store/v11` | `The store has not changed since it was restored, not saving cache.` |
| `runner-split-check` | `reused 1` from the restored store | `Cache saved with the key: …` |

In `runner-split-check`, the install changes one fingerprinted entry and nothing else:

```
after setup:   index.db-wal 0 bytes
pnpm install:  Already up to date
after install: index.db-wal none
```

Without a container, the project store is the same store the runtime install uses. It has an empty `index.db-wal` when pnpm/setup fingerprints it after the restore. The project install opens and closes the database, SQLite deletes the empty log, and the post step's fingerprint no longer matches. In the container job the runtime goes into a different store, so the project store's `index.db-wal` doesn't change and the skip works.

Not yet confirmed: whether the empty `index.db-wal` comes from the runtime install or from the restored archive.
