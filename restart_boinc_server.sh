#!/bin/bash

echo "=========================================="
echo "BOINC Server Daemon Control"
echo "=========================================="

PROJECT_DIR=~/projects/pi_test
cd $PROJECT_DIR

if [ ! -f "config.xml" ]; then
    echo "ERROR: Not in project directory!"
    exit 1
fi

echo "Working in: $PROJECT_DIR"
echo ""

# Funcție pentru verificare proces
check_daemon() {
    local daemon_name=$1
    if pgrep -f "$daemon_name" > /dev/null; then
        echo "  ✓ $daemon_name is running"
        return 0
    else
        echo "  ✗ $daemon_name is NOT running"
        return 1
    fi
}

# Verifică starea actuală
echo "Current status:"
check_daemon "feeder"
check_daemon "transitioner"
check_daemon "validator"
check_daemon "assimilator"
check_daemon "file_deleter"
echo ""

# Întreabă dacă vrea restart
read -p "Do you want to (r)estart, (s)tart, or (st)op daemons? [r/s/st]: " action

if [ "$action" = "st" ] || [ "$action" = "r" ]; then
    echo ""
    echo "Stopping all daemons..."
    
    if [ -f bin/stop ]; then
        bin/stop
    else
        pkill -f "feeder.*$PROJECT_DIR"
        pkill -f "transitioner.*$PROJECT_DIR"
        pkill -f "validator.*$PROJECT_DIR"
        pkill -f "assimilator.*$PROJECT_DIR"
        pkill -f "file_deleter.*$PROJECT_DIR"
    fi
    
    sleep 2
    echo "✓ Stopped"
fi

if [ "$action" = "s" ] || [ "$action" = "r" ]; then
    echo ""
    echo "Starting daemons..."
    
    if [ -f bin/start ]; then
        echo "Using bin/start..."
        bin/start
    else
        echo "Starting daemons manually..."
        
        # Feeder - distribuie work units
        if [ -f bin/feeder ]; then
            nohup bin/feeder -d 3 >> log_*/feeder.log 2>&1 &
            echo "  Started feeder (PID: $!)"
        fi
        
        # Transitioner - gestionează stările WU
        if [ -f bin/transitioner ]; then
            nohup bin/transitioner -d 3 >> log_*/transitioner.log 2>&1 &
            echo "  Started transitioner (PID: $!)"
        fi
        
        # Validator - validează rezultatele
        if [ -f bin/sample_trivial_validator ]; then
            nohup bin/sample_trivial_validator --app pi_compute -d 3 >> log_*/validator.log 2>&1 &
            echo "  Started validator (PID: $!)"
        elif [ -f bin/validator ]; then
            nohup bin/validator --app pi_compute -d 3 >> log_*/validator.log 2>&1 &
            echo "  Started validator (PID: $!)"
        fi
        
        # Assimilator - procesează rezultatele validate
        if [ -f bin/sample_assimilator ]; then
            nohup bin/sample_assimilator --app pi_compute -d 3 >> log_*/assimilator.log 2>&1 &
            echo "  Started assimilator (PID: $!)"
        elif [ -f bin/assimilator ]; then
            nohup bin/assimilator --app pi_compute -d 3 >> log_*/assimilator.log 2>&1 &
            echo "  Started assimilator (PID: $!)"
        fi
        
        # File deleter - șterge fișierele vechi
        if [ -f bin/file_deleter ]; then
            nohup bin/file_deleter -d 3 >> log_*/file_deleter.log 2>&1 &
            echo "  Started file_deleter (PID: $!)"
        fi
    fi
    
    sleep 3
    
    echo ""
    echo "Verification:"
    check_daemon "feeder"
    check_daemon "transitioner"
    check_daemon "validator"
    check_daemon "assimilator"
    check_daemon "file_deleter"
fi

echo ""
echo "=========================================="
echo "Status Check:"
echo ""

# Verifică WU disponibile
echo "Work Units status:"
mysql -u root -p -e "
USE pi_test;
SELECT 
    'Total' as Status, 
    COUNT(*) as Count 
FROM workunit
UNION ALL
SELECT 
    'Unsent (ready)', 
    COUNT(*) 
FROM result 
WHERE server_state=2
UNION ALL
SELECT 
    'In Progress', 
    COUNT(*) 
FROM result 
WHERE server_state=4
UNION ALL
SELECT 
    'Uploaded', 
    COUNT(*) 
FROM result 
WHERE server_state=5;
" 2>/dev/null

echo ""
echo "Last 10 log entries (transitioner):"
tail -10 log_*/transitioner.log 2>/dev/null || echo "No log found"

echo ""
echo "=========================================="
echo "Monitor with:"
echo "  tail -f log_*/transitioner.log"
echo "  tail -f log_*/feeder.log"
echo "  tail -f ~/boinc_clients/client_a/boinc_startup.log"
echo "=========================================="
