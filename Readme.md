# AMBER simulations

## 1 AMBER simulation of protein BCL-2 
Simulation of only protein so without any ligand like venetoclax.

### 1.1 Simulation of WT protein and G101V mutant protein: 200ns
PDB ID (WT): ```6O0K``` (crystal structure of BCL-2 with venetoclax).   
PDB ID (mutant): ```6O0L``` (crystal structure of BCL-2 G101V mutation with venetoclax).   

Clean the PDBs using PyMOL in order to have two PDB files with only the details about the protein. 
So remove water molecules, venetoclax in any conformation, molecules and atoms used for the crystallization.  
In the mutant PDB you will find 2 structures but you need to select one of them.  
Then open PDB files with Notepad++ and remove anisotropic details.  
**name of protein.pdb in the final directory**

### 1.2 Configuration files

#### Building topology ( Leap)

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
#### Minimization
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

#### Equilibration
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

#### Production
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

### 1.3 Prepare output file for analysis
The first solution is to use a **perl** script on *.out files (eq3 and prod) and analyze temperature, density and total energy.  
Example: ```process_mdout.perl prod.out```.

The second solution is to analyze the trajectory in **VMD**.  
When using VMD on Windows you have to convert prod.mdcrd file in one VMD Windows readable. 
In doing this, make *cpptraj_eq.in* for the analysis on the third step of equilibration and make *cpptraj_prod.in* for the analysis of the production phase.

```cpptraj_eq.in```
```
parm complex_solvated.prmtop
trajin eq3.mdcrd
autoimage
trajout eq3_cpptraj.crd
run
quit
```

```cpptraj_prod.in```
```
parm complex_solvated.prmtop
trajin prod.mdcrd
autoimage
trajout prod_cpptraj.crd
run
quit
```

### 1.4 Run the simulation
In this case the simulation will be run on two structures.  
In the working directory:
* create 2 folders in which you will copy the PDB files renamed ```protein.pdb```