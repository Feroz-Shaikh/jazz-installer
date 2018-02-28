# Base Image and maintainer info
FROM jenkins/jenkins:lts
MAINTAINER JazzOSS Team

# Switching to root to configure the image with system packages
USER root
RUN apt-get update && apt-get install -y vim curl sudo

# Copying plugins list. Downlading and installing plugins from Jenkins PluginsManager
COPY dockerfiles/jenkins-ce/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Copy the chef recipes, chefconfigs and bootstrap script
COPY --chown=jenkins:jenkins cookbooks  /var/jenkins_home/cookbooks
COPY --chown=jenkins:jenkins chefconfig /var/jenkins_home/chefconfig
COPY --chown=jenkins:jenkins dockerfiles/jenkins-ce/bootstrap.sh /var/jenkins_home/bootstrap.sh

# Creating node_path directory
RUN mkdir /var/jenkins_home/node

# Setting execute bit and executing the bootstrap script
RUN chmod 777 /var/jenkins_home/bootstrap.sh
RUN bash /var/jenkins_home/bootstrap.sh

# Switching back to Jenkins user for safety
USER jenkins

# Expose the jenkins port
EXPOSE 8081
