#Analysis Directions: 
##Software Dependencies: 
* **EnergyPlus 8.1 or greater**
* **OpenStudio 1.5.1 or greater**
* **Ruby 2.0.0 or greater** 
    * add *Ruby200\bin* to path
    * add a file **openstudio.rb** to *Ruby\lib\ruby\site_ruby* with this in it:
```ruby
require 'C:\Program Files (x86)\OpenStudio 1.5.0\Ruby\openstudio.rb'
```
* **R, recommend RStudio 0.98.1083 or greater**

##Folders: 
* **autosize_measure**
 contains the autosizing measure to hard size HVAC equipment to values from a prior simulation run.

* **base_scripts**
 contains the base scripts for building a ruby run manager call.
 
* **energyplus_additions**
 contains .idf file output requests for environmental impact, utility rates, and load component summaries.
 
* **lib**
 contains R functions for recursion, permutation, net present value, etc.
 
* **measures**
 contains the ruby script implementation for each R measure. 
 
* **model**
 contains the base openstudio model
 
* **run_scripts**
 contains the run scripts for each unique simulation.

* **weather**
 contains the weather file

##Run these files in order:
1.  **RetrofitPermute.R**
 Reads in measure names and generates all possible permutations.
 A copy of the list replaces permutations with combinations with identical simulation results.  E.g., if to measures are independent, then ab = ba, whereas for a third, independent measure c, ac <> ca.  This copy is a "map" to back to the original permutation.  Finally, only unique simulations in the map are identified for simulation.  Saves permutation list, map, simulations required, and cost array to an .RData file.

2.  **run_generation.rb** 
 Takes in a text file of a measure table, with a corresponding letter lookup, and a text file of the unique simulations needed.  It writes a run manager ruby script for each unique simulation. If a measure is dependent on preceding simulations, it will hardsize the equipment based on the .eio file of the prior simulation.

3.  **run_master.rb** 
 Runs all the ruby scripts for each unique simulation, and deletes extraneous files after each simulation.

4.  **ResultsReader.R**
 Reads in the simulation results and saves them to an .RData file.
 
5.  **ResultsConstruction.R**
 Takes in the simulation results and duplicate simulation mapping file. 
 Creates cash flows for each permutation, based on a year weighting over the lifetime.

6.  **RetrofitCharts.R** 
 Takes in the data frames from ResultsConstruction and uses it to produce graphics