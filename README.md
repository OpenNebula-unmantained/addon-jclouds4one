# jclouds4one

## Description

The jclouds4one driver is an OpenNebula add-on that provides a way to access cloud providers implementing the [Apache Jclouds¨ library](<http://jclouds.incubator.apache.org/>). 
This work has been co-funded by the [European Space Agency (ESA)](<http://www.esa.int/ESA>). 

## Development

To contribute bug patches or new features for jclouds4one, you can use the github Pull Request model. It is assumed that code and documentation are contributed under the Apache License 2.0. 

More info:
* [How to Contribute](http://opennebula.org/software:add-ons#how_to_contribute_to_an_existing_add-on)
* Support: [OpenNebula user mailing list](http://opennebula.org/community:mailinglists)
* Development: [OpenNebula developers mailing list](http://opennebula.org/community:mailinglists)
* Issues Tracking: Github issues

## Authors

* Leader: Cesare Rossi (cesare.rossi[at]terradue.com)
* Supervisor: Emmanuel Mathot (emmanuel.mathot[at]terradue.com)

## Compatibility

This add-on is compatible with OpenNebula 4.2.

## Features

Implements hybrid Cloud computing, to support Cloud bursting, with the ability to work with a variety of Cloud provider, such as:

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

The Apache Jclouds¨ API open source library is to date providing support for 30 cloud providers & cloud software stacks.
The jclouds4one development is porting the Apache Jclouds¨ API as a driver for OpenNebula. 
The updated and complete list can be found here: http://jclouds.incubator.apache.org/documentation/userguide/

## Limitations

It is not tested with all the listed providers, so contributions in this way are appreciated.

## Requirements

A JClouds Command Line Interface (CLI). The driver is made for CLIs developed for the JClouds library (for example [jclouds-cli](<https://github.com/jclouds/jclouds-cli>)), but it is generic enough to be used with a generic CLI made on top of JClouds.

## Installation by RPM

This project is developed with Maven and the RPM provided with the rpm-maven-plugin (read `pom.xml`). Once you have built the project, install the package by:

	$ rpm -Uvh jclouds4one.rpm
	
## Manual Installation

To manually install the Driver, you have to download the repository as a ZIP:

	$ unzip jclouds4one-master.zip
	$ cd jclouds4one-master
	
Copy the main driver files in the cloud controller machine:

	$ cp src/main/ruby/im_mad /var/lib/one/remotes/vmm/jclouds
	$ cp src/main/ruby/im_mad /usr/lib/one/mads
	$ cp src/main/ruby/tm_mad /var/lib/one/remotes/tm/jclouds

Copy the configuration driver files in the cloud controller machine:

	$ cp src/main/resources/config/im /etc/one/im_jclouds
	$ cp src/main/resources/config/vmm/jcloudsrc /etc/one/
	$ cp src/main/resources/config/vmm/vmm_exec_jclouds.conf /etc/one/vmm_exec
	$ cp src/main/resources/scripts/setup /etc/one/jclouds_setup

## Configuration

Configure the Opennebula installation, adding the JClouds Information Manager, Virtual Machine Manager and the Transfer Manager. It can be done adding to the file `/etc/one/oned.conf` the following lines:

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
    	
Configure the provider parameters modifying properly the configuration file `/etc/one/im_jclouds/im_jclouds.conf` and the file `/etc/one/jcloudsrc`:

	$ cat jcloudsrc
	# User parameters
	:identity: "identity"
	:credential: "credential"

	# Provider parameters
	:provider: "provider-name"
	:cli: "jclouds"	
	
Configure the CLI path on the Cloud Controller modifying properly the configuration file `/etc/one/vmm_exec/vmm_execrc`

	$ cat vmm_execrc
	[..]
	JCLOUDS_CLI_PATH=/path/to/drivers_cli/jclouds/bin
	JCLOUDS_CONTEXT_PATH=/path/to/remote_context/jclouds/iso
    	
Restart the server via:

	$ service opennebula restart 

## Usage

There is two ways to setup the OpenNebula Cloud Controller (as oneadmin user): by following the Step 1-4 or using the setup script `/etc/one/jclouds_setup/setup.sh`. 

###Step 1 - Setup the Cluster

Create a cluster on Opennebula, named for example 'JClouds', using either the Sunstone GUI or via the following command:

	$ onecluster create JClouds

###Step 2 - Setup the Datastore

Create a datastore on Opennebula, named for example 'JClouds', using either Sunstone GUI or the following commands:

	$ cat ds.conf
	NAME    = JClouds
	TM_MAD  = jclouds
	TYPE    = SYSTEM_DS

	$ onedatastore create ds.conf


###Step 3 - Setup the Host

Create an host on Opennebula, named for example 'JClouds', using either the Sunstone GUI or the following command:

	$ onehost create amazon-ec2 --im im_jclouds --vm vmm_jclouds --net dummy


###Step 4 - Prepare a Virtual Template

Prepare a template suitable for the JClouds Driver, named for example 'JClouds', using either the Sunstone GUI or the following commands:

	$ cat jclouds_template.txt
	NAME="JClouds"
	CONTEXT=[
		FILES=""
	]
	JCLOUDS=[
    	GROUP="default",
    	HARDWAREID="t1.micro",
    	LOCATIONID="us-east-1d"
	]
	
 
	$ onetemplate create jclouds.txt
	ID: 2

Note. The contextualisation section (CONTEXT) is optional. 

###Step 5 - Starting the Virtual Machine

Start the VM either via the Sunstone GUI or via the following command:

	$ onetemplate instantiate 2 

## References

* JClouds: http://jclouds.incubator.apache.org/

