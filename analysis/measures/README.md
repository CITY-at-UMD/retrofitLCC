#Measure Folders 
In addition to the standard OpenStudio measure writing, each measure includes:

-**cost.R**, a function for the measure cost.  Most take in null input, but dependent HVAC measures take in size as a variable to determine cost. 

*Example:*
```R
cost <- function(size) {
  fixed <- 50000
  variable <- 1000
  return (size*variable + fixed)
  }
```
-**measure_flags.R** contains a flag for measure dependence.  If a measure does not depend on prior measures, dependence is 0, otherwise it is 1.  
  
*Example:*
```R
dependence <- 0
```

#Temp Files
These files are generated from running the top-level scripts:

-**measure_permutations.RData** contains all measure data, cost functions, permutations, and reduction for simulation. 

-**measure_map.txt** contains a table correlating letter to measure, and measure dependence.

-**unique_sims.txt** contains the unique combinations to be simulated.
 