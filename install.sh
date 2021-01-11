#!/bin/bash
#
# Install the LaunchURL script and make the needed directories

# TODO(NoeCampos22): Change the error messages to the STDERR and non errors to STDOUT

# TODO(NoeCampos22): Change Global variables to Local on the main function
# and send them as arguments to the rest of functions
# Global Variables
DEPENDENCIES_FLAG=
ALTERNATIVE_PATH=


#######################################
# Check if the needed dependecy is already installed
# or installs it after the user confirmation.
#
# Globals:
#   DEPENDENCIES_FLAG
#
# Inputs:
#   [YyNn] to give or not permission to install dependencies
#
# Outputs:
#   STDOUT:
#       - Notify of the dependency
#       - Little menu that asks for permission to install packages
#######################################
function install_dependencies() {
	
    echo -e '\nThis program has a dependcy on the package: wmctrl'

    # If the -Yy option was not received...
    if [ -z "${DEPENDENCIES_FLAG}" ]; then

        # Asks for permission to install packages
        while true; do
            read -rp "Do you want to install: wmctrl? (Y/n) " YN
            
            case "${YN}" in
                [Yy]* ) break;;
                [Nn]* ) echo -e "\nCan not use LaunchURL without installing wmctrl\n"; exit;;
                * ) echo -e "\nPlease answer yes (y/Y) or no (n/N).\n";;
            esac
        done
    fi

    sudo apt-get install wmctrl -y; 
    echo "";
}


#######################################
# Moves the LaunchURLs script to /usr/bin/ dir or 
# to the given path by the user. Also, creates needed directories.
#
# Globals:
#   ALTERNATIVE_PATH
#
# Outputs:
#   STDOUT:
#       Success message
#######################################
function install_script() {

	local CURRENT_PATH;
    local TARGET_PATH;
    local DESKFILES_PATH;
    local TEMPORAL_PATH;

	# Build the current and target location
    CURRENT_PATH="$(pwd)/LaunchURLs.sh";
    TARGET_PATH="/usr/bin/LaunchURLs";

    # If needed, update to the specified directory
	[[ -n "${ALTERNATIVE_PATH}" ]] && TARGET_PATH="${ALTERNATIVE_PATH}/LaunchURLs";

	# Copy the script to the target location
    if ! sudo cp "${CURRENT_PATH}" "${TARGET_PATH}";
    then
        echo "Unable to copy LaunchURLs to ${TARGET_PATH}" >&2;
        exit 1;
    fi

	# Create the directory for the .desktop and for temporary files
    # TODO(NoeCampos22): Find how to get the username to build the absolute path
    DESKFILES_PATH='/home/noecampos/.local/share/applications/URLs_DeskFiles'
    TEMPORAL_PATH='/tmp/LaunchURLs/'
    [[ ! -d "${DESKFILES_PATH}" ]] && mkdir "${DESKFILES_PATH}";
    [[ ! -d "${TEMPORAL_PATH}" ]] && mkdir "${TEMPORAL_PATH}";

	echo -e "\nLaunchURLs was succesfully installed!\n"
}


#######################################
# MAIN FUNCTION
#
# Globals:
#   DEPENDENCIES_FLAG 
#   ALTERNATIVE_PATH
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
main() {


    # Execute getopt on the arguments passed to this program
    if ! PARSED_OPTIONS="$(getopt --n "LaunchURLs" -o ynYNh -l path:,help -- "$@")";
    # Check for a bad argument
    # TODO(NoeCampos22): Send error message to STDERR
    then 
        echo -e "\nInvalid options provided\n";
        exit 1;
    fi

    eval set -- "${PARSED_OPTIONS}"
    unset PARSED_OPTIONS

    # Check for possible first options
    case "$1" in
        -y|-Y) DEPENDENCIES_FLAG=1; shift;;
        -h|--help) echo "Usage (Print the Manual)"; exit 1;;
    esac

    # Check for the others options
    while true; do
        case "$1" in

            --path)
                # TODO(NoeCampos22): Send error message to STDERR
                # Check that the received path is to a valid directory
                if [[ ! -d "$2" ]]; then
                    echo -e "\nThe path must be to a valid directory.\n"
                    exit 1;
                fi

                ALTERNATIVE_PATH="$2";
                shift 2;;
            
            --)
                shift;
                break;;
            
            # TODO(NoeCampos22): Send error message to STDERR
            *) 
                echo "Unknown error while processing options";
                exit 1;;

        esac
    done

    readonly DEPENDENCIES_FLAG
    readonly ALTERNATIVE_PATH


    # Check if wmctrl is already installed or not
    if ! command -v wmctrl >/dev/null 2>&1; then
        install_dependencies
    fi

    # Call the function to install the script
    install_script
    exit 1;
}

main "$@"