#! /bin/bash

# Flags to know if the options where or not received
installFlg=
installDependencies=

# Global variables that store option values
alternativeInstPath=

# Needed extra global variables

# Execute getopt on the arguments passed to this program
PARSED_OPTIONS="$(getopt --n "LaunchURLs" -o ynYNp:h -l install,uninstall,path:,openAsApp,appname:,url:,webpage:,closeWindow,help -- "$@")"

# If any bad argument was received
[ $? -eq 0 ] || { 
    echo -e "\nInvalid options provided\n"
    exit 1
}

# Needed when using getopt
eval set -- "$PARSED_OPTIONS"
unset PARSED_OPTIONS

# Function that install the script on the specified path
# Or by default it will be moved to the /usr/bin/ directory
installScript() {

	# Check if wmctrl is already installed or not
	if ! command -v wmctrl >/dev/null 2>&1 ; then

		# Notify about the dependency and ask for permission
		echo 'This program has a dependcy on the package: wmctrl'

		# If the install dependencies option was not received...
		if [ ! -n "$installDependencies" ]; then

			# Ask the user
			while true; do
			read -p "Do you want to install: wmctrl? (Y/n) " installDependencies
				case $installDependencies in
					[YyNn]* )
						break;;

					* ) 
						echo -e "\nPlease answer yes (y/Y) or no (n/N).\n";
				esac
			done
		fi

		# Install or not the dependency
		case $installDependencies in
			1) 
				echo "";
				sudo apt-get install wmctrl -y; 
				echo "";;

			0)
				echo -e "\nCan not use LaunchURL without installing wmctrl\n";
				exit;;
		esac
		
	else
		echo -e "Dependency on wmctrl already satisfied!\n";
	fi

	# Build the current and target location
	CURR_LOC="$(pwd)/LaunchURLs.sh";

	# Build the installation path
	if [ -n "$alternativeInstPath" ]; then
		TARG_LOC="$alternativeInstPath/LaunchURLs";
	else
		TARG_LOC="/usr/bin/LaunchURLs";
	fi

	# Move the file to the target location
	sudo cp $CURR_LOC $TARG_LOC

	# Create the directory for the .desktop file
	mkdir ~/.local/share/applications/LaunchURLs_DeskFiles

	echo -e "\nLaunchURLs was succesfully installed!\n"
}

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

    --install)
		shift 1;

		# Check if the user already answer the
		# dependency permissions question via an option
		case $1 in
			-y|-Y)
				installDependencies=1;
				shift 1;;

			-n|-N)
				installDependencies=0;
				shift 1;;
		esac

		# Check if the user sent an alternative installation path
		case $1 in
			-p|--path)

				# Check that the received path is to a valid directory
				if [[ ! -d $2 ]]; then
					echo -e "\nThe path must be to a valid directory.\n"
					exit 1;
				fi

				alternativeInstPath=$2;
				shift 2;;
		esac
		
		if [ "$#" -gt 1 ]; then
			echo -e "\nAny option different than -y/Y, -n/N or --path after --install will be ignored."
		fi

		# Call the function that makes the validations
		# and installation
		installScript
		exit 1;
		;;

	--uninstall)
		shift 1;

		if [ "$#" -gt 1 ]; then
			echo -e "\nAny option after --uninstall will be ignored."
		fi

		# Remove the created .desktop files
		echo -e "\nThe .desktop files created by LaunchURLs will also be removed."
		rm -rf ~/.local/share/applications/LaunchURLs_DeskFiles

		# Get the path to the command and delete the file
		PATH=$(which LaunchURLs)
		echo -e "LaunchURLs was uninstalled succesfully!\n"
		exit 1;
		;;

    
    -h|--help)
        echo "Usage (Print the Manual)"
        exit 1;;

    --openAsApp)
		shift 1;

		# Make sure all the needed optiones were received
		# Application Name, URL, Web Page Name
		if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
		    echo "All the parameters are required";
		    exit 1;
		fi

		# Build the path to the temporal file
		filePath="/tmp/"${2// /_}"_WID"

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
	
	--closeWindow)
		shift 1;

		# Option to leave a background function waiting 
		# until the window is closed to update the file
		closeWindow $2 $3
		exit 1;
		;;

	--)
        shift
        break;;
    
    *) 
        echo "Unknown error while processing options";
        exit 1;;

    esac
done



# #! /bin/bash

# # Flags to know if the options where or not received
# appnameFlg=
# urlFlg=
# webpageFLG=

# # Global variables


# # Execute getopt on the arguments passed to this program
# PARSED_OPTIONS="$(getopt --n "Testing_GETOPT" -o a:u:p:h -l appname:,url:,url=:,pagename:,help -- "$@")"

# # If any bad argument was received
# [ $? -eq 0 ] || { 
#     echo "Incorrect options provided"
#     exit 1
# }

# # Needed when using getopt
# eval set -- "$PARSED_OPTIONS"
# unset PARSED_OPTIONS

# # Goes through all the options with a case and shifting when needing
# # If it is just the option, it needs to shift 1 but if there is also a
# # expected value, it needs to shift 2 and so on.
# while true; do
#     case $1 in

#     -a|--appname)
#         appnameFlg=1;
# 		1=$2;
#         filePath="/tmp/$2_WID.txt";
#         shift 2;;
    
#     -u|--url|--url=)
#         urlFlg=1;
#         2=$2;
#         shift 2;;
    
#     -p|--pagename)
#         webpageFLG=1;
#         3=$2;
#         shift 2;;
    
#     -h|--help)
#         echo "Usage (Print the Manual)"
#         exit 1;;

#     --)
#         shift
#         break;;
    
#     # Should not occur
#     *) 
#         echo "Unknown error while processing options";
#         exit 1;;

#     esac
# done

# if [[ -z "$urlFlg" || -z "$webpageFLG" || -z "$appnameFlg" ]]; then
#     echo "All the parameters are required"
#     exit 1
# fi


# # Function to open Notion and store the WID
# openURL () {

# 	# Store the number of previous instances of Notion
# 	GREP_RESULT=$(wmctrl -l | grep $3)
# 	PREV=$(echo $GREP_RESULT | awk '{print NF/4}')

# 	# Calculate the position of the new WID
# 	WID_NUM=$((4 * $PREV + 1))
# 	echo $WID_NUM

# 	# Open the Notion web page
#     brave-browser --app=$2 &

# 	# Wait 5 seconds for the page to load
# 	sleep 5s

# 	# And check if the page already load or not
# 	GREP_RESULT=$(wmctrl -l | grep $3) 

# 	# After that, check each 2 seconds if the page already load
# 	while [[ -z "$GREP_RESULT" ]];
# 	do 
# 		GREP_RESULT=$(wmctrl -l | grep $3) 
# 		sleep 2s; 
# 	done

#     # Save and append the new WID
# 	WID=$(echo $GREP_RESULT | awk -v var=$WID_NUM '{print $(var)}')
# 	echo $WID 

# 	# To append or overwritte the wid file
# 	if $1; then
# 		echo $WID >> $filePath;
# 	else
#     	echo $WID > $filePath;
# 	fi

# 	#nohup 
# 	/home/noecampos/.local/share/applications/LaunchURLS/CloseWindow.sh $WID $filePath
# }

# # Check if the file exists
# if test -f "$filePath"; then

# 	# If it is not empty...
# 	if [ -s "$filePath" ]; then

# 		# Get the WID stored on the file
# 		WID=$(cat "$filePath")

# 		# Check if WID is currently used with Notion opened as an app
# 		GREP_RESULT=$(wmctrl -l | grep $WID)
# 		if [ -z "$GREP_RESULT" ]
# 		# If the output is empty, it means there is no instance
# 		then
# 			# Open notion 
# 			openURL false

# 		# If grep returns something, it means the app is already opened
# 		else			
# 			# Bring the window to the front
# 			wmctrl -iR $WID
# 		fi
	
# 	# Check if the file is empty
# 	else
# 		# Open notion  
# 		openURL true
# 	fi

# # Create it and open Notion
# else
# 	# Open notion 
# 	openURL true
# fi

# sleep 10
