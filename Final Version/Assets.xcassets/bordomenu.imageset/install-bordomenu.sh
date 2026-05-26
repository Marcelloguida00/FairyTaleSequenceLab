#!/bin/bash
# Installa bordomenu come PNG (alpha) o SVG (vector) nell'asset catalog.
# Uso: ./install-bordomenu.sh /percorso/al/tuo-bordomenu.png|.svg

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 /percorso/al/bordomenu.png|.svg"
  exit 1
fi

SRC="$1"
DIR="$(cd "$(dirname "$0")" && pwd)"
CONTENTS="$DIR/Contents.json"

if [[ ! -f "$SRC" ]]; then
  echo "File non trovato: $SRC"
  exit 1
fi

MAGIC=$(xxd -l 4 -p "$SRC")

if [[ "$MAGIC" == "89504e47" ]]; then
  cp "$SRC" "$DIR/bordomenu.png"
  rm -f "$DIR/bordomenu.svg"
  cat > "$CONTENTS" <<'EOF'
{
  "images" : [
    {
      "filename" : "bordomenu.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
  echo "Installato: bordomenu.png (PNG con alpha, copia binaria)"
elif grep -q '<svg' "$SRC" 2>/dev/null || [[ "$MAGIC" == "3c737667" || "$MAGIC" == "3c3f786d" ]]; then
  cp "$SRC" "$DIR/bordomenu.svg"
  rm -f "$DIR/bordomenu.png"
  cat > "$CONTENTS" <<'EOF'
{
  "images" : [
    {
      "filename" : "bordomenu.svg",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : true
  }
}
EOF
  echo "Installato: bordomenu.svg (vector, Preserve Vector Data attivo)"
else
  echo "Errore: formato non supportato (header $MAGIC)."
  echo "Esporta da Figma come PNG con trasparenza o SVG."
  exit 1
fi
