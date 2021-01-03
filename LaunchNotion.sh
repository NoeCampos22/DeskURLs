#! /bin/bash

# Global variables
WID_FILE=/home/noecampos/.local/share/applications/Notion/WID.txt       # Path where the Windows ID is stored
URL="https://www.notion.so/Dashboard-136779f17240447ebea6a87ae09f79e5"  # URL to the Notion page
PAGE_NAME="Dashboard"                                                   # Initial page name


# Function to open Notion and store the WID
openURL () {

	# Store the number of previous instances of Notion
	GREP_RESULT=$(wmctrl -l | grep $PAGE_NAME)
	PREV=$(echo $GREP_RESULT | awk '{print NF/4}')

	# Calculate the position of the new WID
	WID_NUM=$((4 * $PREV + 1))
	echo $WID_NUM

	# Open the Notion web page
    brave-browser --app=$URL &

	# Wait 5 seconds for the page to load
	sleep 5s

	# And check if the page already load or not
	GREP_RESULT=$(wmctrl -l | grep $PAGE_NAME) 

	# After that, check each 2 seconds if the page already load
	while [[ -z "$GREP_RESULT" ]];
	do 
		GREP_RESULT=$(wmctrl -l | grep $PAGE_NAME) 
		sleep 2s; 
	done

    # Save and append the new WID
	WID=$(echo $GREP_RESULT | awk -v var=$WID_NUM '{print $(var)}')
	echo $WID 
    echo $WID >> $WID_FILE;
 
	#nohup 
	/home/noecampos/.local/share/applications/Notion/ClosingWindow.sh $WID $WID_FILE
}

# Check if the file exists
if test -f "$WID_FILE"; then

	# If it is not empty...
	if [ -s "$WID_FILE" ]; then

		# Get the WID stored on the file
		WID=$(cat "$WID_FILE")

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