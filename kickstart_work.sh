#!/bin/bash

echo "=========================================="
echo "Kickstart BOINC Work Generation"
echo "=========================================="

# 1. Fix permisiuni
echo "Step 1: Fixing permissions..."
cd ~/projects/pi_test
sudo chmod -R 777 upload/ download/
sudo chown -R www-data:www-data upload/
echo "✓ Permissions fixed"

# 2. Generează work units noi
echo ""
echo "Step 2: Creating work units..."

for i in 1 2 3 4 5; do
    iterations=$((5000000 + i * 2000000))
    echo "Creating WU #$i with $iterations iterations"
    
    # Creează input file
    input_file="/tmp/pi_input_wu_$i.txt"
    echo "$iterations" > $input_file
    
    # Creează work unit
    cd ~/projects/pi_test
    bin/create_work \
        --appname pi_compute \
        --wu_name "pi_wu_restart_${i}_$(date +%s)" \
        --wu_template templates/pi_in.xml \
        --result_template templates/pi_out.xml \
        --target_nresults 3 \
        $input_file
    
    if [ $? -eq 0 ]; then
        echo "  ✓ WU #$i created"
    else
        echo "  ✗ Failed to create WU #$i"
    fi
done

# 3. Verifică în DB
echo ""
echo "Step 3: Database status..."
mysql -u root -p << 'EOF'
USE boinc_pi_test;
SELECT 'Total WUs' as Status, COUNT(*) as Count FROM workunit;
SELECT 'Unsent WUs' as Status, COUNT(*) as Count FROM workunit WHERE transition_time > 0;
SELECT 'Active Results' as Status, COUNT(*) as Count FROM result WHERE server_state=2;
EOF

# 4. Verifică fișierele
echo ""
echo "Step 4: File system check..."
echo "Download directory:"
ls ~/projects/pi_test/download/ | wc -l | xargs echo "  Files:"
echo "Upload directory:"
ls ~/projects/pi_test/upload/ | wc -l | xargs echo "  Files:"

# 5. Restart clienți pentru forțare update
echo ""
echo "Step 5: Nudging clients to request work..."
for client in client_a client_b client_c; do
    cd ~/boinc_clients/$client
    if [ -f client_state.xml ]; then
        # Touch fișierul pentru a forța re-read
        touch client_state.xml
        echo "  ✓ Nudged $client"
    fi
done

echo ""
echo "=========================================="
echo "Setup complete! Monitor with:"
echo "  watch -n 5 'ps aux | grep boinc_client | grep -v grep'"
echo "  tail -f ~/boinc_clients/client_a/boinc_startup.log"
echo "=========================================="
