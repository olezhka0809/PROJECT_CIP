#!/bin/bash

echo "=========================================="
echo "BOINC Detailed Diagnosis"
echo "=========================================="
echo ""

# 1. Client activ
echo "=== Active BOINC Client ==="
client_pid=$(ps aux | grep boinc_client | grep -v grep | awk '{print $2}')
if [ ! -z "$client_pid" ]; then
    echo "✓ Client PID: $client_pid"
    client_dir=$(readlink -f /proc/$client_pid/cwd)
    echo "✓ Working directory: $client_dir"
    
    if [ -f "$client_dir/client_state.xml" ]; then
        echo ""
        echo "Projects attached:"
        grep -A 1 "<master_url>" "$client_dir/client_state.xml" | grep -v "master_url"
        
        echo ""
        echo "Active tasks:"
        grep -c "<active_task>" "$client_dir/client_state.xml" || echo "0"
        
        echo ""
        echo "Last 10 messages:"
        tail -10 "$client_dir/stdoutdae.txt" 2>/dev/null || echo "No log file"
    fi
else
    echo "✗ No active BOINC client"
fi

echo ""
echo "=== Pi Test Project ==="
if [ -d ~/projects/pi_test ]; then
    echo "✓ Project exists"
    
    echo ""
    echo "Directory structure:"
    ls -la ~/projects/pi_test/ | awk '{print $9}' | grep -v "^$" | head -15
    
    echo ""
    echo "Upload directory (results from clients):"
    if [ -d ~/projects/pi_test/upload ]; then
        upload_count=$(ls ~/projects/pi_test/upload 2>/dev/null | wc -l)
        echo "  Files: $upload_count"
        ls -lht ~/projects/pi_test/upload | head -5
    fi
    
    echo ""
    echo "Download directory (work units for clients):"
    if [ -d ~/projects/pi_test/download ]; then
        download_count=$(ls ~/projects/pi_test/download 2>/dev/null | wc -l)
        echo "  Files: $download_count"
        ls -lht ~/projects/pi_test/download | head -5
    fi
else
    echo "✗ Pi test project not found"
fi

echo ""
echo "=== Database Check ==="
mysql -u root -p -e "SHOW DATABASES;" 2>/dev/null | grep -i pi_test
if [ $? -eq 0 ]; then
    echo "✓ Database exists"
    echo ""
    echo "Enter MySQL root password to see work unit stats:"
    mysql -u root -p -e "USE boinc_pi_test; SELECT COUNT(*) as 'Total WUs' FROM workunit; SELECT COUNT(*) as 'Total Results' FROM result; SELECT state, COUNT(*) FROM result GROUP BY state;" 2>/dev/null
fi

echo ""
echo "=== Web Interface ==="
for dir in /var/www/html/pi_test /var/www/pi_test /var/www/html/boinc; do
    if [ -d "$dir" ]; then
        echo "✓ Found: $dir"
    fi
done

echo ""
echo "=== Client Directories ==="
for client in ~/boinc_clients/client_*; do
    if [ -d "$client" ]; then
        client_name=$(basename "$client")
        echo ""
        echo "$client_name:"
        ls -la "$client" | wc -l | xargs echo "  Files:"
        
        if [ -f "$client/client_state.xml" ]; then
            echo "  ✓ Has client_state.xml"
        fi
        
        if [ -d "$client/slots" ]; then
            slot_count=$(ls "$client/slots" 2>/dev/null | wc -l)
            echo "  Slots: $slot_count"
        fi
    fi
done

echo ""
echo "=========================================="
