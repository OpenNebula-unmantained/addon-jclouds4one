#!/bin/bash 

# Create the cluster, if doesn't already exists
exist=`onecluster list | grep "JClouds\s"`
[ -z "$exist" ] && onecluster create JClouds

# Create the datastore, if doesn't already exists
exist=`onedatastore list | grep "JClouds\s"`
[ -z "$exist" ] && onedatastore create ds.conf

# Create the host, if doesn't already exists
exist=`onehost list | grep "JClouds\s"`
[ -z "$exist" ] && onehost create JClouds --im im_jclouds --vm vmm_jclouds --net dummy

# Install an example template, if doesn't already exists
exist=`onetemplate list | grep "JClouds\s"`
[ -z "$exist" ] && onetemplate create jclouds_template.txt

exit 0