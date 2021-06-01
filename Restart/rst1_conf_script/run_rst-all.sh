#!/bin/sh


# To run this program with 4 cores on GPU 1:
# ./run_all.sh 4 1

if [ $# -eq 2 ]
then
	# Define list of mutations
	#mut_list="WT G101V"
	mut_list="WT"
	# Define a log
	log=state_all

	echo '' >$log

	# Simulate mutations
	for mut in $mut_list; do
		# Accessing to elements of the list and append info to log
		echo 'Accessing ' $mut >>$log
		# Run run_rst-simul.sh script for which is necessary to enter the core and node
		./run_rst-simul.sh $mut $1 $2 
	done
else
	echo 'Error: 2 arguments are expected!'
fi