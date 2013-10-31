#!/bin/bash 

cluster="JClouds"
datastore="JClouds"
host="JClouds"
template="JClouds"

# Create the cluster, if doesn't already exists
exist=`onecluster list | grep "$cluster\s"`
if [ -z "$exist" ]; then
	onecluster create $name
	echo "Cluster $cluster successfully created."
fi

# Create the datastore, if doesn't already exists
exist=`onedatastore list | grep "$datastore\s"`
if [ -z "$exist" ]; then
	onedatastore create ds.conf
	echo "Datastore $datastore successfully created."
fi

# Create the host, if doesn't already exists
exist=`onehost list | grep "$host\s"`
if [ -z "$exist" ]; then
	onehost create $host --im im_jclouds --vm vmm_jclouds --net dummy --cluster $cluster
	echo "Host $name successfully created."
fi

# Install an example template, if doesn't already exists
exist=`onetemplate list | grep "$name\s"`
if [ -z "$exist" ] then
	onetemplate create jclouds_template.txt
	echo "Template $name successfully created."
fi

exit 0