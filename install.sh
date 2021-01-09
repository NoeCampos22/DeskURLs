#! /bin/bash

# Global Variables
depFlg=
altPath=

# Execute getopt on the arguments passed to this program
PARSED_OPTIONS="$(getopt --n "LaunchURLs" -o ynYNh -l path:,help -- "$@")"

# If any bad argument was received
[ $? -eq 0 ] || { 
    echo -e "\nInvalid options provided\n"
    exit 1
}

# Needed when using getopt
eval set -- "$PARSED_OPTIONS"
unset PARSED_OPTIONS


installDependencies() {
	
    # Notify about the dependency and ask for permission
    echo -e '\nThis program has a dependcy on the package: wmctrl'

    # If the install dependencies option was not received...
    if [ ! -n "$depFlg" ]; then

        # Ask the user
        while true; do
        read -p "Do you want to install: wmctrl? (Y/n) " depFlg
            case $depFlg in
                [Yy]* )
                    break;;
                
                [Nn]* )
                    echo -e "\nCan not use LaunchURL without installing wmctrl\n";
                    exit;;

                * ) 
                    echo -e "\nPlease answer yes (y/Y) or no (n/N).\n";;
            esac
        done
    fi

    echo "";
    sudo apt-get install wmctrl -y; 
    echo "";
}

# Function that install the script on the specified path
# Or by default it will be moved to the /usr/bin/ directory
installScript() {

	# Build the current and target location
	CURR_LOC="$(pwd)/LaunchURLs.sh";
    TARG_LOC="/usr/bin/LaunchURLs";

	# Build the installation path
	[[ -n "$altPath" ]] && TARG_LOC="$altPath/LaunchURLs";

	# Move the file to the target location
	sudo cp $CURR_LOC $TARG_LOC

	# Create the directory for the .desktop file
    DeskfilesPath=~/.local/share/applications/URLs_DeskFiles
    [[ ! -d $DeskfilesPath ]] && mkdir $DeskfilesPath;

    # Create directory for temporary files
    TemporalPath=/tmp/LaunchURLs/
    [[ ! -d $TemporalPath ]] && mkdir $TemporalPath;


	echo -e "\nLaunchURLs was succesfully installed!\n"
}

# Execute the solicited option
case $1 in
    -y|-Y)
        depFlg=1;
        shift 1;;

    -h|--help)
        echo "Usage (Print the Manual)"
        exit 1;;
esac


# Execute the solicited option
while true; do
    case $1 in

        --path)
            # Check that the received path is to a valid directory
            if [[ ! -d $2 ]]; then
                echo -e "\nThe path must be to a valid directory.\n"
                exit 1;
            fi

            altPath=$2;
            shift 2;;
        
        --)
            shift;
            break;;
        
        *) 
            echo "Unknown error while processing options";
            exit 1;;

    esac
done


# Check if wmctrl is already installed or not
if ! command -v wmctrl >/dev/null 2>&1 ; then
    installDependencies
fi

# Call the function to move the script
installScript

exit 1;