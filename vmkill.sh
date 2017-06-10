#!/bin/bash

# Title: VMKill v1.6
# Purpose: Shutdown all VMs, then shutdown/reboot host if desired. 
# Author: Chris Johnson cc452@icloud.com
# Explanation: Looks for active virtual machines using virsh, sends each a shutdown signal, then polls virsh until all VMs are verified offline.
#              It then shuts down or reboots the host, depending on chosen parameters.
# Example: ./vmkill -s
# Optional Parameters: -s shutdown host, -r reboot host, -h list optional parameters 

# Script header
script_header () {
	printf "\nVMKill - v1.6\n------------------------------\n"
}

# Checks for root user
check_root () {
	if [ "$UID" != "0" ]; then
		printf "Must be root to run.\n\n"
		exit
	fi
}

# Getopts definition
script_options () {
	while getopts "srh" opt; do
		case $opt in
			s) shutdown_host
			;;
			r) reboot_host
			;;
			h) file_help
			;;
		esac
	done
}

# Saves list of active virtual machines to an array
map_vmArray () {
	mapfile -t vmshutdown < <(virsh list --name)
}

check_active () {
	if [ "${vmshutdown[0]}" == '' ]; then
		printf "There are no active VMs.\n\n"
		exit
	fi
}

# Cycles through the array, shutting down each virtual machine referenced, ignoring any empty fields in the array
shutdown_VMs () {
	for (( i=0; i<${#vmshutdown[@]}; i++ ));
		do
			if [ "${vmshutdown[i]}" != '' ]; then
				printf "Sending shutdown signal to ${vmshutdown[i]}.\n"
				virsh shutdown ${vmshutdown[i]}
			fi
		done
}

VM_status () {
	# Initialize function variables
	VIRSHSTATUS=0
	SEC="A"

	#Calls for list of active VMs, until the list returns nothing
	printf "Waiting on VM shutdown to complete.\n"
	until [ "$VIRSHSTATUS" = '' ]; do
		VIRSHSTATUS=$(virsh list --name)

		# Displays a * char once per second during the VIRSHSTATUS run, to show the script hasn’t frozen
		if [ "$SEC" != $(date +%S) ]; then
			SEC=$(date +%S)
			printf "*"
		fi
	done

	# Displays completion once virsh returns zero active VMs
	printf "\nVM shutdown complete.\n\n"
}

shutdown_host () {
	printf "Shutting down host $(hostnamectl --static).\n\n"
	map_vmArray
	check_active
	shutdown_VMs
	VM_status
    shutdown now
    exit
}

reboot_host () {
	printf "Rebooting host $(hostnamectl --static).\n\n"
	map_vmArray
	check_active
	shutdown_VMs
	VM_status
    reboot
    exit
}

file_help () {
	printf "Script accepts -s for shutting down host, -r for rebooting host, and -h for help.\n\n"
	exit
}

# Function calls (main program sequence)
script_header
check_root
script_options
map_vmArray
check_active
shutdown_VMs
VM_status
