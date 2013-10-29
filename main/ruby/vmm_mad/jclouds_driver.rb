# ---------------------------------------------------------------------------- #
# Copyright 2013, Terradue S.r.l.                                              #
#                                                                              #
# Licensed under the Apache License, Version 2.0 (the "License"); you may      #
# not use this file except in compliance with the License. You may obtain      #
# a copy of the License at                                                     #
#                                                                              #
# http://www.apache.org/licenses/LICENSE-2.0                                   #
#                                                                              #
# Unless required by applicable law or agreed to in writing, software          #
# distributed under the License is distributed on an "AS IS" BASIS,            #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.     #
# See the License for the specific language governing permissions and          #
# limitations under the License.                                               #
# ---------------------------------------------------------------------------- #

require "scripts_common"
require 'yaml'
require "CommandManager"
require "rexml/document"
require "VirtualMachineDriver"
require 'fileutils'

class JCloudsDriver < VirtualMachineDriver
    # -------------------------------------------------------------------------#
    # Set up the environment for the driver                                    #
    # -------------------------------------------------------------------------#
    ONE_LOCATION = ENV["ONE_LOCATION"]
    JCLOUDS_CLI_PATH = ENV["JCLOUDS_CLI_PATH"]
    JCLOUDS_CONTEXT_PATH = ENV["JCLOUDS_CONTEXT_PATH"]

    if !ONE_LOCATION
       BIN_LOCATION = "/usr/bin" 
       LIB_LOCATION = "/usr/lib/one"
       ETC_LOCATION = "/etc/one" 
       VAR_LOCATION = "/var/lib/one"
       DS_LOCATION  = "/var/lib/one/datastores"
    else
       LIB_LOCATION = ONE_LOCATION + "/lib"
       BIN_LOCATION = ONE_LOCATION + "/bin" 
       ETC_LOCATION = ONE_LOCATION  + "/etc/"
       VAR_LOCATION = ONE_LOCATION + "/var/"
       DS_LOCATION  = ONE_LOCATION + "/datastores"
    end

    CONF_FILE   = ETC_LOCATION + "/jclouds_rc"

    ENV['LANG'] = 'C'

    SHUTDOWN_INTERVAL = 5
    SHUTDOWN_TIMEOUT  = 500

    def initialize(host)
      
       conf  = YAML::load(File.read(CONF_FILE))
       
       # Provider parameters
       @provider = conf[:provider]
       @identity= conf[:identity]
       
       if conf[:credential] and !conf[:credential].empty?
          @credential  = conf[:credential]
       else
          @credential="\"\""
       end
           
       # -------------------------------------------------------------------------#
       # Configuration of the CLI                                                 #
       # -------------------------------------------------------------------------#
           
       # Regular expressions templates for parsing responses.
       # These depends from the CLI used
       @cli = conf[:cli]       
       @external_ip_regex = /Public\sAddress:\s(\S{1,})/
       @internal_ip_regex = /Private\sAddress:\s(\S{1,})/
       
       # This doesn't depend directly from the CLI but depends from the 'poll' method
       # (i.e. from the informations that one wants to display, either in log).
       @one_poll_regex = /STATE=(.*?)\sEXT_IP=(.*?)\sINT_IP=(.*?)$/   
	   
    end

    # ######################################################################## #
    #                          JCLOUDS DRIVER ACTIONS                          #
    # ######################################################################## #

    # ------------------------------------------------------------------------ #
    # Deploy and define a VM                                                   #
    # ------------------------------------------------------------------------ #
    def deploy(dfile, id)
    	
        one_id = "one-#{id}"
        
    	# Extract informations from xml template
    	xml = File.new(dfile, "r").read
    	doc = REXML::Document.new xml    	  
    	
        # Deployment parameters  
    	
        # NOTE
        # In the version 3.8.3 of OpenNebula the parameters gathers from the xml template was a little different
        # For example:
        # doc.elements["TEMPLATE/JCLOUDS/PARAMS"] instead of doc.elements["VM/USER_TEMPLATE/JCLOUDS/PARAMS"]  	
    	# TODO: Costruct the parameters with an each
    	params 
        doc.elements.each("VM/USER_TEMPLATE/JCLOUDS/*") { |element| puts element.name }
    	params = doc.elements["VM/USER_TEMPLATE/JCLOUDS/PARAMS"].text
        group  = doc.elements["VM/USER_TEMPLATE/JCLOUDS/group"].text
  
        # Construct the command parameters
        auth_params       = "--provider #{@provider} --identity #{@identity} --credential #{@credential}"
        additional_params = " \"#{params}\""
            
        # Starts the VM
        rc, info = do_action(JCLOUDS_CLI_PATH + "/" + @cli + " node create" + " " + auth_params +
                             " " + additional_params + " " + group)
                   
        if rc == false
            exit info
        end
        
        # Extract the 'id' (or internal_name) from JClouds response
        # The response is in the form:
        #
        # [id]                 [location] [hardware] [group] [status]
        # us-east-1/i-00452c66 us-east-1d t1.micro   default RUNNING
                
        internal_name = info.lines[1].split(" ")[0]             
        
        OpenNebula.log_debug("JClouds internal name #{internal_name}")
        
        # Wait until the machine is in RUNNING state and the Public Address is present
        ip_regex = /\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b/
         
        begin
            
            sleep(5)
            
            state_short = '-'
            ext_addr = '-'
            
            info = poll(internal_name)            
            tmp = info.match(@one_poll_regex)
            
            if tmp
                state_short = tmp[1]
                ext_addr = tmp[2]
            end           
                                    
        end while ( state_short == VM_STATE[:unknown] ) || !ext_addr.match(ip_regex) 
                        
        # Prepare the remote context
        remote_vm_id = ext_addr.gsub(".", "-")
        remote_context_dir = JCLOUDS_CONTEXT_PATH + '/' + remote_vm_id
        prepare_context(remote_vm_id, id) unless File.directory?(remote_context_dir)

        OpenNebula.log_debug("Successfully created JClouds instance (name: #{one_id}, internal_name: #{internal_name})")
        
        reference_id = internal_name + "@" + remote_vm_id
        
        return reference_id
    end

    # ------------------------------------------------------------------------ #
    # Cancels the VM                                                           #
    # ------------------------------------------------------------------------ #
    def cancel(reference_id)
        
        shutdown(reference_id)
    end

    # ------------------------------------------------------------------------ #
    # Reboots a running VM                                                     #
    # ------------------------------------------------------------------------ #
    def reboot(reference_id)
        
        OpenNebula.log_debug("Action not implemented.")
    end

    # ------------------------------------------------------------------------ #
    # Reset a running VM                                                       #
    # ------------------------------------------------------------------------ #
    def reset(reference_id)
        
        OpenNebula.log_debug("Action not implemented.")
    end

    # ------------------------------------------------------------------------ #
    # Migrate                                                                  #
    # ------------------------------------------------------------------------ #
    def migrate(reference_id, dst_host, src_host)
        
        OpenNebula.log_debug("Action not implemented.")
    end
    
    # ------------------------------------------------------------------------ #
    # Monitor a VM                                                             #
    # ------------------------------------------------------------------------ #
    def poll(reference_id)
        
        auth_params = "--provider #{@provider} --identity #{@identity} --credential #{@credential}"
        
        tmp = reference_id.split("@")        
        internal_name = tmp[0]
           
        # Start the monitoring
        rc, info = do_action(JCLOUDS_CLI_PATH + "/" + @cli + " node info" + " " + auth_params + " " + internal_name)

        return "STATE=#{VM_STATE[:deleted]}" if rc == false
        
        state = '-'
        ext_addr = '-'

        # Extract informations from 'node info' response
        
        # -> State     
        tmp = info.lines[1].split(" ")[4]
        state = tmp[1] if tmp
        
        # -> Public IP
        tmp = info.match(@external_ip_regex)
        ext_addr = tmp[1] if tmp
        
        # -> Private IP
        tmp = info.match(@internal_ip_regex)
        int_addr = tmp[1] if tmp
                                     
        case state
            when "RUNNING"
                state_short = VM_STATE[:active]
            when "STOPPED"
                state_short = 's'
            else
                state_short = VM_STATE[:unknown]
        end  
                   
        info = "STATE=#{state_short} EXT_IP=#{ext_addr} INT_IP=#{int_addr}"
        
        OpenNebula.log_debug("info: #{info}")
        
        return info
    end

    # ------------------------------------------------------------------------ #
    # Restore a VM                                                             #
    # ------------------------------------------------------------------------ #
    def restore(checkpoint)
        
        OpenNebula.log_debug("Action not yet implemented.")
    end

    # ------------------------------------------------------------------------ #
    # Saves a VM taking a snapshot                                             #
    # ------------------------------------------------------------------------ #
    def save(reference_id)
        
        OpenNebula.log_debug("Action not implemented.")
    end

    # ------------------------------------------------------------------------ #
    # Shutdown a VM                                                            #
    # ------------------------------------------------------------------------ #
    def shutdown(reference_id)
    
        auth_params = "--provider #{@provider} --identity #{@identity} --credential #{@credential}"
        
        tmp = reference_id.split("@")        
        internal_name = tmp[0]
        remote_vm_id = tmp[1]
        
        remove_context(remote_vm_id)
                
        # Destroy the VM
        rc, info = do_action(JCLOUDS_CLI_PATH + "/" + @cli + " node destroy" + " " + auth_params + " " + provider_params + " --internalName " + internal_name) 

        exit info if rc == false
                
        OpenNebula.log_debug("Successfully removed JClouds instance #{internal_name}.")
    end

    # ######################################################################## #
    #                          DRIVER HELPER FUNCTIONS                         #
    # ######################################################################## #

    private

    # Performs an action
    def do_action(cmd, log=true)
        
        rc = LocalCommand.run(cmd)

        if rc.code == 0
            return [true, rc.stdout]
        else
            err = "Error executing: #{cmd} err: #{rc.stderr} out: #{rc.stdout}"
            OpenNebula.log_error(err) if log
            return [false, rc.code]
        end
    end
    
    # Prepare a remote context for the Virtual Machine
    def prepare_context(deployment_id, id)         

        tar_filename = 'context.tgz'
        iso_dir = DS_LOCATION + '/' + ".isofiles" + "/" + id
        remote_context_dir = JCLOUDS_CONTEXT_PATH + '/' + deployment_id
        
        # Creating remote context dir        
        FileUtils.mkdir_p remote_context_dir       
        
        # Creating tarball and copying it in the remote_context_dir                
        rc, info = do_action("cd #{iso_dir}; tar -cvzf #{tar_filename} * > /dev/null 2>&1; cp #{tar_filename} #{remote_context_dir} ")
        
        # Removing the iso_dir created by Opennebula       
        FileUtils.rm_rf iso_dir               
    end
    
    # Remove the remote context directory when unnecessary
    def remove_context(remote_vm_id)     
        
        remote_context_dir = JCLOUDS_CONTEXT_PATH + '/' + remote_vm_id
        FileUtils.rm_rf remote_context_dir
    end

end
