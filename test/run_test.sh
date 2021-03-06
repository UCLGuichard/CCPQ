#!/bin/bash

# copy test input files
cp ../input/System.inp ../input/System_tmp.inp 
cp ../input/Dynamics.inp ../input/Dynamics_tmp.inp 
cp ../input/Output.inp ../input/Output_tmp.inp 

cp ./test_input/*.inp ../input/ 

# Run test case for Decoherence
cd ../bin/
rm *.dat
./Decoherence.exe

# Copy output files as inputs for Tania's subroutine
cd ../test/Tania_subroutine/
rm *.dat

lines=$(wc -l < ../../bin/couplings_nuclear_*.dat)
echo $((lines - 1)) > coupling.dat
sed -n '2,$p' ../../bin/couplings_nuclear_*.dat >> coupling.dat

# Run test
./ROLAND.DD.out < input_test.inp

# copy back and remove input files
cp ../../input/System_tmp.inp ../../input/System.inp 
cp ../../input/Dynamics_tmp.inp ../../input/Dynamics.inp 
cp ../../input/Output_tmp.inp ../../input/Output.inp 

rm ../../input/System_tmp.inp
rm ../../input/Dynamics_tmp.inp
rm ../../input/Output_tmp.inp

































































