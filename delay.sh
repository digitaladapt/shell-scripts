#!/bin/bash

# optionally takes a single argument of how long of a delay to take. defaults to 5 seconds.
seconds=$1

# seconds 
if [[ "$seconds" -lt "1" ]] || [[ "$seconds" -gt "60" ]]; then
    seconds=5
fi

# convert delay in seconds to 1/50 slice of time
slice=$(echo "scale=3; $seconds/50" | bc -l)

echo ''
for i in $(seq 1 50); do
    sleep "$slice"
    echo -n '.'
done
echo ''

