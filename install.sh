#!/bin/bash
#
# Install the LaunchURL script and make the needed directories


#######################################
# Function to display the help message, 
# when the option is received or when an 
# error occurs.
#######################################
function display_help () {
# Using a here doc with standard out.
cat <<-END
Usage: install.sh [OPTIONS]
  A small program to facilate the installation of the LaunchURL.sh script and
  make the directory to store the .desktop files. To work properly, this script 
  must be executed on the same directory where is the LaunchURLs.sh file.

  Syntax: install.sh [[[-y|-Y] | [-n|-N]] [--path DIRECTORY] | [-h|--help]]

  Options:
      -y,  -Y             Install dependencies without asking.
      -n,  -N             Not install dependencies.
              --path      Specify the installation path.
      -h,     --help      Display this help message.

END
}


#######################################
# Function to print an error message
#
# Arguments:
#   All the messages
#
#######################################
err() {
  echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $* \n" >&2
}


#######################################
# Check if the dependency is already installed or 
# asks the user for permission to install it.
#
# Arguments:
#   $1: Flag to install dependency without asking.
#
# Inputs:
#   [YyNn] To give or not permission to install a dependency
#
# Outputs:
#   STDOUT:
#       - Notify of the dependency
#       - Little menu that asks for permission to install packages
#######################################
function install_dependencies() {
	
    echo -e '\nThis program has a dependcy on the package: wmctrl'

    # If the -Yy option was not received...
    if [ -z "${1}" ]; then

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

    # Install dependency
    sudo apt-get install wmctrl -y; 
    echo "";
}


#######################################
# Moves the LaunchURLs script to the /usr/bin/ dir or 
# to the directory indicated by the user. Also, creates needed directories.
#
# Arguments:
#   - $1 is an alternative path to install the script or empty
#
# Outputs:
#   STDOUT:
#       - Success message
#   STDERR:
#       - Error trying to copy the script
#######################################
function install_script() {

	local current_path;
    local target_path;
    local deskfiles_path;

	# Build the current and target location
    current_path="$(pwd)/LaunchURLs.sh";
    target_path="/usr/bin/LaunchURLs";

    # TODO(NoeCampos22): Validate the path is on the $PATH variable
    # or at least notify that the target directory must be on it.

    # If needed, update to the specified directory
	[[ -n "${1}" ]] && target_path="${1}/LaunchURLs";

	# Copy the script to the target location
    if ! sudo cp "${current_path}" "${target_path}";
    then
        err "Unable to copy LaunchURLs to ${target_path}";
        exit 1;
    fi

	# Create the directory for the .desktop (using the env var HOME)
    deskfiles_path="$HOME/.local/share/applications/URLs_DeskFiles"
    [[ ! -d "${deskfiles_path}" ]] && mkdir "${deskfiles_path}";

	echo -e "\nLaunchURLs was succesfully installed!\n"
}


#######################################
# MAIN FUNCTION
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

    local dependencies_flag;
    local alternative_path;

    # Execute getopt on the arguments passed to this program
    if ! PARSED_OPTIONS="$(getopt --n "LaunchURLs" -o ynYNh -l path:,help -- "$@")";
    # Check for a bad argument
    then 
        err "Invalid options provided";
        display_help
        exit 1;
    fi

    eval set -- "${PARSED_OPTIONS}"
    unset PARSED_OPTIONS

    # Check for possible first options
    case "$1" in
        -y|-Y) dependencies_flag=1; shift;;
        -h|--help) display_help; exit 1;;
    esac

    # Check for the others options
    while true; do
        case "$1" in

            --path)
                # Check that the received path is to a valid directory
                if [[ ! -d "$2" ]]; then
                    err "The path must be to a valid directory."
                    exit 1;
                fi

                alternative_path="$2";
                shift 2;;
            
            --) shift; break;;
            
            *) err "Unknown error while processing options"; display_help; exit 1;;

        esac
    done

    # Check if wmctrl is already installed or not
    if ! command -v wmctrl >/dev/null 2>&1; then
        install_dependencies "${dependencies_flag}"
    fi

    # Call the function to install the script
    install_script "${alternative_path}"
    exit 1;
}

main "$@";
exit 1;