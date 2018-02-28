#!/bin/bash

# Installing chefclient & pip
sudo bash ~/cookbooks/installChef.sh
sudo curl -O https://bootstrap.pypa.io/get-pip.py&& sudo python get-pip.py
sudo chmod -R o+w /usr/lib/python2.7/* /usr/bin/

# Running chef-client to execute cookbooks
sudo chef-client --local-mode -c ~/chefconfig/jenkins_client.rb -j ~/chefconfig/node-jenkinsserver-packages.json
