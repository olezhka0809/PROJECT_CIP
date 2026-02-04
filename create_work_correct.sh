#!/bin/bash

echo "=========================================="
echo "Create BOINC Work Units - CORRECT Method"
echo "=========================================="

PROJECT_DIR=~/projects/pi_test
cd $PROJECT_DIR

if [ ! -f "config.xml" ]; then
    echo "ERROR: Not in project directory!"
    exit 1
fi

echo "✓ Working in: $PROJECT_DIR"
echo ""

# Cleanup old test files
rm -f wu_*.txt 2>/dev/null

echo "Creating work units..."
echo ""

success_count=0
fail_count=0

for i in {1..10}; do
    # Variere iterații pentru diversitate
    iterations=$((5000000 + i * 1000000))
    
    # Creează fișier în ROOT project (nu în download/)
    input_file="wu_input_${i}.txt"
    echo "$iterations" > $input_file
    
    # Verifică că fișierul există
    if [ ! -f "$input_file" ]; then
        echo "ERROR: Failed to create $input_file"
        continue
    fi
    
    echo "Creating WU #$i ($iterations iterations)..."
    
    # Creează work unit
    bin/create_work \
        --appname pi_compute \
        --wu_name "pi_manual_${i}_$(date +%s)" \
        --wu_template templates/pi_in.xml \
        --result_template templates/pi_out.xml \
        --target_nresults 3 \
        $input_file \
        > /tmp/create_work_${i}.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Success"
        ((success_count++))
        # Șterge fișierul după creare reușită
        rm -f $input_file
    else
        echo "  ✗ Failed"
        ((fail_count++))
        echo "  Log: /tmp/create_work_${i}.log"
        cat /tmp/create_work_${i}.log | head -5
    fi
    echo ""
done

echo "=========================================="
echo "Summary:"
echo "  ✓ Success: $success_count"
echo "  ✗ Failed: $fail_count"
echo ""

# Verifică rezultatele
echo "Database Status:"
mysql -u root -p << 'EOF'
USE pi_test;
SELECT 'Total WUs' as Metric, COUNT(*) as Count FROM workunit
UNION ALL
SELECT 'Total Results', COUNT(*) FROM result
UNION ALL  
SELECT 'Results IN_PROGRESS (state=2)', COUNT(*) FROM result WHERE server_state=2
UNION ALL
SELECT 'Results OVER (state=4)', COUNT(*) FROM result WHERE server_state=4
UNION ALL
SELECT 'Results UPLOADED (state=5)', COUNT(*) FROM result WHERE server_state=5;
EOF

echo ""
echo "File System:"
echo "  Download: $(ls download/ | wc -l) files"
echo "  Upload: $(ls upload/ | wc -l) files"

echo ""
echo "=========================================="
echo "Monitor clients with:"
echo "  tail -f ~/boinc_clients/client_a/boinc_startup.log"
echo "  ls ~/boinc_clients/client_a/slots/"
echo "=========================================="
