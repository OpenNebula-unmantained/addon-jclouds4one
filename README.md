# Hybrid jclouds

## Description

Hybrid JClouds is a Driver for Opennebula that provides a way to use providers that can be accessed by the [JClouds](<http://jclouds.incubator.apache.org/>) library. It is made for Command Line Interfaces (CLIs) developed on top of the JClouds library (for example [jclouds-cli](<https://github.com/jclouds/jclouds-cli>)), but it is generic enough to be used with a generic CLI made on top of JClouds, configuring properly the parsing of CLI responses in the `jclouds_driver.rb`.

## Development

To contribute bug patches or new features, you can use the github Pull Request model. It is assumed that code and documentation are contributed under the Apache License 2.0. 

More info:
* [How to Contribute](http://opennebula.org/software:add-ons#how_to_contribute_to_an_existing_add-on)
* Support: [OpenNebula user mailing list](http://opennebula.org/community:mailinglists)
* Development: [OpenNebula developers mailing list](http://opennebula.org/community:mailinglists)
* Issues Tracking: Github issues

## Authors

* Leader: Cesare Rossi (cesare.rossi@terradue.com)
* Other: Emmanuel Mathot (emmanuel.mathot@terradue.com)

## Compatibility

This add-on is compatible with OpenNebula 4.2.

## Features

Implements Hybrid Cloud, to support Cloud Bursting, with the ability to work with a variety of Cloud provider, such as:

* Amazon AWS
* Azure Management
* Cloud Stack
* ElasticHosts
* GleSYS
* Go2Cloud
* GoGrid
* HP Cloud Services
* Ninefold
* OpenStack

The updated and complete list can be found here: http://jclouds.incubator.apache.org/documentation/userguide/

## Limitations

It is not tested with all the listed providers, so contributions in this way are appreciated.

## Requirements

* RHEL-based OS

## Installation

Install the package by:

	$ rpm -Uvh jclouds4one.rpm

## Configuration

Configure the Opennebula installation, adding the Jclouds Information Manager, Virtual Machine Manager and the Transfer Manager. It can be done adding to the file `/etc/one/oned.conf` the following lines:

	IM_MAD = [
    	name       = "im_jclouds",
    	executable = "one_im_jclouds",
    	arguments  = "im_jclouds/im_jclouds.conf" ]

	VM_MAD = [
    	name       = "vmm_jclouds",
    	executable = "one_vmm_sh",
    	arguments  = "-t 15 -r 0 jclouds",
    	default    = "vmm_exec/vmm_exec_jclouds.conf",
    	type       = "xml" ]
    	
    TM_MAD = [
    	executable = "one_tm",
    	arguments  = "-t 15 -d dummy,lvm,shared,qcow2,ssh,vmfs,iscsi,ceph,jclouds" ]
    	
Configure the provider parameters modifying properly the configuration file `/etc/one/im_jclouds/im_jclouds.conf` and the file `/etc/one/jclouds_rc`:

	$ cat jclouds_rc
	# User parameters
	:identity: "identity"
	:credential: "credential"

	# Provider parameters
	:endpoint: "url-endpoint-api"
	:cli: "jclouds"	
    	
Restart the server via:

	$ service opennebula restart 

## Usage

###Step 1 - Setup the Cluster

Create a cluster on Opennebula, named for example 'jclouds', using either the Sunstone GUI or via the following command:

	$ onecluster create jclouds

###Step 2 - Setup the Datastore

Create a datastore on Opennebula, named for example 'jclouds-ds', using either Sunstone GUI or the following commands:

	$ cat ds.conf
	NAME    = jclouds-ds
	TM_MAD  = jclouds
	TYPE    = SYSTEM_DS

	$ onedatastore create ds.conf


###Step 3 - Setup the Host

Create an host on Opennebula, named for example 'jclouds-provider', using either the Sunstone GUI or the following command:

	$ onehost create jclouds-provider --im im_jclouds --vm vmm_jclouds --net dummy


###Step 4 - Prepare a Virtual Template

Prepare a template suitable for the Jclouds Driver, named for example 'jclouds-vm', using either the Sunstone GUI or the following commands:

	$ cat jclouds.txt
	NAME="jclouds-vm"
	CPU="1"
	MEMORY="1024"
	CONTEXT=[
		FILES="file1 file2"
	]
	JCLOUDS=[
		EXTERNAL_NETWORK="remote_external_network",
		TEMPLATE="remote_template",
		PRIVATE_NETWORK="remote_private_network"
	]
	
 
	$ onetemplate create jclouds.txt
	ID: 2

Note. The contextualisation section (CONTEXT) is optional. 

###Step 5 - Starting the Virtual Machine

Start the VM either via the Sunstone GUI or via the following command:

	$ onetemplate instantiate 2 

## References

* JClouds: http://jclouds.incubator.apache.org/

