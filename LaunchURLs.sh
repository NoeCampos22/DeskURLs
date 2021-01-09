#! /bin/bash

DeskfilesPath=~/.local/share/applications/URLs_DeskFiles
TemporalPath=/tmp/LaunchURLs/

# Execute getopt on the arguments passed to this program
PARSED_OPTIONS="$(getopt --n "LaunchURLs" -o ynYNh -l asApp,asTab,appname:,url:,webpage:,closeWindow,deskfile,uninstall,help -- "$@")"

# If any bad argument was received
[ $? -eq 0 ] || { 
    echo -e "\nInvalid options provided\n"
    exit 1
}

# Needed when using getopt
eval set -- "$PARSED_OPTIONS"
unset PARSED_OPTIONS


# Function to open Notion and store the WID
openURL () {

	# Store the number of previous instances of Notion
	GREP_RESULT=$(wmctrl -l | grep $3)
	PREV=$(echo $GREP_RESULT | awk '{print NF/4}')

	# Calculate the position of the new WID
	WID_NUM=$((4 * $PREV + 1))

	# Open the Notion web page
    brave-browser --app=$2 &

	# Wait 5 seconds for the page to load
	sleep 5s

	# And check if the page already load or not
	GREP_RESULT=$(wmctrl -l | grep $3) 

	# After that, check each 2 seconds if the page already load
	while [[ -z "$GREP_RESULT" ]];
	do 
		GREP_RESULT=$(wmctrl -l | grep $3) 
		sleep 2s; 
	done

    # Save and append the new WID
	WID=$(echo $GREP_RESULT | awk -v var=$WID_NUM '{print $(var)}')

	# To append or overwritte the wid file
	if $4; then
		echo $WID >> $1;
	else
    	echo $WID > $1;
	fi
	
	# Leave on the background the close function
	nohup LaunchURLs --closeWindow $WID $1 $
}

closeWindow() {
	# Check if the window keeps open
	GREP_RESULT=$(wmctrl -l | grep $1) 

	# After that, check each 2 seconds if the page already load
	while ! [[ -z "$GREP_RESULT" ]];
	do 
		GREP_RESULT=$(wmctrl -l | grep $1) 
		sleep 2s; 
	done
	
	# Delete the WID
	awk "!/$1/" $2 > temp && mv temp $2
}

# Execute the solicited option
while true; do
    case $1 in

		--asApp)
			shift 1;

			# Make sure all the needed optiones were received
			# Application Name, URL, Web Page Name
			if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
				echo "All the parameters are required";
				exit 1;
			fi

			# Build the path to the temporal file
			filePath="$TemporalPath"${2// /_}"_WID"

			# Check if the file exists
			if test -f "$filePath"; then

				# If it is not empty...
				if [ -s "$filePath" ]; then

					# Get the WID stored on the file
					WID=$(cat "$filePath")

					# Check if WID is currently used with Notion opened as an app
					GREP_RESULT=$(wmctrl -l | grep $WID)
					if [ -z "$GREP_RESULT" ]
					# If the output is empty, it means there is no instance
					then
						# Open notion 
						openURL $filePath $3 $4 false

					# If grep returns something, it means the app is already opened
					else			
						# Bring the window to the front
						wmctrl -iR $WID
					fi
				
				# Check if the file is empty
				else
					# Open notion  
					openURL $filePath $3 $4 true
				fi

			# Create it and open Notion
			else
				# Open notion 
				openURL $filePath $3 $4 true
			fi
			exit 1;
			;;

		--asTab)
			shift 1;
			
			# Open the url as another tab
			nohup brave-browser $2 &
			exit 1;
			;;
		
		--closeWindow)
			shift 1;

			# Option to leave a background function waiting 
			# until the window is closed to update the file
			closeWindow $2 $3
			exit 1;
			;;

		--deskfile)
			shift 1;


			template="[Desktop Entry]\nVersion=1.0\nName={APP_NAME} \nComment=To open {APP_NAME}";

			# Check if the launcher will open the URL as a tab 
			# or as a an app
			case $1 in
				--asApp)

					# Make sure all the needed optiones were received
					# Application Name, URL, Web Page Name
					if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
						echo "All the parameters are required";
						exit 1;
					fi


					template="$template\nExec=bash -c \"LaunchURLs --asApp '{APP_NAME}' '{URL}' '{WEB_PAGE}'\""
					appname=${3// /_}
					URL=$4;
					webpage=$5
					shift 1;;

				--asTab)

					# Make sure all the needed optiones were received
					# Application Name, URL, Web Page Name
					if [[ -z "$3" || -z "$4" ]]; then
						echo "All the parameters are required";
						exit 1;
					fi

					template="$template\nExec=bash -c \"LaunchURLs --asTab '{URL}'\""
					appname=${3// /_}
					URL=$4;
					shift 1;;

				--)
					echo "Manual";
					exit 1; 
			esac

			template="$template\nIcon=/usr/share/icons/{APP_NAME}\nEncoding=UTF-8\nTerminal=false"
			template="$template\nType=Application\nName[it]={APP_NAME}\nCategories=URL"

			# Replace the template placeholders to the real URL
			template="${template//\{APP_NAME\}/$appname}"
			template="${template//\{URL\}/$URL}"
			template="${template//\{WEB_PAGE\}/$webpage}"

			echo -e $template > $DeskfilesPath/$appname.desktop
			;;

		--uninstall)
			shift 1;

			if [ "$#" -gt 1 ]; then
				echo -e "\nAny option after --uninstall will be ignored."
			fi

			# Remove the created .desktop files
			echo -e "\nThe .desktop files created by LaunchURLs will also be removed."
			[[ -d $DeskfilesPath ]] && rm -rf $DeskfilesPath;
			[[ -d $TemporalPath ]] && rm -rf $TemporalPath;

			# Get the path to the command and delete the file
			whichLaunch=$(which LaunchURLs);
			sudo rm -rf $whichLaunch;
			echo -e "LaunchURLs was uninstalled succesfully!\n"
			exit 1;
			;;

		-h|--help)
			echo "Usage (Print the Manual)"
			exit 1;;
		
		--)
			shift;
			break;;
		
		*) 
			echo "Unknown error while processing options";
			exit 1;;

    esac
done
