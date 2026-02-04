#!/bin/bash

echo "=========================================="
echo "Complete Diagnostic for create_work"
echo "=========================================="

cd ~/projects/pi_test

echo "1. Project configuration:"
echo "---"
cat config.xml | grep -E "<name>|<app>|<user_friendly_name>" | head -20

echo ""
echo "2. Database name:"
mysql -u root -p -e "SHOW DATABASES;" 2>/dev/null | grep -i "test\|boinc\|pi"

echo ""
echo "3. Templates:"
ls -la templates/

echo ""
echo "4. Applications:"
find apps -type f | head -10

echo ""
echo "5. Existing work unit example:"
mysql -u root -p << 'EOF'
USE pi_test;
SELECT name, xml_doc FROM workunit LIMIT 1;
EOF

echo ""
echo "6. Download directory structure:"
ls -la download/ | head -20

echo ""
echo "7. Test create_work help:"
bin/create_work --help 2>&1 | head -30

echo "=========================================="
