#!/bin/bash

#shows help information
show_help () {
cat <<EOF
Usage: ${0##*/} -o backup directory -u github_user -t  github_token [-h] [-R retry] [-t timeout] 
Use this script to backup GitHub repositories.
        -h                          display this help and exit
        -u  github_user             GitHub username of user with repos to backup
        -t  github_token            GitHub API token to access API with specified user
        -o  backup_directory        specify backup target directory to store backups archives
        -r  retention               number of backup archives to store before deleting oldest files (default 7)
        -R  retries                 number of retries before script should not retry to download backup archive from GitHub (default 5)
        -T  timeout                 timeout between retries in seconds (default 30 sec.)
EOF
}

TIMEOUT_ARCHIVE_CHECK_SEC=30
REPEAT_ARCHIVE_CHECK=5
BACKUP_RETENTION=7

#set flag parameters
while getopts "hu:R:T:o:t:r:" opt; do
    case $opt in
        h) 
            show_help
            exit 0
            ;;
        u) 
            USERNAME=$OPTARG
            ;;
        R) 
            REPEAT_ARCHIVE_CHECK=$OPTARG
            ;;
        T) 
            TIMEOUT_ARCHIVE_CHECK_SEC=$OPTARG
            ;;
        o)
            TARGET_DIRECTORY=$OPTARG
            ;;
        t)
            TOKEN=$OPTARG
            ;;
        r)
            BACKUP_RETENTION=$OPTARG
            ;;
    esac
done

#checks if mandatory flags are set
if [ -z ${USERNAME+x} ]
then
echo 'Mandatory parameter -u is missing'
exit 1
fi

if [ -z ${TOKEN+x} ]
then
echo 'Mandatory parameter -t is missing'
exit 1
fi

if [ -z ${TARGET_DIRECTORY+x} ]
then
echo 'Mandatory parameter -o is missing'
exit 1
fi

#get all github repos of user
echo 'Get list of all GitHub repos of user'
GITHUB_REPOS=$(curl \
    -u $USERNAME:$TOKEN \
    -H "Accept: application/vnd.github.v3+json" \
    -s \
    'https://api.github.com/user/repos?per_page=100&affiliation=owner' | jq -r '[.[] | .full_name]'
    )

#create archive
echo 'Creating Backup Archive'
MIGRATON_URL=$(curl \
	-u $USERNAME:$TOKEN \
	-X POST \
	-H "Accept: application/vnd.github.v3+json" \
	-d '{"repositories":'"$GITHUB_REPOS"'}' \
	 -s \
	https://api.github.com/user/migrations | jq -r '.url')

MIGRATION_STATUS=
WHILE_RUN=0

#wait for archive to be created
echo 'Waiting for Backup Archive to be created '
while [[ "$MIGRATION_STATUS" != "exported" && $WHILE_RUN -lt $REPEAT_ARCHIVE_CHECK ]]
do
    ((WHILE_RUN++))

    MIGRATION_STATUS=$(curl \
        -u $USERNAME:$TOKEN \
        -H "Accept: application/vnd.github.v3+json" \
        -s \
        $MIGRATON_URL | jq -r ".state")
    
    if [ "$MIGRATION_STATUS" != "exported" ]
    then
        sleep $TIMEOUT_ARCHIVE_CHECK_SEC
    fi
    
done

#download archive
echo 'Download Backup Archive'
DOWNLOAD_URL=$(curl \
  -u $USERNAME:$TOKEN \
  -H "Accept: application/vnd.github.v3+json" \
  -s \
  ${MIGRATON_URL}/archive)
  
curl -s $DOWNLOAD_URL --output ${TARGET_DIRECTORY}/ghb-$(date +%s).tar

#backup retention cleanup

NUMBER_OF_BACKUPS=$(ls -1 ${TARGET_DIRECTORY}/ghb-*.tar | wc -l) 

if [ $NUMBER_OF_BACKUPS -gt  $BACKUP_RETENTION ]
then
    echo 'Cleanup Backups according to backup policy'
    DIFF=$((NUMBER_OF_BACKUPS - BACKUP_RETENTION))
    rm $(ls -1 ${TARGET_DIRECTORY}/ghb-*.tar | head -n ${DIFF})
fi