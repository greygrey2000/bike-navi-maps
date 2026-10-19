#!/usr/bin/env bash
# Standalone publisher. Runs on GitHub Actions; never needs the Android source.
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-greygrey2000/bike-navi-maps}"
BBOX='9.90,51.95,11.40,52.75'
BUILD_DAY=''
for offset in 0 1 2 3 4 5 6; do
  day=$(date -u -d "-$offset day" +%Y%m%d)
  if curl --connect-timeout 15 --max-time 30 -fsI "https://build.protomaps.com/$day.pmtiles" >/dev/null; then
    BUILD_DAY="$day"
    break
  fi
done
test -n "$BUILD_DAY" || { echo 'Kein aktueller Protomaps-Build erreichbar.' >&2; exit 1; }
TAG="map-$BUILD_DAY"
mkdir -p output

# Published releases are immutable from the app's perspective. A rerun uses
# the existing file; a failed draft can be completed safely.
if gh release view "$TAG" --repo "$REPO" --json isDraft --jq '.isDraft' >output/is-draft 2>/dev/null &&
    test "$(cat output/is-draft)" = false; then
  gh release download "$TAG" --repo "$REPO" --pattern map.json --dir output --clobber
else
  curl -fL --retry 3 --connect-timeout 15 \
    https://github.com/protomaps/go-pmtiles/releases/download/v1.31.2/go-pmtiles_1.31.2_Linux_x86_64.tar.gz \
    -o output/pmtiles.tar.gz
  echo '3ed7dbf4ec2e6dfe5e25b6f70d1ffc932729f93c86db353bf514dd71010a312f  output/pmtiles.tar.gz' | sha256sum -c -
  tar -xzf output/pmtiles.tar.gz -C output pmtiles
  FILE="region-wob-bs-$BUILD_DAY.pmtiles"
  output/pmtiles extract "https://build.protomaps.com/$BUILD_DAY.pmtiles" "output/$FILE" \
    --bbox="$BBOX" --maxzoom=15 --download-threads=8
  output/pmtiles verify "output/$FILE"
  python3 - "$REPO" "$BUILD_DAY" "$FILE" <<'PY'
import hashlib, json, pathlib, sys
repo, day, name = sys.argv[1:]
path = pathlib.Path('output') / name
manifest = {
    'schema': 1, 'region': 'wob-bs', 'build': day,
    'file': name, 'bytes': path.stat().st_size,
    'sha256': hashlib.file_digest(path.open('rb'), 'sha256').hexdigest(),
    'url': f'https://github.com/{repo}/releases/download/map-{day}/{name}',
    'bbox': [9.90, 51.95, 11.40, 52.75], 'maxzoom': 15,
    'source': f'https://build.protomaps.com/{day}.pmtiles',
    'attribution': '© OpenStreetMap contributors (ODbL), Protomaps',
}
pathlib.Path('output/map.json').write_text(json.dumps(manifest, indent=2) + '\n')
PY
  if ! gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
    gh release create "$TAG" --repo "$REPO" --draft --target main \
      --title "Braunschweig / Wolfsburg · $BUILD_DAY" \
      --notes 'Region 9.90–11.40° E / 51.95–52.75° N, Zoom 0–15. Kartendaten © OpenStreetMap contributors (ODbL), Basemap Protomaps. Automatisch aus dem datierten Protomaps-Build ausgeschnitten.'
  fi
  gh release upload "$TAG" "output/$FILE" output/map.json --repo "$REPO" --clobber
  gh release edit "$TAG" --repo "$REPO" --draft=false --latest
fi
cp output/map.json latest.json
