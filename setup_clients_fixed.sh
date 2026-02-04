#!/bin/bash

echo "=========================================="
echo "Setup Client B and C for Pi Project"
echo "=========================================="

# Găsește informații din fișierul de cont
if [ -f ~/boinc_clients/client_a/account_127.0.0.1_pi_test.xml ]; then
    PROJECT_URL=$(grep -oP '(?<=<master_url>)[^<]+' ~/boinc_clients/client_a/account_127.0.0.1_pi_test.xml)
    ACCOUNT_KEY=$(grep -oP '(?<=<authenticator>)[^<]+' ~/boinc_clients/client_a/account_127.0.0.1_pi_test.xml)
else
    echo "ERROR: Account file not found!"
    exit 1
fi

echo "Project URL: $PROJECT_URL"
echo "Account Key: $ACCOUNT_KEY"
echo ""

if [ -z "$PROJECT_URL" ] || [ -z "$ACCOUNT_KEY" ]; then
    echo "ERROR: Could not extract project credentials"
    exit 1
fi

# Funcție pentru setup client
setup_client() {
    local client_dir=$1
    local client_name=$(basename $client_dir)
    local port=$2
    
    echo "=========================================="
    echo "Setting up $client_name on port $port"
    echo "=========================================="
    
    cd $client_dir
    
    # Oprește orice instanță veche
    pkill -f "boinc_client.*$client_name" 2>/dev/null
    sleep 2
    
    # Curăță directorul (păstrează doar ce e necesar)
    rm -f lockfile client_state.xml client_state_prev.xml
    
    # Creează structura de directoare
    mkdir -p projects slots notices
    
    # Copiază fișierele de configurare de la client_a
    cp ~/boinc_clients/client_a/gui_rpc_auth.cfg . 2>/dev/null
    cp ~/boinc_clients/client_a/all_projects_list.xml . 2>/dev/null
    
    # Creează fișierul de cont
    cat > account_127.0.0.1_pi_test.xml << EOF
<account>
    <master_url>$PROJECT_URL</master_url>
    <authenticator>$ACCOUNT_KEY</authenticator>
</account>
EOF
    
    echo "✓ Configuration files created"
    
    # Pornește clientul
    echo "Starting BOINC client..."
    nohup ~/boinc_source/client/boinc_client \
        --dir $client_dir \
        --allow_remote_gui_rpc \
        --gui_rpc_port $port \
        > $client_dir/boinc_startup.log 2>&1 &
    
    local pid=$!
    echo "✓ Client started with PID: $pid"
    
    # Așteaptă puțin ca clientul să pornească
    sleep 5
    
    # Verifică dacă procesul rulează
    if ps -p $pid > /dev/null; then
        echo "✓ $client_name is running!"
        
        # Verifică dacă a creat client_state.xml
        if [ -f $client_dir/client_state.xml ]; then
            echo "✓ Client initialized successfully"
        else
            echo "⚠ Client running but not initialized yet (wait ~30 seconds)"
        fi
    else
        echo "✗ Failed to start $client_name"
        echo "Check log: cat $client_dir/boinc_startup.log"
    fi
    
    echo ""
}

# Setup clienți
setup_client ~/boinc_clients/client_b 31422
setup_client ~/boinc_clients/client_c 31423

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Verify all clients are running:"
echo "  ps aux | grep boinc_client"
echo ""
echo "Monitor Client B:"
echo "  tail -f ~/boinc_clients/client_b/boinc_startup.log"
echo ""
echo "Monitor Client C:"
echo "  tail -f ~/boinc_clients/client_c/boinc_startup.log"
echo ""
echo "Check client logs after 30 seconds:"
echo "  cat ~/boinc_clients/client_b/client_a.log"
echo "  cat ~/boinc_clients/client_c/client_a.log"
echo "=========================================="
