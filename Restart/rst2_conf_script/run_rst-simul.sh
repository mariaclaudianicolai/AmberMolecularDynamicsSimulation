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
pmemd.cuda -O -i ../prod_rst.in -c prod_rest1.rst -p protein_solvated.prmtop -o prod_rst2.out -r prod_rst2.rst -x prod_rst2.mdcrd -inf prod_rst2.mdinfo
#making production analysis files in a new directory
echo 'prod_analysis...' >>$log
mkdir prod_analysis
cd prod_analysis
process_mdout.perl ../prod_rst2.out
#back to working directory
cd ..
#converting mdcrd file into crd for analysis in VMD Windows
cpptraj -i ../cpptraj_prod_rst2.in
tar -czvf prod_rst2_cpptraj.tar.gz prod_rst2_cpptraj.crd

#simulation done
echo "Done!" >>$log 