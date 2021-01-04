#!/bin/bash

# Flags to know if the options where or not received
fflag=
uflag=
pflag=

# Variables to store the received values
fval=
uval=
pval=

# Execute getopt on the arguments passed to this program, identified by the special character $@
# The --n is to specify the program name
# -o is shot of options and is followed by the single letter options (Leter: if it will receive value)
# -l is for longoptions and then the string with the long named options 
# It is important to always end with the -- "$@" since is the part that tells getopt how to end
# the parsed options
PARSED_OPTIONS="$(getopt --n "Testing_GETOPT" -o f:u:p:h -l file:,url:,url=:,pagename:,help -- "$@")"

# If any bad argument was received
[ $? -eq 0 ] || { 
    echo "Incorrect options provided"
    exit 1
}

# Needed when using getopt
eval set -- "$PARSED_OPTIONS"
unset PARSED_OPTIONS

# Goes through all the options with a case and shifting when needing
# If it is just the option, it needs to shift 1 but if there is also a
# expected value, it needs to shift 2 and so on.
while true; do
    case $1 in

    -f|--file)
        fflag=1;
        fval=$2;
        shift 2;;
    
    -u|--url|--url=)
        uflag=1;
        uval=$2;
        shift 2;;
    
    -p|--pagename)
        pflag=1;
        pval=$2;
        shift 2;;
    
    -h|--help)
        echo "Usage (Print the Manual)"
        exit 1;;

    --)
        shift
        break;;
    
    # Should not occur
    *) 
        echo "Unknown error while processing options";
        exit 1;;

    esac
done

if [[ -z "$uflag" || -z "$pflag" || -z "$fflag" ]]; then
    echo "All the parameters are required"
    exit 1
fi

echo $fval
echo $uval
echo $pval
