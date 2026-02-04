#!/bin/bash

echo "=========================================="
echo "Create BOINC Work Units - WITH STAGING"
echo "=========================================="

PROJECT_DIR=~/projects/pi_test
cd $PROJECT_DIR

if [ ! -f "config.xml" ]; then
    echo "ERROR: Not in project directory!"
    exit 1
fi

echo "✓ Working in: $PROJECT_DIR"
echo ""

# Găsește un exemplu de WU existent pentru a înțelege structura
echo "Analyzing existing work unit structure..."
existing_file=$(find download -name "*.txt" -type f | head -1)
if [ ! -z "$existing_file" ]; then
    echo "  Found example: $existing_file"
    cat "$existing_file"
fi
echo ""

success_count=0
fail_count=0

echo "Creating work units..."
echo ""

for i in {1..5}; do
    iterations=$((5000000 + i * 2000000))
    
    # Creează fișier temporar
    temp_file="/tmp/wu_${i}_$(date +%s).txt"
    echo "$iterations" > $temp_file
    
    echo "WU #$i: $iterations iterations"
    echo "  Temp file: $temp_file"
    
    # Metodă 1: Cu --stdin (fișierul vine de la stdin)
    bin/create_work \
        --appname pi_compute \
        --wu_name "pi_new_${i}_$(date +%s)" \
        --wu_template templates/pi_in.xml \
        --result_template templates/pi_out.xml \
        --target_nresults 3 \
        --stdin < $temp_file \
        > /tmp/create_work_${i}.log 2>&1
    
    result1=$?
    
    if [ $result1 -eq 0 ]; then
        echo "  ✓ Success with --stdin"
        ((success_count++))
        rm -f $temp_file
        continue
    fi
    
    # Metodă 2: Copiere manuală în download
    echo "  Trying manual copy method..."
    
    # Creează fișier în download direct
    download_file="download/wu_${i}.txt"
    cp $temp_file $download_file
    chmod 666 $download_file
    
    bin/create_work \
        --appname pi_compute \
        --wu_name "pi_copy_${i}_$(date +%s)" \
        --wu_template templates/pi_in.xml \
        --result_template templates/pi_out.xml \
        --target_nresults 3 \
        wu_${i}.txt \
        > /tmp/create_work_copy_${i}.log 2>&1
    
    result2=$?
    
    if [ $result2 -eq 0 ]; then
        echo "  ✓ Success with copy"
        ((success_count++))
        rm -f $temp_file
        # Nu șterge din download - e nevoie acolo
    else
        echo "  ✗ Both methods failed"
        ((fail_count++))
        echo "  --- Method 1 log ---"
        head -3 /tmp/create_work_${i}.log
        echo "  --- Method 2 log ---"
        head -3 /tmp/create_work_copy_${i}.log
        rm -f $temp_file $download_file
    fi
    
    echo ""
done

echo "=========================================="
echo "Summary:"
echo "  ✓ Success: $success_count"
echo "  ✗ Failed: $fail_count"
echo ""

if [ $success_count -gt 0 ]; then
    echo "Checking database..."
    mysql -u root -p -e "USE pi_test; SELECT COUNT(*) as 'Total WUs' FROM workunit; SELECT name FROM workunit ORDER BY id DESC LIMIT 5;" 2>/dev/null
    
    echo ""
    echo "Download directory now has: $(ls download/ | wc -l) items"
    
    echo ""
    echo "=========================================="
    echo "✓ Work units created successfully!"
    echo ""
    echo "Monitor clients:"
    echo "  tail -f ~/boinc_clients/client_b/boinc_startup.log"
    echo "  watch -n 5 'ls -l ~/boinc_clients/client_*/slots/'"
else
    echo "=========================================="
    echo "✗ No work units created"
    echo ""
    echo "Let's try the tutorial's method..."
    if [ -f ~/work/boinc_tutorial/scripts/setup_server.sh ]; then
        echo "Check: ~/work/boinc_tutorial/scripts/setup_server.sh"
        echo "Run: cd ~/work/boinc_tutorial && grep -A 30 'create_work' scripts/setup_server.sh"
    fi
fi

echo "=========================================="
