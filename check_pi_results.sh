#!/bin/bash

echo "=========================================="
echo "BOINC Pi Calculation Results"
echo "=========================================="

PROJECT_DIR=~/projects/pi_test
cd $PROJECT_DIR

echo "Analyzing results from upload directory..."
echo ""

# Funcție pentru extragere valoare Pi dintr-un fișier
extract_pi() {
    local file=$1
    if [ -f "$file" ]; then
        # Caută valori Pi (număr care începe cu 3.14...)
        pi_value=$(grep -oE "3\.[0-9]{6,}" "$file" | head -1)
        if [ ! -z "$pi_value" ]; then
            echo "$pi_value"
            return 0
        fi
        
        # Alternativ, caută "Pi = "
        pi_value=$(grep -i "pi.*=" "$file" | grep -oE "[0-9]\.[0-9]+" | head -1)
        if [ ! -z "$pi_value" ]; then
            echo "$pi_value"
            return 0
        fi
    fi
    return 1
}

# Găsește toate fișierele de rezultate recent încărcate
echo "=== Recent Results (last 24h) ==="
find upload -type f -mtime -1 2>/dev/null | sort | while read result_file; do
    echo ""
    echo "File: $(basename $(dirname $result_file))/$(basename $result_file)"
    
    pi_val=$(extract_pi "$result_file")
    if [ ! -z "$pi_val" ]; then
        # Calculează eroarea față de Pi real (3.14159265359)
        error=$(echo "scale=10; ($pi_val - 3.14159265359)" | bc -l 2>/dev/null | sed 's/^-//')
        accuracy=$(echo "scale=4; (1 - $error / 3.14159265359) * 100" | bc -l 2>/dev/null)
        
        echo "  Pi value: $pi_val"
        echo "  Error: $error"
        echo "  Accuracy: ${accuracy}%"
    else
        echo "  Content preview:"
        head -3 "$result_file" | sed 's/^/    /'
    fi
done

echo ""
echo "=========================================="
echo "Database Statistics"
echo "=========================================="

mysql -u root -p << 'EOSQL'
USE pi_test;

-- Statistici generale
SELECT 
    'Work Units' as Metric, 
    COUNT(*) as Count 
FROM workunit
UNION ALL
SELECT 
    'Results Uploaded', 
    COUNT(*) 
FROM result 
WHERE server_state=5
UNION ALL
SELECT 
    'Results Validated', 
    COUNT(*) 
FROM result 
WHERE validate_state=1;

-- Detalii pe fiecare WU din seria pi_copy
SELECT 
    w.id,
    w.name as WorkUnit,
    COUNT(r.id) as Results,
    SUM(CASE WHEN r.server_state=5 THEN 1 ELSE 0 END) as Uploaded,
    SUM(CASE WHEN r.validate_state=1 THEN 1 ELSE 0 END) as Validated,
    ROUND(AVG(r.cpu_time), 2) as Avg_CPU_Time,
    ROUND(AVG(r.elapsed_time), 2) as Avg_Elapsed_Time
FROM workunit w
LEFT JOIN result r ON r.workunitid = w.id
WHERE w.name LIKE 'pi_copy%'
GROUP BY w.id, w.name
ORDER BY w.id;

-- Client-uri care au contribuit
SELECT 
    h.id as Host_ID,
    h.domain_name,
    COUNT(DISTINCT r.id) as Results_Submitted,
    ROUND(SUM(r.cpu_time)/3600, 2) as Total_CPU_Hours,
    ROUND(AVG(r.cpu_time), 2) as Avg_Task_Time
FROM host h
JOIN result r ON r.hostid = h.id
WHERE r.server_state=5
GROUP BY h.id, h.domain_name;

EOSQL

echo ""
echo "=========================================="
echo "Individual Task Results"
echo "=========================================="

# Listează fiecare result cu detalii
mysql -u root -p -t << 'EOSQL'
USE pi_test;

SELECT 
    SUBSTRING(w.name, 1, 20) as WorkUnit,
    SUBSTRING(r.name, 1, 25) as Result,
    CASE r.server_state
        WHEN 2 THEN 'UNSENT'
        WHEN 4 THEN 'IN_PROG'
        WHEN 5 THEN 'UPLOADED'
    END as State,
    CASE r.validate_state
        WHEN 0 THEN 'INIT'
        WHEN 1 THEN 'VALID'
        WHEN 2 THEN 'INVALID'
    END as Valid,
    ROUND(r.cpu_time, 1) as CPU_sec,
    r.hostid as Host
FROM result r
JOIN workunit w ON r.workunitid = w.id
WHERE w.name LIKE 'pi_copy%'
ORDER BY w.id, r.id;

EOSQL

echo ""
echo "=========================================="
echo "Cross-Validation Check"
echo "=========================================="
echo "BOINC compares results from different clients"
echo "to verify correctness (redundancy = 3 results/WU)"
echo ""

# Verifică câte WU-uri au toate cele 3 rezultate
mysql -u root -p << 'EOSQL'
USE pi_test;

SELECT 
    w.name as WorkUnit,
    COUNT(r.id) as Total_Results,
    SUM(CASE WHEN r.server_state=5 THEN 1 ELSE 0 END) as Uploaded_Results,
    CASE 
        WHEN COUNT(r.id) = 3 AND SUM(CASE WHEN r.server_state=5 THEN 1 ELSE 0 END) = 3 
        THEN '✓ COMPLETE'
        ELSE '⧗ PENDING'
    END as Status
FROM workunit w
LEFT JOIN result r ON r.workunitid = w.id
WHERE w.name LIKE 'pi_copy%'
GROUP BY w.id, w.name
ORDER BY w.id;

EOSQL

echo ""
echo "=========================================="
echo "To see actual Pi values in output files:"
echo "  ls -lht upload/ | head -20"
echo "  cat upload/XXX/YYY_0  # Replace with actual file"
echo ""
echo "To check validator logs:"
echo "  tail -50 log_*/validator.log"
echo "=========================================="

