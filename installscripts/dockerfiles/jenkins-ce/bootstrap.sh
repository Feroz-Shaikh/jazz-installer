#!/bin/bash

# Installing chefclient
curl -sL -o chefdk.deb https://packages.chef.io/files/stable/chefdk/2.4.17/ubuntu/16.04/chefdk_2.4.17-1_amd64.deb
dpkg -i chefdk.deb

# Installing pip
curl -sL -O https://bootstrap.pypa.io/get-pip.py && python get-pip.py
chmod -R o+w /usr/lib/python2.7/* /usr/bin/
