#!/bin/bash

# Flags to know if the options where or not received
uflag=
oflag=
fflag=

uval=
oval=
fval=

# This is a while loop to go through all the options and get their values, 
# all of them are parsed by the "getopts" command.
# The first parameter to the "getopts" command is a string used to specify the 
# expected options and if they have to have a  value 
# (To this, the letter must be followed by a colon. Ex: p:)
# Also, the first colon on the string is to mute the defualt error messages of the 
# command and be able to display our own error messages.
# The second parameter (OPTNAME) is an identifier to store the value of the current option
# It is important to say that if a option has a value, it will be stored on 
# a variable named OPTARG
while getopts ":u:o:f:h" OPTNAME
do
    case "$OPTNAME" in
        "u")
            uflag=1;
            uval=$OPTARG;;

        "o")
            oflag=1;
            oval=$OPTARG;;

        "f")
            fflag=1;
            fval=$OPTARG;;
        
        "h")
            echo "Usage (Print all the manual)";
            exit 1;;

        "?") 
            echo "Unknown option $OPTARG";
            exit 1;;
        
        ":") 
            echo "No value for option $OPTARG";
            echo "All the parameters must have values.";
            exit 1;;
        
        # Should not occur
        *) 
            echo "Unknown error while processing options";
            exit 1;;
    esac
done


if [[ -z "$uflag" || -z "$fflag" || -z "$oflag" ]]; then
    echo "All the parameters are required"
    exit 1
fi