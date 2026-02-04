#!/bin/bash

clear
echo "Monitoring BOINC Clients - Press Ctrl+C to exit"
echo "Refreshing every 10 seconds..."
echo ""

while true; do
    clear
    echo "=========================================="
    echo "BOINC Clients Status - $(date '+%H:%M:%S')"
    echo "=========================================="
    echo ""
    
    # Procese
    echo "=== Running Processes ==="
    ps aux | grep boinc_client | grep -v grep | awk '{print $2, $11, $12, $13, $14}' || echo "No processes found"
    echo ""
    
    # Client A
    echo "=== Client A (Port 31421) ==="
    if [ -f ~/boinc_clients/client_a/client_state.xml ]; then
        results=$(grep -c "<result>" ~/boinc_clients/client_a/client_state.xml 2>/dev/null || echo 0)
        echo "Results: $results"
        
        if [ -f ~/boinc_clients/client_a/client_a.log ]; then
            echo "Last message:"
            tail -1 ~/boinc_clients/client_a/client_a.log
        fi
    else
        echo "Not initialized"
    fi
    echo ""
    
    # Client B
    echo "=== Client B (Port 31422) ==="
    if [ -f ~/boinc_clients/client_b/client_state.xml ]; then
        results=$(grep -c "<result>" ~/boinc_clients/client_b/client_state.xml 2>/dev/null || echo 0)
        echo "Results: $results"
        
        if [ -f ~/boinc_clients/client_b/client_a.log ]; then
            echo "Last message:"
            tail -1 ~/boinc_clients/client_b/client_a.log
        fi
    else
        echo "Not initialized (wait 30-60 sec after start)"
    fi
    echo ""
    
    # Client C
    echo "=== Client C (Port 31423) ==="
    if [ -f ~/boinc_clients/client_c/client_state.xml ]; then
        results=$(grep -c "<result>" ~/boinc_clients/client_c/client_state.xml 2>/dev/null || echo 0)
        echo "Results: $results"
        
        if [ -f ~/boinc_clients/client_c/client_a.log ]; then
            echo "Last message:"
            tail -1 ~/boinc_clients/client_c/client_a.log
        fi
    else
        echo "Not initialized (wait 30-60 sec after start)"
    fi
    echo ""
    
    # Server stats
    echo "=== Server (pi_test) ==="
    upload_count=$(ls ~/projects/pi_test/upload 2>/dev/null | wc -l)
    download_count=$(ls ~/projects/pi_test/download 2>/dev/null | wc -l)
    echo "Work units available: $download_count"
    echo "Results uploaded: $upload_count"
    echo ""
    
    echo "=========================================="
    
    sleep 10
done
