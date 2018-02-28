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

#Installing Docker-ce on centos7
sudo yum check-update &> /dev/null
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 &> /dev/null &
spin_wheel $! "Installing prerequisites for docker-ce"
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &> /dev/null &
spin_wheel $! "Adding yum repo for docker-ce"
sudo yum install docker-ce -y &> /dev/null &
spin_wheel $! "Installing docker-ce"

sudo systemctl start docker &> /dev/null &
spin_wheel $! "Starting docker-ce"
sudo systemctl status docker &> /dev/null &
spin_wheel $! "Checking docker-ce service"
sudo systemctl enable docker &> /dev/null &
spin_wheel $! "Enabling docker-ce service"
sudo usermod -aG docker $(whoami) &> /dev/null &
spin_wheel $! "Adding the present user to docker group"

# Check if docker with same name exists. If yes, stop and remove the docker container.
sudo docker ps -a | grep -i jenkins-server &> /dev/null
if [ $? == 0 ] ; then
  echo "Detected a container with name: jenkins-server. Deleting it..."
  sudo docker stop jenkins-server &> /dev/null &
  spin_wheel $! "Stopping existing Jenkins Docker"
  sudo docker rm jenkins-server &> /dev/null &
  spin_wheel $! "Removing existing Jenkins Docker"
fi

# Check if docker volume exists. If yes, remove the docker volume.
sudo docker volume inspect jenkins-volume &> /dev/null
if [ $? == 0 ] ; then
  echo "Detected a volume with name: jenkins-volume. Deleting it..."
  sudo docker volume rm jenkins-volume &> /dev/null &
fi

# Building the custom docker image from the jenkins-ce base image
cd ~/jazz-installer/installscripts
sudo docker build -t jenkins-ce-image -f dockerfiles/jenkins-ce/Dockerfile .

# Create the volume that we host the jenkins_home dir on dockerhost.
sudo docker volume create jenkins-volume &> /dev/null &
spin_wheel $! "Creating the Jenkins volume"

# Running the custom image
sudo docker run -d --name jenkins-server -p 8081:8080 -v jenkins-volume:/var/jenkins_home jenkins-ce-image

# Wainting for the container to spin up
sleep 60

# Grabbing initial password and populating jenkins default authfile
initialPassword=`sudo cat /var/lib/docker/volumes/jenkins-volume/_data/secrets/initialAdminPassword`
echo "initialPassword is: $initialPassword"
sudo docker exec -it jenkins-server bash -c "echo 'admin:$initialPassword' > /var/jenkins_home/cookbooks/jenkins/files/default/authfile"

# Running chef-client to execute cookbooks
sudo docker exec -u root -it jenkins-server sudo chef-client --local-mode -c /var/jenkins_home/chefconfig/jenkins_client.rb -j /var/jenkins_home/chefconfig/node-jenkinsserver-packages.json

# Once the docker image is configured, we will commit the image.
sudo docker commit -m "JazzOSS-Custom Jenkins container" jenkins-server jazzoss-jenkins-server

# The image jazzoss-jenkins-server is now ready to be shipped to and/or spinned in any docker hosts like ECS cluster/fargate etc.
