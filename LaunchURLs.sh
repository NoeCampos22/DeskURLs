#!/bin/bash
#
# Script to open URLs as apps and manage the windows,
# also easily create new .desktop files that opens URLs.

# TODO(NoeCampos22): Change the error messages to the STDERR and non errors to STDOUT

# TODO(NoeCampos22): Find how to get the username to build the absolute path
# TODO(NoeCampos22): Make them local variables on the main, since the other functions receive them as arguments
readonly DESKFILES_PATH='/home/noecampos/.local/share/applications/URLs_DeskFiles'
readonly TEMPORAL_PATH='/tmp/LaunchURLs'


#######################################
# Function that opens an URL as an app
# and store the window ID to manage it.
#
# Arguments:
#   $1: Path to the file /tmp/LaunchURLS/APP_WID
#   $2: URL to open
#	$3: Web page that will be open
#
#######################################
function open_url () {

	local grep_result;
	local number_prev;
	local wid_number;
	local wid;

	# TODO(NoeCampos22): If the 2 instances option is deprecated,
	# this logic should be removed
	
	# Store the number of previous instances of Notion
	grep_result=$(wmctrl -l | grep "$3")
	number_prev=$(echo "${grep_result}" | awk '{print NF/4}')

	# Calculate the position of the new WID
	wid_number=$((4 * number_prev + 1))

	# Open the ULR on Brave as an APP
	# TODO(NoeCampos22): Use the default browser (?)
    brave-browser --app="$2" &
	sleep 5s

	# And check if the page already load or not
	grep_result=$(wmctrl -l | grep "$3") 

	# If not, each 2 seconds check it
	while [[ -z "${grep_result}" ]];
	do 
		grep_result=$(wmctrl -l | grep "$3") 
		sleep 2s; 
	done

    # Store the new WID
	wid=$(echo "${grep_result}" | awk -v var="${wid_number}" '{print $(var)}')
	echo "${wid}" > "$1";
	
	# Leave on the background the close function
	nohup LaunchURLs --closeWindow "${wid}" "$1" $
}


#######################################
# Function that works on the background
# waiting for the window to be closed
# and update the WID file.
#
# Arguments:
#   $1: Windows ID
#   $2: Temporary file path
#######################################
function close_window() {

	local grep_result;

	# Check if the window keeps open
	grep_result=$(wmctrl -l | grep "$1") 

	# After that, check each 2 seconds if the page already load
	while [[ -n "${grep_result}" ]];
	do 
		grep_result=$(wmctrl -l | grep "$1") 
		sleep 2s; 
	done
	
	# Delete the WID
	awk "!/$1/" "$2" > temp && mv temp "$2"
}


main(){

	# Execute getopt on the arguments passed to this program
    if ! PARSED_OPTIONS="$(getopt --n "LaunchURLs" -o ynYNh -l asApp,asTab,closeWindow,deskfile,uninstall,help -- "$@")";
    # Check for a bad argument
    # TODO(NoeCampos22): Send error message to STDERR
	then 
        echo -e "\nInvalid options provided\n";
        exit 1;
    fi

	# Needed when using getopt
	eval set -- "$PARSED_OPTIONS"
	unset PARSED_OPTIONS

	local file_path;
	local wid;
	local grep_result;

	# Execute the solicited option
	while true; do
		case "$1" in

			--asApp)
				shift 1;

				# Make sure all the needed optiones were received
				# Application Name, URL, Web Page Name
				if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
					echo "All the parameters are required";
					exit 1;
				fi

				# TODO(NoeCampos22): Validate the received URL is valid

				# Build the path to the temporal file
				file_path="${TEMPORAL_PATH}/${2// /_}_WID"
				readonly file_path
				
				# TODO(NoeCampos22): Merge both conditions
				# Check if the file exists
				if test -f "${file_path}"; then

					# If it is not empty...
					if [ -s "${file_path}" ]; then

						# Look on the file if there is a WID
						wid=$(cat "${file_path}")
						grep_result=$(wmctrl -l | grep "${wid}")

						# If it is a non active window or an empty file..
						if [ -z "${grep_result}" ]; then

							# Open the URL
							open_url "${file_path}" "$3" "$4"

						else			
							# Or bring upfront the active window
							wmctrl -iR "${wid}"
						fi
					
					else
						# Open the URL 
						open_url "${file_path}" "$3" "$4"
					fi
				else
					# Open the URL
					open_url "${file_path}" "$3" "$4"
				fi
				exit 1;;

			--asTab)
				shift 1;
				
				# Open the url as another tab
				nohup brave-browser "$2" &
				exit 1;;
			
			--closeWindow)
				shift 1;

				# Option to leave a background function waiting 
				# until the window is closed to update the file
				close_window "$2" "$3"
				exit 1;;

			# TODO(NoeCampos22): Make a function of creating_deskfiles
			--deskfile)
				shift 1;

				local file_template;
				file_template="[Desktop Entry]\nVersion=1.0\nName={APP_NAME} \nComment=To open {APP_NAME}";

				# TODO(NoeCampos22): Validate the URLS are valid

				# Check if the launcher will open the URL as a tab 
				# or as a an app
				case "$1" in
					--asApp)

						# Make sure all the needed optiones were received
						# Application Name, URL, Web Page Name
						if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
							echo "All the parameters are required";
							exit 1;
						fi


						file_template="$file_template\nExec=bash -c \"LaunchURLs --asApp '{APP_NAME}' '{URL}' '{WEB_PAGE}'\""
						appname="${3// /_}"
						url="$4";
						webpage="$5"
						shift 1;;

					--asTab)

						# Make sure all the needed optiones were received
						# Application Name, URL, Web Page Name
						if [[ -z "$3" || -z "$4" ]]; then
							echo "All the parameters are required";
							exit 1;
						fi

						file_template="$file_template\nExec=bash -c \"LaunchURLs --asTab '{URL}'\""
						appname="${3// /_}"
						url="$4";
						shift 1;;

					--)
						echo "Manual";
						exit 1;;
				esac

				file_template="$file_template\nIcon=/usr/share/icons/{APP_NAME}\nEncoding=UTF-8\nTerminal=false"
				file_template="$file_template\nType=Application\nName[it]={APP_NAME}\nCategories=URL"

				# Replace the file_template placeholders to the real URL
				file_template="${file_template//\{APP_NAME\}/$appname}"
				file_template="${file_template//\{URL\}/$url}"
				file_template="${file_template//\{WEB_PAGE\}/$webpage}"

				echo -e "${file_template}" > "${DESKFILES_PATH}"/"${appname}".desktop;;


			# TODO(NoeCampos22): Make a function of uninstalling
			--uninstall)
				shift 1;

				local which_launch;

				if [ "$#" -gt 1 ]; then
					echo -e "\nAny option after --uninstall will be ignored."
				fi

				# Remove the created .desktop files
				echo -e "\nThe .desktop files created by LaunchURLs will also be removed."
				[[ -d "${DESKFILES_PATH}" ]] && rm -rf "${DESKFILES_PATH}";
				[[ -d "${TEMPORAL_PATH}" ]] && rm -rf "${TEMPORAL_PATH}";

				# Get the path to the command and delete the file
				which_launch=$(which LaunchURLs);
				
				sudo rm -rf "${which_launch}";
				
				echo -e "LaunchURLs was uninstalled succesfully!\n"
				exit 1;;

			-h|--help)
				echo "Usage (Print the Manual)"
				exit 1;;
			
			--) shift; break;;
			
			# TODO(NoeCampos22): Send error message to STDERR
			*) 
				echo "Unknown error while processing options";
				exit 1;;

		esac
	done

}


main "$@"