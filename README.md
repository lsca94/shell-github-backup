# shell-github-backup
The shell script included in this repo is designed to backup your GitHub repositories.
This is to protect repositories from accidental deletion or if you don't fully trust GitHub with your code.
The script can be run using daily using crontab or any other task scheduler.

The script downloads the backups as a *.tar archive. The archive contains the content of the .git folders of all your repos.

## Prerequirements
The command-line tool jq is needed to run this script. Installation instruction can be found [here](https://stedolan.github.io/jq/).

To use the script a GitHub user and an personal access token with `repo` and `admin:org` permissions is needed. The Token can be generated following these [instructions](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).

## Usage


### Examples
Create and download backup of all repositories
```
# gh-backup -u [username] -t [Personal Access Token] -o [backup folder]
```

Create and download backup of all repositories and store 30 copies of it
```
# gh-backup -u [username] -t [Personal Access Token] -o [backup folder] -r 30
```


## Restore Backup
To restore a backup just follow these four easy steps

1. Unpack the .tar archive  
```
# tar -xzvf ghb-[timestamp].tar
```

2. Copy the '[repository].git' folder to the desired restore location  
```
# cp repositories/[user]/[repository].git /restore/to/this/folder
```

3. Go to the restore folder and change the name of the '[repository].git' folder to '.git'  
```
# cd /restore/to/this/folder
# mv [repository].git .git
```

4. Reinitalize the Git repository and restore to the most recent commit  
```
# git init
# git reset --hard HEAD
```
