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

#building topology files
echo 'leap...'>$log
tleap -f ../leap.in

#running minimization. Change core number!!!
echo 'min...' >>$log
mpirun -np $cores pmemd.MPI -O -i ../min.in -c protein_solvated.inpcrd -p protein_solvated.prmtop -ref protein_solvated.inpcrd -o min.out -r min.rst -inf min.mdinfo

#running equilibration. Change core number and environment variable!!!
echo 'eq1..' >>$log
mpirun -np $cores pmemd.MPI -O -i ../eq1.in -c min.rst -p protein_solvated.prmtop -ref min.rst -o eq1.out -r eq1.rst -x eq1.mdcrd -inf eq1.mdinfo
echo 'eq2...' >>$log
mpirun -np $cores pmemd.MPI -O -i ../eq2.in -c eq1.rst -p protein_solvated.prmtop -ref eq1.rst -o eq2.out -r eq2.rst -x eq2.mdcrd -inf eq2.mdinfo 
echo 'eq3...' >>$log
pmemd.cuda -O -i ../eq3.in -c eq2.rst -p protein_solvated.prmtop -o eq3.out -r eq3.rst -x eq3.mdcrd -inf eq3.mdinfo
#making equilibration analysis files in a new directory
echo 'eq_analysis...' >>$log
mkdir eq_analysis
cd eq_analysis
process_mdout.perl ../eq1.out ../eq2.out ../eq3.out
#back to working directory
cd ..
#converting mdcrd file into crd for analysis in VMD Windows
cpptraj -i ../cpptraj_eq.in
tar -czvf eq3_cpptraj.tar.gz eq3_cpptraj.crd

#running production
echo 'prod...' >>$log
pmemd.cuda -O -i ../prod.in -c eq3.rst -p protein_solvated.prmtop -o prod.out -r prod.rst -x prod.mdcrd -inf prod.mdinfo
#making production analysis files in a new directory
echo 'prod_analysis...' >>$log
mkdir prod_analysis
cd prod_analysis
process_mdout.perl ../prod.out
#back to working directory
cd ..
#converting mdcrd file into crd for analysis in VMD Windows
cpptraj -i ../cpptraj_prod.in
tar -czvf prod_cpptraj.tar.gz prod_cpptraj.crd

#simulation done
echo "Done!" >>$log 