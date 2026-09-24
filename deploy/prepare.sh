#!/usr/bin/env bash
# Copies the exported builds into deploy/ so `docker compose up` can use them.
#   ./deploy/prepare.sh                 # from local exports in build/
#   ./deploy/prepare.sh path/to/artifacts   # from downloaded CI artifacts
#                                           # (folders web-build/ and linux-server/)
set -euo pipefail
cd "$(dirname "$0")"
source_dir="${1:-../build}"
mkdir -p server web
if [ -d "$source_dir/web-build" ]; then
  cp -r "$source_dir/web-build/." web/
  cp "$source_dir/linux-server/forest-server.x86_64" server/
else
  cp -r "$source_dir/web/." web/
  cp "$source_dir/server/forest-server.x86_64" server/
fi
chmod +x server/forest-server.x86_64
echo "Ready: deploy/web ($(ls web | wc -l) files) and deploy/server/forest-server.x86_64"
