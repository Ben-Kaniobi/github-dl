#!/bin/bash
#
# Arguments:
# $1: Repository link to GitHub repository (HTTPS, SSH, or Subversion)
# $2: Path to folder in repository, optional
# $3: Branch, optional

# Exit on error
set -o errexit


# Check number of arguments
if [ $# -lt 1 ]
then
	# Less than 1 arguments
	echo 'Missing argument'
	# Exit with error
	exit 1
fi

HOST=https://github.com
REPO=$1
FOLDER=$2
BRANCH=$3

# Make sure the format is as expected:
# Replace : with /
REPO=$(echo $REPO | sed 's/:/\//g')
# Remove www.
REPO=$(echo $REPO | sed 's/www\.//g')
# Remove everything until after .com/
REPO=$(echo $REPO | sed 's/^[^\.]*.com\///g')
# Remove .git at end
REPO=$(echo $REPO | sed 's/\.git$//g')
# Remove / at beginning and end
FOLDER=$(echo $FOLDER | sed 's/^\///g')
FOLDER=$(echo $FOLDER | sed 's/\/$//g')
# Check if FOLDER has length 0
if [ -z $FOLDER ]
then
	# Length is 0 (argument was / or not specified) --> root directory, use the distro name
	FOLDERNAME=${REPO##*/}
else
	# Length is not zero, get folder name
	FOLDERNAME=${FOLDER##*/}
fi
# Check if BRANCH has length 0
if [ -z $BRANCH ]
then
	# Length is 0 (argument was not specified), use master branch
	BRANCH='master'
fi

# Varibles should now be in this format:
# HOST        https://github.com
# REPO        user/repo_name
# BRANCH      master
# FOLDER      dir/subdir/folder
# FOLDERNAME  folder
echo
#echo "HOST:       '$HOST'"
echo "REPO:       '$REPO'"
echo "BRANCH:     '$BRANCH'"
echo "FOLDER:     '$FOLDER'"
#echo "FOLDERNAME: '$FOLDERNAME'"
# Prompt 
echo
echo "Continue?"
choice1="Yes, include subfolders"
choice2="Yes, single folder"
choice3="No"
select result in "$choice1" "$choice2" "$choice3"
do
	case $result in
		$choice1 ) RECURSIVE=1; break;;
		$choice2 ) RECURSIVE=0; break;;
		$choice3 ) exit;;
	esac
done

# Define the recursive download function
recursive_download() {
	# Create the folder
	mkdir -p $FOLDERNAME
	cd $FOLDERNAME

	# Download GitHub html page of this folder
	curl -3 -L $HOST/$REPO/tree/$BRANCH/$FOLDER > tmp1
	# Find and prepare file URLs
	sed 's,",\n -3LO '"$HOST"',g' tmp1 | grep $REPO/blob/$BRANCH/$FOLDER > tmp2

	# Download raw files
	curl $(cat tmp2 | sed 's/blob/raw/g')

	if [ $RECURSIVE -ge 1 ]
	then
		# Find subfolder URLs
		sed 's/"/\n/g' tmp1 | grep tree/$BRANCH/$FOLDER/ | sed 's,'"\/$REPO\/tree\/$BRANCH\/"',,g' > tmp2

		# Recursively call this function for every line
		while read line           
		do
			FOLDER=$line
			FOLDERNAME=${FOLDER##*/}
			recursive_download
		done <tmp2
	fi
	
	# Remove temporary files
	rm -f tmp1 tmp2
	
	# Leave subfolder
	cd ..
}

# Call the recursive download function
recursive_download