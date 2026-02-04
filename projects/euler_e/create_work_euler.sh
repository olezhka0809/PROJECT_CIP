#!/bin/bash
cd /home/helgidev08/projects/euler_e

for i in {1..5}; do
    iterations=$((1000000 * i))
    ./bin/create_work \
        --appname euler_e \
        --wu_name "euler_${i}_$(date +%s)" \
        --wu_template templates/euler_in \
        --result_template templates/euler_out \
        --command_line "$iterations"
    echo "Created work unit $i with $iterations iterations"
done
