#!/bin/bash

clear
echo "=========================================="
echo "  DEMONSTRAȚIE PROIECT BOINC"
echo "=========================================="
echo ""
read -p "Apasă ENTER pentru a începe demonstrația..."

# ==========================================
# CERINȚA 1: Pi Calculation cu 3 Clienți
# ==========================================
clear
echo "=========================================="
echo "CERINȚA 1: Calculul lui Pi cu 3 Clienți"
echo "=========================================="
echo ""
echo "Arhitectura:"
echo "  - Server BOINC (Apache + MySQL) pe localhost"
echo "  - 3 clienți independenți"
echo "  - Work units distribuite prin Apache"
echo "  - Rezultate trimise în upload/"
echo ""
read -p "Apasă ENTER pentru a vedea status-ul clienților..."

echo ""
echo "=== CLIENT A ==="
boinccmd --host localhost:31416 --passwd boinc123 --get_state | grep -A 5 "Projects"

echo ""
echo "=== CLIENT B ==="
boinccmd --host localhost:31417 --passwd boinc123 --get_state | grep -A 5 "Projects"

echo ""
echo "=== CLIENT C ==="
boinccmd --host localhost:31418 --passwd boinc123 --get_state | grep -A 5 "Projects"

echo ""
read -p "Apasă ENTER pentru a vedea rezultatele diferite ale clienților..."

echo ""
echo "=== Rezultate Pi din Upload Directory ==="
echo "Ultimele 10 rezultate trimise de clienți:"
ls -lht ~/projects/pi_test/upload/ | head -11

echo ""
echo "Conținut exemple de rezultate (diferite valori Pi):"
for file in $(ls ~/projects/pi_test/upload/*_0 2>/dev/null | head -3); do
    echo ""
    echo "--- $file ---"
    cat "$file" | head -3
done

echo ""
read -p "Apasă ENTER pentru a vedea interfața web..."

echo ""
echo "Interface Web BOINC accesibilă la:"
echo "  http://127.0.0.1/pi_test/"
echo ""
echo "Poți arăta profesorului în browser:"
echo "  - Status server"
echo "  - Work units distribuite"
echo "  - Rezultate primite"
echo ""

read -p "Apasă ENTER pentru cerința următoare..."

# ==========================================
# CERINȚA 2: Euler Constant
# ==========================================
clear
echo "=========================================="
echo "CERINȚA 2: Calculul constantei Euler (e)"
echo "=========================================="
echo ""
echo "Similar cu Pi, dar calculează e = 2.71828..."
echo ""

cd ~/projects/euler_e
echo "Creăm work units pentru Euler:"
./create_work_euler.sh

echo ""
echo "Work units create și gata pentru distribuție!"
echo ""
ls -lh ~/projects/euler_e/download/ | head -10

read -p "Apasă ENTER pentru cerința următoare..."

# ==========================================
# CERINȚA 3: Ax=b Solver
# ==========================================
clear
echo "=========================================="
echo "CERINȚA 3: Rezolvarea Ax=b"
echo "Metoda: Ulam-von Neumann (Monte Carlo)"
echo "=========================================="
echo ""

cd ~/projects/axb_solver/apps/axb_compute/1.0

echo "Generăm o problemă Ax=b nouă..."
./generate_axb_input demo_problem.txt
echo ""
echo "Matricea A și vectorul b generat:"
cat demo_problem.txt
echo ""

read -p "Apasă ENTER pentru a rezolva sistemul..."

echo ""
echo "Rezolvare cu metoda Monte Carlo paralelizabilă:"
./axb_solver demo_problem.txt demo_solution.txt

echo ""
echo "Soluția găsită:"
cat demo_solution.txt

read -p "Apasă ENTER pentru cerința următoare..."

# ==========================================
# CERINȚA 4: Problemă la Alegere
# ==========================================
clear
echo "=========================================="
echo "CERINȚA 4: Monte Carlo Integration"
echo "=========================================="
echo ""
echo "Calculăm integrala funcției f(x) = x²·sin(x) + 1"
echo "pe intervalul [0, π]"
echo ""

cd ~/projects/monte_carlo_integral/apps/integral_compute/1.0

read -p "Apasă ENTER pentru a calcula integrala..."

./integral_monte_carlo 0 3.14159 5000000 demo_integral.txt

echo ""
cat demo_integral.txt

read -p "Apasă ENTER pentru ultima cerință (cea mai importantă)..."

# ==========================================
# CERINȚA 5: Temperature + SEAL
# ==========================================
clear
echo "=========================================="
echo "CERINȚA 5: Monitorizare Temperatură"
echo "          + Criptare Omorfă (SEAL)"
echo "=========================================="
echo ""
echo "Demonstrație criptare omorfă:"
echo "  1. Fiecare client citește temperatura CPU"
echo "  2. Criptează temperatura cu Microsoft SEAL"
echo "  3. Serverul calculează MEDIA pe date criptate"
echo "  4. Verifică dacă depășește pragul (60°C)"
echo "  5. FĂRĂ să decripteze temperaturile individuale!"
echo ""

read -p "Apasă ENTER pentru a rula 3 clienți..."

cd ~/projects/apps/pi_compute/1.0_with_seal

# Curăță teste anterioare
rm -f seal_parms.bin public_key.bin secret_key.bin demo_*.txt*

echo ""
echo "=== Client 1 ==="
./pi_compute_seal 1000000 demo_client1.txt

echo ""
echo "=== Client 2 ==="
./pi_compute_seal 2000000 demo_client2.txt

echo ""
echo "=== Client 3 ==="
./pi_compute_seal 3000000 demo_client3.txt

read -p "Apasă ENTER pentru a vedea analiza SERVER-SIDE..."

echo ""
echo "=== SERVERUL verifică temperaturile (CRIPTATE) ==="
cd ~/projects
./check_encrypted_temps apps/pi_compute/1.0_with_seal/demo_client*.txt

echo ""
echo ""
