#!/bin/bash
# Converte tutti i file .slim in app/views/ a .erb usando slimrb
# Usage: docker compose run --rm airesis bash bin/slim_to_erb.sh

set -e

COUNT=0
ERRORS=0

find app/views -name '*.slim' | sort | while read slim_file; do
  # Determina il nome del file ERB
  erb_file="${slim_file%.slim}"

  # Se è .html.slim → .html.erb
  if [[ "$slim_file" == *.html.slim ]]; then
    erb_file="${slim_file%.html.slim}.html.erb"
  # Se è .js.slim → .js.erb
  elif [[ "$slim_file" == *.js.slim ]]; then
    erb_file="${slim_file%.js.slim}.js.erb"
  # Se è .pdf.slim → .pdf.erb
  elif [[ "$slim_file" == *.pdf.slim ]]; then
    erb_file="${slim_file%.pdf.slim}.pdf.erb"
  # Se è solo .slim (partial senza formato) → .erb
  else
    erb_file="${slim_file%.slim}.erb"
  fi

  # Salta se il file ERB esiste già
  if [ -f "$erb_file" ]; then
    echo "SKIP (erb exists): $slim_file"
    continue
  fi

  # Converti
  if slimrb -e "$slim_file" > "$erb_file" 2>/dev/null; then
    rm "$slim_file"
    echo "OK: $slim_file → $erb_file"
    COUNT=$((COUNT + 1))
  else
    echo "ERR: $slim_file (keeping slim)"
    rm -f "$erb_file"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""
echo "Done. Converted: $COUNT, Errors: $ERRORS"
