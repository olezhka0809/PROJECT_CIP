#!/bin/bash

echo "=========================================="
echo "Generate Work Units for Pi Test"
echo "=========================================="

PROJECT_DIR=~/projects/pi_test
cd $PROJECT_DIR

# Verifică dacă există scriptul de generare
if [ -f bin/create_work ]; then
    echo "✓ Found create_work script"
    
    # Generează 30 de work units noi
    echo "Generating 30 new work units..."
    
    for i in {1..30}; do
        # Număr random de iterații pentru Monte Carlo (între 1M și 10M)
        iterations=$((1000000 + RANDOM % 9000000))
        
        echo "Creating WU #$i with $iterations iterations"
        
        # Creează fișier input
        echo "$iterations" > /tmp/pi_input_$i.txt
        
        # Apelează create_work (sintaxa depinde de tutorial)
        # Trebuie adaptat conform tutorialului tău
        bin/create_work \
            --appname pi_monte_carlo \
            --wu_name "pi_wu_${i}_$(date +%s)" \
            --wu_template templates/pi_wu_template.xml \
            --result_template templates/pi_result_template.xml \
            /tmp/pi_input_$i.txt
    done
    
    echo "✓ Work units created!"
else
    echo "✗ create_work not found. Checking tutorial structure..."
    
    # Verifică structura din tutorial
    if [ -d ~/work/boinc_tutorial/examples ]; then
        echo "Looking in tutorial examples..."
        ls -la ~/work/boinc_tutorial/examples/
    fi
fi

echo ""
echo "Current work units in download:"
ls ~/projects/pi_test/download/ | wc -l

echo "=========================================="
