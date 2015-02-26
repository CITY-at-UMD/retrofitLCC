#Analysis Directions: 
##Software Dependencies: 
* **[EnergyPlus 8.1](http://apps1.eere.energy.gov/buildings/energyplus/energyplus_about.cfm)**
* **OpenStudio 1.5.1, 1.5.2, or 1.5.3**
	* [Download OpenStudio 1.5.1 here](http://developer.nrel.gov/downloads/buildings/openstudio/builds/)
    * Make sure that you select the Windows version not the 64bit version (For example, for the 1.5.1, the donwloaded file has `OpenStudio-1.5.1.0c740efe7c-Windows.exe` name)    
* **Ruby 2.0.0**
    * [Download Ruby 2.0.0 here](https://www.ruby-lang.org/en/documentation/installation/)
    * Make sure that you select the regular version of the ruby 2.0.0-p598 version not the 64bit version (The donwloaded file has this name: `rubyinstaller-2.0.0-p598`)
    * During the installation make sure thay you check the 2nd and 3rd boxes to add ruby to the environmental paths and assocaited files. 
    * If you select the 64bit versions for the OpenStudio and ruby, OpenStudio will show a Win32 error message. 
    * add *Ruby200\bin* to the [path Environmental Variable](http://en.wikipedia.org/wiki/Environment_variable)
* **OpenStudio gem**	
    * add a file **openstudio.rb** to *Ruby\lib\ruby\site_ruby* with this in it (Windows machine):
```ruby
require 'C:\Program Files (x86)\OpenStudio 1.5.1\Ruby\openstudio.rb'
```
* **minitest 5.4.2 gem or greater**
    * [Download minitest 5.4.2](https://rubygems.org/gems/minitest/versions/5.4.2)
    * Put the file in the `C:\Ruby200\lib\ruby\gems\2.0.0\gems`
    * Go to the command line and navigate to the folder
    * Type `gem install minitest-5.4.2.gem`
    * You should see a new folder *minitest-5.4.2*

* **R, recommend RStudio 0.98.1083 or greater**
	* [Download RStudio](http://www.rstudio.com/products/RStudio/)
	* Install packages DBI, grid, gridExtra, gsubfn, ggplot2, proto, reshape2, RSQLite, scales, sqldf, tcltk, zoo

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
 Creates cash flows for each permutation, based on a capital constraint. 
 Saves these in data frames to the results folder under run_scripts

6.  **RetrofitCharts.R** 
 Takes in the data frames from ResultsConstruction and uses them to produce graphics
 
7.  **ResultsReaderSingleSimulation.R**
 Reads in the simulation results for a single simulation generates load component information and energy use breakdown.