# data/

Downloaded files land in `data/raw/<dataset>/` and are git-ignored. Re-create them with:

```bash
python ingest/run_all.py --sample     # 20,000 rows per file
python ingest/run_all.py              # full files
```

Each dataset folder gets a `_manifest.json` with the source URL, row count, bytes and sha256.
