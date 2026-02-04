#!/bin/bash
# Script complet end-to-end pentru pi_compute_seal și check_encrypted_temps
# Tot output-ul va fi salvat în run_log.txt

CLIENT_DIR=~/projects/apps/pi_compute/1.0_with_seal
SERVER_DIR=~/projects
LOG_FILE=run_log.txt

echo "=== Ștergerea rezultatelor vechi ===" | tee "$LOG_FILE"

# Lista fișierelor de șters
FILES_TO_REMOVE=(
    "$CLIENT_DIR"/result*.txt
    "$CLIENT_DIR"/seal_parms.bin
    "$CLIENT_DIR"/public_key.bin
    "$CLIENT_DIR"/secret_key.bin
)

for f in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$f" ]; then
        rm -v "$f" | tee -a "$LOG_FILE"
    fi
done

echo "✅ Curățenie terminată" | tee -a "$LOG_FILE"

# --- Rulăm pi_compute_seal ---
echo -e "\n=== Rulăm pi_compute_seal ===" | tee -a "$LOG_FILE"
cd "$CLIENT_DIR" || exit 1

./pi_compute_seal 1000000 result1.txt | tee -a "$LOG_FILE"
./pi_compute_seal 2000000 result2.txt | tee -a "$LOG_FILE"
./pi_compute_seal 3000000 result3.txt | tee -a "$LOG_FILE"

# --- Verificăm temperaturile criptate ---
echo -e "\n=== Verificăm temperaturile criptate ===" | tee -a "$LOG_FILE"
cd "$SERVER_DIR" || exit 1
# Rulăm check_encrypted_temps din directorul clientului
./check_encrypted_temps "$CLIENT_DIR"/result*.txt | tee -a "$LOG_FILE"

echo -e "\n Script finalizat! Tot output-ul este în $LOG_FILE"
