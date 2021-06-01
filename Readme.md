---
# AMBER simulations

---

# 1 AMBER simulation of protein BCL-2 
Simulation of only protein so without any ligand like venetoclax.

## 1.1 Simulation of WT protein and G101V mutant protein: 200ns
PDB ID (WT): ```6O0K``` (crystal structure of BCL-2 with venetoclax).   
PDB ID (mutant): ```6O0L``` (crystal structure of BCL-2 G101V mutation with venetoclax).   

Clean the PDBs using first PyMOL in order to have two PDB files with only the details about the protein. 
So remove water molecules, venetoclax in any conformation, molecules and atoms used for the crystallization.  
In the mutant PDB you will find 2 structures but you need to select one of them. 

Then open PDB files with Notepad++ and remove anisotropic details. 
Save these files with the name you prefer and only when you will load files on your working directory
you will change file names in **protein.pdb**.

## 1.2 Configuration files

### Building topology ( Leap)

Make ```leap.in```
```
source /usr/local/amber20/dat/leap/cmd/oldff/leaprc.ff14SB
source leaprc.water.tip3p
protein = loadpdb protein.pdb
set default PBRadii mbondi2
saveAmberParm protein protein.prmtop protein.inpcrd
savepdb protein protein_leap.pdb
charge protein
addions protein Na+ 0
charge protein
solvatebox protein TIP3PBOX 12
saveamberparm protein protein_solvated.prmtop protein_solvated.inpcrd
savepdb protein protein_leap_solvated.pdb
quit
```
### Minimization
Make ```min.in```
```
Minimization
&cntrl
imin=1, maxcyc=1000, ncyc=500,
ntpr=100,
ntb=1, ntc=1, ntf=1,  
cut=10.0
/
```

### Equilibration
*Equlibration for 100ps each.*   
Make ```eq1.in```
```
Equilibration
 &cntrl
   nstlim=50000, dt=0.002,
   ntpr=1000, ntwx=1000,
   irest=0, ntx=1, 
   ntb,=1, ntc=2, ntf=2, 
   ntt=3, gamma_ln=1, temp0=300.0,
   cut=10.0, ig=-1,
/
```

Make ```eq2.in```
```
Equilibration
 &cntrl
   nstlim=50000, dt=0.002,
   ntpr=1000, ntwx=1000, ntwr=1000,
   irest=1, ntx=5,
   ntb=2, ntc=2, ntf=2,
   ntt=3, gamma_ln=1, temp0=300.0,
   ntp=1, taup=2.0,
   cut=10.0, ig=-1,
/
```

Make ```eq3.in```
```
Equilibration
 &cntrl
   nstlim=50000, dt=0.002,
   ntpr=1000, ntwx=500, ntwr=1000,
   irest=1, ntx=5,
   ntc=2, ntf=2, ntb=2,
   ntt=3, gamma_ln=1, temp0=300.0,
   ntp=1, taup=2.0,
   cut=10.0, ig=-1,
/
```

### Production
*MD simulation of 200ns*  
Make ```prod.in```
```
Production
 &cntrl
   nstlim=100000000, dt=0.002,
   ntpr=100000, ntwx=20000, ntwr=500000,
   irest=0, ntx=1,
   ntc=2, ntf=2, ntb=2,
   ntt=3, gamma_ln=1, temp0=300.0,
   ntp=1, taup=2.0,
   cut=10.0, ig=-1,
/
```

## 1.3 Prepare output file for analysis
The first solution is to use a **perl** script on *.out files (eq3 and prod) and analyze temperature, density and total energy.  
Example: ```process_mdout.perl prod.out```.

The second solution is to analyze the trajectory in **VMD**.  
When using VMD on Windows you have to convert *prod.mdcrd* file in a format VMD Windows readable. 
In doing this, make *cpptraj_eq.in* for the analysis on the third step of equilibration and make *cpptraj_prod.in* for the analysis of the production phase.

```cpptraj_eq.in```
```
parm protein_solvated.prmtop
trajin eq3.mdcrd
autoimage
trajout eq3_cpptraj.crd
run
quit
```

```cpptraj_prod.in```
```
parm protein_solvated.prmtop
trajin prod.mdcrd
autoimage
trajout prod_cpptraj.crd
run
quit
```
Run: ```cpptraj -i cpptraj_eq.in``` and ```cpptraj -i cpptraj_prod.in```

## 1.4 Automate simulations
In this case the simulation will be run for two structures. 
We will use 2 scripts to automate the process, so sequentially the simulations will be run.
In that case, you need to add the name of the new folder (containing *protein.pdb*) in which put the results in the *run_all* script.

### Script of all commands
Make ```run_simul.sh```
```
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
```
Make ```run_all.sh```
```
#!/bin/sh


# To run this program with 4 cores on GPU 1:
# ./run_all.sh 4 1

if [ $# -eq 2 ]
then
	# Define list of mutations
	mut_list="WT"
	# Define a log
	log=state_all

	echo '' >$log

	# Simulate mutations
	for mut in $mut_list; do
		# Accessing to elements of the list and append info to log
		echo 'Accessing ' $mut >>$log
		# Run run_simul.sh script for which is necessary to enter the core and node
		./run_simul.sh $mut $1 $2 
	done
else
	echo 'Error: 2 arguments are expected!'
fi
```
**Note:**  
In the *run_all.sh* change *mut_list* with the name of folder/s you create in the working directory ( folder with only *protein.pdb* inside).

## 1.5 Run simulations

Now we will prepare the working directory for the job.  
In the working directory:
* Create 2 folders ( *WT* and *G101V*) and copy in each of them the corresponding PDB protein file renamed in ```protein.pdb```.
* Copy in the working directory all the configuration files.
* Copy in the working directory all the scripts.

Make *run_simul.sh* and *run_all.sh* executable:  
```chmod +x run_simul.sh```  
```chmod +x run_all.sh```  

Check the **core** and **node** available on your server before run the job.  
Finally we can run the simulation/s:  
```nohup ./run_all.sh core_number node_number &```  

**Note:**  
* *nohup* to be sure the job runs in case you close the shell.  
* *&* runs the job in background.

# 2 Restart simulation

The configuration reported above is for a simulation of 200ns, but how can we continue the simulation and add other 200ns?
How can we restart the simulation?

## 2.1 Before restart
We need to make some name modifications to avoid overwriting the file we have from the previous simulation.

To be sure to not overwrite previous output files, we create a **new folder** in which we will move the necessary files.  
Then in this folder create 2 other folders one for the *WT* protein and one for *G101V* mutant portein. We will copy in them the file we need and in these folders we will find the output files.

### 2.1.2 Topology file
Move in the correspondent folder the topology file: 
* *protein_solvated.prmtop* of **WT**
* *protein_solvated.prmtop* of **G101V**

### 2.1.3 Production  
Restart means that we will run only the **MD production** step for other 200ns.  
Make  ```prod_rst.in``` *MD simulation of 200ns*:
```
Production
 &cntrl
   nstlim=100000000, dt=0.002,
   ntpr=100000, ntwx=20000, ntwr=500000,
   irest=1, ntx=5,
   ntc=2, ntf=2, ntb=2,
   ntt=3, gamma_ln=1, temp0=300.0,
   ntp=1, taup=2.0,
   cut=10.0, ig=-1,
/
```
**Note:**  
*irest=1*: restart the simulation, reading coordinates and velocities from previously saved restart file.
The velocity information is necessary when restarting, so *ntx* must be 4 or higher if *irest=1*.

### 2.1.4 Scripts
We will use 2 scripts to perform more simulation on after the other.

* **run_rst-simul.sh**  

To run the command for production step we need **prod.rst** from the previous simulation. Copy the file in the correspondent folder.  
  
This script runs also commands for generating output files for the analysis.  
Make ```run_rst-simul.sh```
```
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
pmemd.cuda -O -i ../prod_rst.in -c prod.rst -p protein_solvated.prmtop -o prod_rst1.out -r prod_rst1.rst -x prod_rst1.mdcrd -inf prod_rst1.mdinfo
#making production analysis files in a new directory
echo 'prod_analysis...' >>$log
mkdir prod_analysis
cd prod_analysis
process_mdout.perl ../prod_rst1.out
#back to working directory
cd ..
#converting mdcrd file into crd for analysis in VMD Windows
cpptraj -i ../cpptraj_prod_rst1.in
tar -czvf prod_rst1_cpptraj.tar.gz prod_rst1_cpptraj.crd

#simulation done
echo "Done!" >>$log 
```
  
* **run_rst-all.sh**    

This script is for the actual running. It works as in the normal simulation.  
  In *mut_list* type the name/s of the folder/s in which you want run the calculation ( folders correspond to the system you are studying).
  
Make ```run_rst-all.sh```
```
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
```

## 2.2 Run restart simulation
Make *run_rst-simul.sh* and *run_rst-all.sh* executable:  
```chmod +x run_rst-simul.sh```  
```chmod +x run_rst-all.sh```  

Check the **core** and **node** available on your server before run the job.  
Finally we can run the simulation/s:  
```nohup ./run_rst-all.sh core_number node_number &```  

**Note:**  
* *nohup* to be sure the job runs in case you close the shell.  
* *&* runs the job in background.

---

# 3 RMSD and RMSF

## 3.1 RMSD
*RMSD for the backbone and reference first frame*  
Make ```rmsd.in```  
```
parm protein_solvated.prmtop
trajin prod.mdcrd
rms @C,CA,N first out rmsd_backbone.agr
```

## 3.2 RMSF

*RMSF for the backbone of atoms and residues*  
Make  ```rmsf.in```  
```  
parm protein_solvated.prmtop
trajin prod.mdcrd
#rms first
#average crdset MyAvg
#run
#rms ref MyAvg
rmsd @C,CA,N first
atomicfluct out RMSF_backbone_atom.agr @CA,C,N
atomicfluct out RMSF_backbone_res.agr @CA,C,N byres
```  

## Run RMSD/F

Run RMSD: ``` cpptraj -i rmsd.in  ```    
Run RMSF: ``` cpptraj -i rmsf.in  ```  