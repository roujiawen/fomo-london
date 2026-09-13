#!/usr/bin/env bash
#
# Daily pipeline run for Fomo London (invoked by cron; see deploy/setup_vm.sh).
#
# Crawls → extracts → processes → merges → exports JSON to src/data/, then
# rebuilds dist/ so nginx serves the fresh data. The pipeline's own Step 8
# (FTP upload) fails because we deploy locally — that is expected and harmless;
# the export in Step 7 has already written src/data/ by then, so we ignore it
# and republish via the build.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

export FOMO_CITY="${FOMO_CITY:-london}"
export FOMO_ENV="${FOMO_ENV:-local}"

echo "===== $(date -Is) pipeline start ====="

# Run the pipeline. Upload (Step 8) will fail with no FTP config — tolerate it;
# the JSON export (Step 7) runs first and is what we publish.
"$REPO_DIR/.venv/bin/python" pipeline/main.py || echo "(pipeline exited non-zero — expected if only the FTP upload failed)"

# Republish src/data (+ any shell changes) into dist/ for nginx.
FOMO_CITY="$FOMO_CITY" npm run build

echo "===== $(date -Is) pipeline done ====="
