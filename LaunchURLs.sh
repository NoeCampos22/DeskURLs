#! /bin/bash

# Flags to know if the options where or not received
fileFlg=
urlFlg=
webPageFLG=

# Global variables
fileVal=
urlVal=
webPageVal=

# Execute getopt on the arguments passed to this program
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
        fileFlg=1;
        fileVal=$2;
        shift 2;;
    
    -u|--url|--url=)
        urlFlg=1;
        urlVal=$2;
        shift 2;;
    
    -p|--pagename)
        webPageFLG=1;
        webPageVal=$2;
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

if [[ -z "$urlFlg" || -z "$webPageFLG" || -z "$fileFlg" ]]; then
    echo "All the parameters are required"
    exit 1
fi


# Function to open Notion and store the WID
openURL () {

	# Store the number of previous instances of Notion
	GREP_RESULT=$(wmctrl -l | grep $webPageVal)
	PREV=$(echo $GREP_RESULT | awk '{print NF/4}')

	# Calculate the position of the new WID
	WID_NUM=$((4 * $PREV + 1))
	echo $WID_NUM

	# Open the Notion web page
    brave-browser --app=$urlVal &

	# Wait 5 seconds for the page to load
	sleep 5s

	# And check if the page already load or not
	GREP_RESULT=$(wmctrl -l | grep $webPageVal) 

	# After that, check each 2 seconds if the page already load
	while [[ -z "$GREP_RESULT" ]];
	do 
		GREP_RESULT=$(wmctrl -l | grep $webPageVal) 
		sleep 2s; 
	done

    # Save and append the new WID
	WID=$(echo $GREP_RESULT | awk -v var=$WID_NUM '{print $(var)}')
	echo $WID 
    echo $WID >> $fileVal;
 
	#nohup 
	/home/noecampos/.local/share/applications/LaunchURLS/CloseWindow.sh $WID $fileVal
}

# Check if the file exists
if test -f "$fileVal"; then

	# If it is not empty...
	if [ -s "$fileVal" ]; then

		# Get the WID stored on the file
		WID=$(cat "$fileVal")

		# Check if WID is currently used with Notion opened as an app
		GREP_RESULT=$(wmctrl -l | grep $WID)
		if [ -z "$GREP_RESULT" ]
		# If the output is empty, it means there is no instance
		then
			# Open notion 
			openURL

		# If grep returns something, it means the app is already opened
		else			
			# Bring the window to the front
			wmctrl -iR $WID
		fi
	
	# Check if the file is empty
	else
		# Open notion  
		openURL
	fi

# Create it and open Notion
else
	# Open notion 
	openURL
fi

sleep 10
