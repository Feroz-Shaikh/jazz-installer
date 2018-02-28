# Base Image and maintainer info
FROM jenkins/jenkins:lts
MAINTAINER JazzOSS Team

# Declaring ARGS and ENV
ARG cookbooksDirArg=
ENV cookbooksDir=${cookbooksDirArg}

# Switching to root to configure the image with system packages
USER root
RUN apt-get update && apt-get install -y vim curl

# Copying plugins list. Downlading and installing plugins from Jenkins PluginsManager
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Copy the chef recipes and configs
COPY ../../cookbooks/* ~/cookbooks/
COPY ../../chefconfig/* ~/chefconfig/

# Copy and run the bootstrap script
COPY bootstrap.sh ~/
RUN ~/bootstrap.sh

# Switching back to Jenkins user for safety
USER jenkins
