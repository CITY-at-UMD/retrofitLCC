#Directions: 
##Folders: 
-*lib*
 Contains R functions for recursion, permutation, net present value, etc.

-*measures* 
 Contains the ruby script implementation for each R measure. 
 Note that each measure is fixed where possible

##Files:
-*RetrofitPermute (R)*
 Reads in measure names and generates all permutations.  
 Then, it removes duplicate permutations, but retains a mapping for post processing, saved as an .RData file.

-*RunGeneration  (R, ruby imbedded)*
 Takes in a .RData file of measures with in an order of implementation, and writes a run manager ruby script to simulate it

-*RunManagerMaster (ruby)*
 A master code that runs all the ruby scripts, and deletes extraneous files after each simulation

-*ResultsConstruction (R)*
 Takes in the simulation results and duplicate simulation mapping file. 
 Creates cash flows for each permutation from RetrofitPermute 

-*RetrofitCharts (R, D3)*
 Takes in the data frames from ResultsConstruction and uses it to produce graphics