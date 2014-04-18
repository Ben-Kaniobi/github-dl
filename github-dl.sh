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
#echo "HOST:       '$HOST'"
#echo "REPO:       '$REPO'"
#echo "BRANCH:     '$BRANCH'"
#echo "FOLDER:     '$FOLDER'"
#echo "FOLDERNAME: '$FOLDERNAME'"
#exit 0

# Create the folder
mkdir -p $FOLDERNAME
cd $FOLDERNAME

# Download GitHub html page of this folder
curl -3 -L $HOST/$REPO/tree/$BRANCH/$FOLDER > dl.temp
# Find and prepare file URLs
sed 's,",\n -3LO '"$HOST"',g' dl.temp | grep $REPO/blob/$BRANCH/$FOLDER > dl2.temp

# Download raw files
curl $(cat dl2.temp | sed 's/blob/raw/g')

# Remove temporary files
rm dl.temp dl2.temp