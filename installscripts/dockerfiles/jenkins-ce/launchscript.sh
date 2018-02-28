#Spin wheel for visual effects
spin_wheel()
{
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    NC='\033[0m'

    pid=$1 # Process Id of the previous running command
    message=$2
    spin='-\|/'
    printf "\r$message...."
    i=0

    while ps -p $pid > /dev/null
    do
        #echo $pid $i
        i=$(( (i+1) %4 ))
        printf "\r${GREEN}$message....${spin:$i:1}"
        sleep .05
    done

    wait "$pid"
    exitcode=$?
    if [ $exitcode -gt 0 ]
    then
        printf "\r${RED}$message....Failed${NC}\n"
        exit
    else
        printf "\r${GREEN}$message....Completed${NC}\n"

    fi
}

# Check if docker with same name exists. If yes, stop and remove the docker container.
sudo docker ps -a | grep -i jenkins-server &> /dev/null
if [ $? == 0 ] ; then
  echo "Detected a container with name: jenkins-server. Deleting it..."
  sudo docker stop jenkins-server &> /dev/null &
  spin_wheel $! "Stopping existing Jenkins Docker"
  sudo docker rm jenkins-server &> /dev/null &
  spin_wheel $! "Removing existing Jenkins Docker"
fi

# Building the custom docker image from the jenkins-ce base image
sudo docker build -t jenkins-server .



# Script to get the list of plugins installed in jenkins
# JENKINS_HOST=admin:f14c2a4f44ce46d7a8ef010cb28efff9@54.86.125.198:8081
# curl -sSL "http://$JE NKINS_HOST/pluginManager/api/xml?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins" | perl -pe 's/.*?<shortName>([\w-]+).*?<version>([^<]+)()(<\/\w+>)+/\1 \2\n/g'|sed 's/ /:/'
