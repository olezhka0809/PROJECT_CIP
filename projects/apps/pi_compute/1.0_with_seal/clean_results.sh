#!/bin/bash
# Script pentru ștergerea fișierelor generate de pi_compute_seal

# Lista fișierelor care vor fi șterse
FILES=(
    result*.txt
    seal_parms.bin
    public_key.bin
    secret_key.bin
)

echo "Șterg fișierele vechi..."

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -v "$file"
    fi
done

echo " Curățenie terminată!"
