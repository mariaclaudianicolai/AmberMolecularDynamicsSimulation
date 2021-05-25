#!/bin/sh

# To run this program with 4 cores on GPU 1:
# ./run_simul.sh E136D 4 1

working_dir=$1
cores=$2
node=$3

log=state_simul

echo 'Ready! ' $working_dir

cd $working_dir

# Change if it is necessary
export CUDA_VISIBLE_DEVICES=$node


#running production
echo 'prod...' >>$log
pmemd.cuda -O -i ../prod_rest.in -c prod.rst -p protein_solvated.prmtop -o prod_rest1.out -r prod_rest1.rst -x prod_rest1.mdcrd -inf prod_rest1.mdinfo
#making production analysis files in a new directory
echo 'prod_analysis...' >>$log
mkdir prod_analysis
cd prod_analysis
process_mdout.perl ../prod_rest1.out
#back to working directory
cd ..
#converting mdcrd file into crd for analysis in VMD Windows
cpptraj -i ../cpptraj_prod_rest1.in
tar -czvf prod_rest1_cpptraj.tar.gz prod_rest1_cpptraj.crd

#simulation done
echo "Done!" >>$log 