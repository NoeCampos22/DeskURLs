#!/bin/bash
#
# Script to open URLs as apps and manage the windows,
# also easily create new .desktop files that opens URLs.


readonly DESKFILES_PATH="$HOME/.local/share/applications/URLs_DeskFiles"
readonly TEMPORAL_PATH="/tmp/LaunchURLs"


#######################################
# Function to display the help message, 
# when the option is received or when an 
# error occurs.
#######################################
function display_help () {
# Using a here doc with standard out.
cat <<-END
Usage: LaunchURLs OPTIONS
  Script to create desktop files that open URLs in Brave (currently, 
  it only works with Brave Browser) as another tab or as an application. 

  Syntax: LaunchURLs [ --asApp ARGS | --asTab URL | 
                       --deskfile [--asApp ARGS | --asTab ARGS] | 
                       [-h|--help] | --uninstall ]

  Options:
      --asApp       Opens an URL as an application, it will keep track 
                    of the window, to avoid opening multiple instances 
                    of it and simply bringing to the front the initial 
                    window when the file is run multiple times. 

                    It requires three arguments: Application Name, URL 
                    and Window Name.

                    Option example: 
                        LaunchURLs --asApp "Github" "https://github.com" "Github - Brave"

                    To read a description of this arguments, read 
                    the --deskfile option help section.
        
      --asTab       Just opens the passed URL in a new Brave Browser.
                    
                    Option example: 
                        LaunchURLs --asTab "https://github.com"

                    To read a description of this arguments, read 
                    the --deskfile option help section.

      --deskfile    Make a .desktop file that open a URL. After this 
                    option it is need to specify if it will be as an 
                    app or as a tab and some arguments.
                      
                    Required option and arguments:
                      --asApp "Application Name" "URL" "Window Name"
                      --asTab "Application Name" "URL"

                    * Application Name is how you want the desktop file 
                    to be named. Ex: If it is to open the Github portal, 
                    the application name could be just "Github".

                    * Window Name is how the window is named after loading 
                    the URL. To get this, you can run the command "wmctrl -l", 
                    open the desired URL on a Brave tab, go again to 
                    the terminal and run again "wmctrl -l" and take note
                    of the new window name.

                    Option examples:
                      LaunchURLs --deskfile --asApp "Github" "https://github.com" "Github - Brave"
                      LaunchURLs --deskfile --asTab "Github" "https://github.com"

                    NOTE: For the APP.deskfile to have an empty or 
                    default icon, you need to download a desired
                    SVG or PNG file with the exact same name as the 
                    Application Name and store it on the 
                    /usr/share/icons/ dir.

      --uninstall   Remove the LaunchURL command and delete the 
                    directory where the .desktop files are.

  -h, --help        Display this help message.

END
}


#######################################
# Function to print an error message
#
# Arguments:
#   The messages
#
#######################################
err() {
  echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $* \n" >&2
}

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

	# TODO(NoeCampos22): This logic is kept due to the future possibility 
	# of launching URLs as apps but with the option of having mulitple instances
	
	# Store the number of previous instances of the page
	grep_result=$(wmctrl -l | grep "$3")
	#number_prev=$(echo "${grep_result}" | awk '{print NF/4}')
	number_prev=$(echo "${grep_result}" | awk '{print NF}')

	# Calculate the position of the new WID
	# wid_number=$((4 * number_prev + 1))
	wid_number=$((number_prev + 1))

	# Open the ULR on Brave as an APP
	# TODO(NoeCampos22): Valid the received url is valid (?)
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

	# TODO(NoeCampos22): Change from many files, to just one that store all the WIDs.
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

#######################################
# Make a .desktop file that openes the received URL
#
# Globals:
#   DEPENDENCIES_FLAG
#
# Arguments:
#	All
#
# Outputs:
#   STDOUT:
#       - Successful creation message
#   STDERR:
#       - Missing a parameter message and the manual
#######################################
function make_deskfile(){
	
	local file_template;
	local command_temp;
	local as_app;

	# TODO(NoeCampos22): Add the option of adding an extra option to pass a URL to the desired icon
	# and download/move itself.

	# .desktop file template
	file_template="[Desktop Entry]\nVersion=1.0\nName={APP_NAME} \nComment=To open {APP_NAME}\n{COMMAND}";
	file_template="$file_template\nIcon=/usr/share/icons/{APP_NAME}\nEncoding=UTF-8\nTerminal=false";
	file_template="$file_template\nType=Application\nName[it]={APP_NAME}\nCategories=URL";

	# TODO(NoeCampos22): Validate the URLS are valid
	# Check if the launcher will open the URL as a tab or as a an app
	case "$1" in
		--asApp)
			shift 1;
			as_app=1;
			command_temp="Exec=bash -c \"LaunchURLs --asApp '{APP_NAME}' '{URL}' '{WEB_PAGE}'\"";;

		--asTab)
			shift 1;
			command_temp="Exec=bash -c \"LaunchURLs --asTab '{URL}'\"";;

		--)
			err "It is necessary to specify if it will open as an App or as a Tab";
			display_help;
			exit 1;;
	esac

	# Make sure the application name, url were received
	if [[ -z "$2" || -z "$3" ]]; then
		err "All the parameters are required";
		display_help;
		exit 1;
	fi

	# TODO(NoeCampos22): Make that the script get this value by itself 
	# (opening the url and checking the wmctrl list)
	# Make sure web page name received
	if [[ -n "${as_app}" && -z "$4" ]]; then
		err "All the parameters are required2";
		display_help;
		exit 1;
	fi

	# Replace the file_template placeholders to the real values
	file_template="${file_template//\{COMMAND\}/$command_temp}";
	file_template="${file_template//\{APP_NAME\}/${2// /_}}"
	file_template="${file_template//\{URL\}/$3}"
	file_template="${file_template//\{WEB_PAGE\}/$4}"

	# Write the desktop file
	echo -e "${file_template}" > "${DESKFILES_PATH}"/"${2// /_}".desktop;
}


#######################################
# Function that uninstall the script. 
# Delete the file on /usr/bin/, the temporary directory
# and the .desktop file
#
# Globals:
#   DEPENDENCIES_FLAG
#	TEMPORAL_PATH
#
# Outputs:
#   STDOUT:
#       - Uninstallation succesful message
#   STDERR:
#       - Message if the script received more than the uninstall option
#######################################
function uninstall(){
	
	local which_launch;

	# Remove the created .desktop and temporary files
	echo -e "\nThe .desktop files created by LaunchURLs will also be removed."
	[[ -d "${DESKFILES_PATH}" ]] && rm -rf "${DESKFILES_PATH}";
	[[ -d "${TEMPORAL_PATH}" ]] && rm -rf "${TEMPORAL_PATH}";

	# Get the path to the command and delete the file
	which_launch=$(which LaunchURLs);
	sudo rm -rf "${which_launch}";
	
	echo -e "LaunchURLs was uninstalled succesfully!\n";
}


#######################################
# MAIN FUNCTION
#
# Globals:
#   DESKFILES_PATH
#   TEMPORAL_PATH
#
# Arguments:
#   All
#
# Outputs:
#   STDOUT:
#       - Usage manual
# 
#   STDERR:
#       - Invalid option message
#       - Invalid path
#       - Unknown error while processing options
#######################################
main(){

	# Execute getopt on the arguments passed to this program
    if ! PARSED_OPTIONS="$(getopt --n "LaunchURLs" -o ynYNh -l asApp,asTab,closeWindow,deskfile,uninstall,help -- "$@")";
    # Check for a bad argument
	then 
        err "Invalid options provided";
		display_help;
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
					err "All the parameters are required";
					display_help;
					exit 1;
				fi

				# Check if the temporary directory exists
    			[[ ! -d "${TEMPORAL_PATH}" ]] && mkdir "${TEMPORAL_PATH}";

				# Build the path to the temporal file
				file_path="${TEMPORAL_PATH}/${2// /_}_WID"
				readonly file_path

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

				exit 1;;

			--asTab) 

				# Make sure the URL was received
				if [[ -z "$3" ]]; then
					err "The URL parameter is required";
					display_help;
					exit 1;
				fi
			
				nohup brave-browser "$3" & 
				exit 1;;
			
			--closeWindow) close_window "$3" "$4"; exit 1;;

			--deskfile) shift 1; make_deskfile "$@"; exit 1;;

			--uninstall) uninstall; exit 1;;

			-h|--help)
				display_help;
				exit 1;;
			
			--)	shift; break;;
			
			*) err "Unknown error while processing options"; display_help; exit 1;;

		esac
	done

}


main "$@"
display_help;
exit 1;