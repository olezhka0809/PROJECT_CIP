#!/bin/bash

echo "=========================================="
echo "Setup Client B and C for Pi Project"
echo "=========================================="

# Găsește URL-ul proiectului din Client A
PROJECT_URL=$(grep -oP '(?<=<master_url>)[^<]+' ~/boinc_clients/client_a/client_state.xml | head -1)
ACCOUNT_KEY=$(grep -oP '(?<=<authenticator>)[^<]+' ~/boinc_clients/client_a/client_state.xml | head -1)

echo "Project URL: $PROJECT_URL"
echo "Account Key: $ACCOUNT_KEY"
echo ""

if [ -z "$PROJECT_URL" ] || [ -z "$ACCOUNT_KEY" ]; then
    echo "ERROR: Could not find project info from client_a"
    exit 1
fi

# Funcție pentru setup client
setup_client() {
    local client_dir=$1
    local client_name=$(basename $client_dir)
    local port=$2
    
    echo "Setting up $client_name..."
    
    cd $client_dir
    
    # Creează fișier de configurare
    cat > gui_rpc_auth.cfg << EOF
$(cat ~/boinc_clients/client_a/gui_rpc_auth.cfg 2>/dev/null || echo "boinc")
EOF
    
    # Creează directoare necesare
    mkdir -p projects slots
    
    # Pornește clientul în background cu port diferit
    echo "Starting $client_name on port $port..."
    nohup ~/boinc_source/client/boinc_client \
        --dir $client_dir \
        --allow_remote_gui_rpc \
        --gui_rpc_port $port \
        > $client_dir/boinc_start.log 2>&1 &
    
    sleep 3
    
    # Atașează la proiect folosind boinccmd
    if command -v boinccmd &> /dev/null; then
        echo "Attaching to project..."
        boinccmd --host localhost:$port --project_attach $PROJECT_URL $ACCOUNT_KEY
    else
        echo "WARNING: boinccmd not found. Manual attach needed."
    fi
    
    echo "$client_name setup complete!"
    echo ""
}

# Setup Client B pe port 31422
setup_client ~/boinc_clients/client_b 31422

# Setup Client C pe port 31423
setup_client ~/boinc_clients/client_c 31423

echo "=========================================="
echo "All clients configured!"
echo ""
echo "Check status with:"
echo "  ps aux | grep boinc_client"
echo ""
echo "Monitor logs:"
echo "  tail -f ~/boinc_clients/client_b/stdoutdae.txt"
echo "  tail -f ~/boinc_clients/client_c/stdoutdae.txt"
echo "=========================================="

