#!/bin/bash

echo "=========================================="
echo "Create Work Units - Fixed Version"
echo "=========================================="

PROJECT_DIR=~/projects/pi_test
cd $PROJECT_DIR

# Verifică că suntem în directorul corect
if [ ! -f "config.xml" ]; then
    echo "ERROR: Not in project directory!"
    exit 1
fi

echo "✓ In project directory: $PROJECT_DIR"
echo ""

# Creează directorul pentru input files în DOWNLOAD
mkdir -p download/input_files
chmod 777 download/input_files

echo "Creating work units..."
echo ""

for i in {1..5}; do
    iterations=$((5000000 + i * 2000000))
    
    # Creează fișierul de input în directorul download
    input_file="download/input_files/pi_input_$i.txt"
    echo "$iterations" > $input_file
    chmod 666 $input_file
    
    echo "WU #$i: $iterations iterations"
    echo "  Input file: $input_file"
    
    # Rulează create_work cu calea relativă
    bin/create_work \
        --appname pi_compute \
        --wu_name "pi_manual_${i}_$(date +%s)" \
        --wu_template templates/pi_in.xml \
        --result_template templates/pi_out.xml \
        --target_nresults 3 \
        $input_file
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Created successfully"
    else
        echo "  ✗ Failed"
        echo "  Trying with absolute path..."
        
        # Încearcă cu cale absolută
        abs_input="/home/helgidev08/projects/pi_test/$input_file"
        bin/create_work \
            --appname pi_compute \
            --wu_name "pi_manual_abs_${i}_$(date +%s)" \
            --wu_template templates/pi_in.xml \
            --result_template templates/pi_out.xml \
            --target_nresults 3 \
            $abs_input
        
        if [ $? -eq 0 ]; then
            echo "  ✓ Created with absolute path"
        else
            echo "  ✗ Still failed - checking configuration..."
        fi
    fi
    echo ""
done

echo "=========================================="
echo "Checking results..."
echo ""

# Verifică DB cu numele corect
echo "Database check:"
mysql -u root -p << 'EOF'
USE pi_test;
SELECT COUNT(*) as 'Total WUs' FROM workunit;
SELECT COUNT(*) as 'Total Results' FROM result;
SELECT COUNT(*) as 'Unsent WUs' FROM workunit WHERE transition_time > 0;
EOF

echo ""
echo "File system check:"
echo "Download directory: $(ls download/ | wc -l) items"
echo "Upload directory: $(ls upload/ | wc -l) items"

echo ""
echo "=========================================="
