# Update environment variables for Opennebula process
grep 'JAVA_HOME=' /etc/one/vmm_exec/vmm_execrc > /dev/null 2>&1

if [ $? -ne 0 ]; then
	echo 'JAVA_HOME=${JAVA_HOME}' >> /etc/one/vmm_exec/vmm_execrc
fi

grep 'JCLOUDS_CLI_PATH=' /etc/one/vmm_exec/vmm_execrc > /dev/null 2>&1

if [ $? -ne 0 ]; then
	echo 'JCLOUDS_CLI_PATH=${JCLOUDS_CLI_PATH}' >> /etc/one/vmm_exec/vmm_execrc
fi

grep 'JCLOUDS_CONTEXT_PATH=' /etc/one/vmm_exec/vmm_execrc > /dev/null 2>&1

if [ $? -ne 0 ]; then
	echo 'JCLOUDS_CONTEXT_PATH=${JCLOUDS_CONTEXT_PATH}' >> /etc/one/vmm_exec/vmm_execrc
fi

service opennebula restart