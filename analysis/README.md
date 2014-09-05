#Analysis Directions: 
##Folders: 
-**lib**
 contains R functions for recursion, permutation, net present value, etc.
 
-**measures**
 contains the ruby script implementation for each R measure. 
 
-**energyplus_additions**
 contains .idf file output requests for environmental impact, utility rates, and load component summaries.
 
-**base_scripts**
 contains the base scripts for building a ruby run manager call.
 
-**run_scripts**
 contains the run scripts for each unique simulation.
 
##Files:
1)**RetrofitPermute.R**
 reads in measure names and generates all possible permutations.
 A copy of the list replaces permutations with combinations with identical simulation results.  
 E.g., if to measures are independent, then ab = ba, whereas for a third, independent measure c, ac <> ca.
 This copy is a "map" to back to the original permutation.  Finally, only unique simulations in the map are identified for simulation.  
 Saves permutation list, map, simulations required, and cost array to an .RData file.

2)**run_generation.rb** 
 takes in a text file of a measure table, with a corresponding letter lookup, and a text file of the unique simulations needed.  It writes a run manager ruby script for each unique simulation. If a measure is dependent on preceding simulations, it will hardsize the equipment based on the .eio file of the prior simulation.

3)**run_master.rb** 
 runs all the ruby scripts for each unique simulation, and deletes extraneous files after each simulation.

4)**ResultsConstruction.R**
 takes in the simulation results and duplicate simulation mapping file. 
 Creates cash flows for each permutation.

5)**RetrofitCharts.R** 
 takes in the data frames from ResultsConstruction and uses it to produce graphics