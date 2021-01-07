#! /bin/bash

# Flags to know if the options where or not received
installFlg=
installDependencies=

# Global variables that store option values
alternativeInstPath=

# Needed extra global variables

# Execute getopt on the arguments passed to this program
PARSED_OPTIONS="$(getopt --n "LaunchURLs" -o ynYNp:h -l install,uninstall,path:,help -- "$@")"

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

	# Notify about the dependency and ask for permission
	echo 'This program has a dependcy on the package: wmctrl'

	# Check if wmctrl is already installed or not
	if ! command -v wmctrl >/dev/null 2>&1 ; then

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
				echo -e "\nCan not install LaunchURL without wmctrl\n";
				exit;;
		esac
		
	else
		echo -e "wmctrl is already installed\n";
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

    --)
        shift
        break;;
    
    *) 
        echo "Unknown error while processing options";
        exit 1;;

    esac
done