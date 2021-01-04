#!/bin/bash

echo "Esperando.."
echo $1
# Check if the window keeps open
GREP_RESULT=$(wmctrl -l | grep $1) 

# After that, check each 2 seconds if the page already load
while ! [[ -z "$GREP_RESULT" ]];
do 
    GREP_RESULT=$(wmctrl -l | grep $1) 
    echo "$GREP_RESULT"
    sleep 2s; 
done

echo $1
echo "Ya esta cerrado"
# Delete the WID
awk "!/$1/" $2 > temp && mv temp $2