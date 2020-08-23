# devsecopscli

this file has been copied to /home/devops and afterwards the ownership and access rights set to only devops (for example for ssh stuff important)

change your docker start command and add the environment variable to your source folder:
    
    -e USER_HOME_COPYSOURCE=/some/path/mountedinto -v local/dir:/some/path/mountedinto

all files will be recursively copied into your /home/devops directory and ownership/access rights will be
- devops:devops
- 600 for all files
- 700 for all *.sh files
