#!/bin/bash
# Installa la mappa ad alta risoluzione nell'asset catalog (copia binaria PNG).
# Uso: ./install-mappa.sh /percorso/alla/mappa2540x1440.png

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 /percorso/alla/mappa.png"
  exit 1
fi

SRC="$1"
DIR="$(cd "$(dirname "$0")" && pwd)"
DST="$DIR/mappa.png"

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
