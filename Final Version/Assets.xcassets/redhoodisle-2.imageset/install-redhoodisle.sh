#!/bin/bash
# Installa la sotto-mappa Cappuccetto Rosso (copia binaria PNG).
# Uso: ./install-redhoodisle.sh /percorso/a/redhoodislefinal.png

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 /percorso/a/redhoodislefinal.png"
  exit 1
fi

SRC="$1"
DIR="$(cd "$(dirname "$0")" && pwd)"
DST="$DIR/redhoodislefinal.png"
CONTENTS="$DIR/Contents.json"

if [[ ! -f "$SRC" ]]; then
  echo "File non trovato: $SRC"
  exit 1
fi

MAGIC=$(xxd -l 4 -p "$SRC")
if [[ "$MAGIC" != "89504e47" ]]; then
  echo "Errore: il file non è un PNG valido (header $MAGIC)."
  exit 1
fi

cp "$SRC" "$DST"
W=$(sips -g pixelWidth "$DST" 2>/dev/null | awk '/pixelWidth/ {print $2}')
H=$(sips -g pixelHeight "$DST" 2>/dev/null | awk '/pixelHeight/ {print $2}')
echo "Installato: $DST (${W}x${H}, copia binaria)"
echo "Aggiorna MapLayout.redHoodMapAspectRatio a ${W}.0 / ${H}.0 se diverso."

cat > "$CONTENTS" <<EOF
{
  "images" : [
    {
      "filename" : "redhoodislefinal.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "Contents.json aggiornato."
