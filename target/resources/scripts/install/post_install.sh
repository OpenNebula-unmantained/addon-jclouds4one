# Update environment variables for Opennebula process
grep 'JAVA_HOME=' /etc/one/vmm_exec/vmm_execrc > /dev/null 2>&1

if [ $? -ne 0 ]; then
	echo 'JAVA_HOME=/usr/java/jdk1.7.0_17' >> /etc/one/vmm_exec/vmm_execrc
fi

grep 'JCLOUDS_CLI_PATH=' /etc/one/vmm_exec/vmm_execrc > /dev/null 2>&1

if [ $? -ne 0 ]; then
	echo 'JCLOUDS_CLI_PATH=/cloud/drivers_cli/jclouds/bin' >> /etc/one/vmm_exec/vmm_execrc
fi

grep 'JCLOUDS_CONTEXT_PATH=' /etc/one/vmm_exec/vmm_execrc > /dev/null 2>&1

if [ $? -ne 0 ]; then
	echo 'JCLOUDS_CONTEXT_PATH=/cloud/remote_context/jclouds/iso' >> /etc/one/vmm_exec/vmm_execrc
fi

service opennebula restart