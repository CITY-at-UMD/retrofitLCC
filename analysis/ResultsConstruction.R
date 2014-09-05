# ResultsConstruction.R
# Takes in the simulation results and duplicate simulation mapping file. 
# Creates cash flows for each permutation, based on a year weighting over the lifetime.
#
# Building Science Group 2014
#
# Contributors: 
# Matthew G. Dahlhausen
#
# Package Dependencies: 
# 
rm(list=ls())  # clear variables 
#
# load measures data and simulation results
load('./measures/measure_permutations.RData')
load('./run_scripts/results/simulation_results.RData')
r <- nrow(permutations.map)
c <- ncol(permutations.map)

#duplicates <- duplicated(permutations.map[,ncol(permutations.map)])
#path.options <- permutations.map[!duplicates,]
#apply(path.options, 1, function(row) {
#  print(length(row))
#})

# list of all of the variables in the simulation results
vars <- c("site.energy", "site.energy.units", "source.energy", "source.energy.units", 
          "site.energy.intensity", "site.energy.intensity.units", "source.energy.intensity", "source.energy.intensity.units", 
          "annual.electric", "annual.electric.units", "annual.gas", "annual.gas.units",
          "peak.electric.demand", "peak.electric.demand.units", "ghg.emissions", "ghg.emissions.units",
          "annual.electric.cost", "annual.electric.cost.units", "annual.gas.cost", "annual.gas.cost.units",
          "total.annual.energy.cost", "total.annual.energy.cost.units", 
          "annual.energy.cost.intensity", "annual.energy.cost.intensity.units",
          "boiler.size", "cu.size")
# for each variable, create a matrix
for (var in vars) {
  assign(var, matrix(0, nrow=r, ncol=c))
}
# make a list with the variables
vars.list <- list(site.energy, site.energy.units, source.energy, source.energy.units, 
                  site.energy.intensity, site.energy.intensity.units, source.energy.intensity, source.energy.intensity.units, 
                  annual.electric, annual.electric.units, annual.gas, annual.gas.units,
                  peak.electric.demand, peak.electric.demand.units, ghg.emissions, ghg.emissions.units,
                  annual.electric.cost, annual.electric.cost.units, annual.gas.cost, annual.gas.cost.units,
                  total.annual.energy.cost, total.annual.energy.cost.units, 
                  annual.energy.cost.intensity, annual.energy.cost.intensity.units,
                  boiler.size, cu.size)
names(vars.list) <- vars
rm(list=vars)

# matrix which tells if a simulation results is available
permutations.exists <- matrix(0, nrow=r, ncol=c)

# populate the matrices for each variable, based on the simulation
for (i in 1:r) {
  for (j in 1:c) {
    run <- permutations.map[i,j]
    simulation.result <- simulation.results[simulation.results$run.name %in% run,]
    if (nrow(simulation.result) != 0) {
      permutations.exists[i,j] <- TRUE
      for (k in 1:length(vars)) {
        vars.list[[k]][i,j] <- simulation.result[,vars[k]]
      }       
    } else{
      permutations.exists[i,j] <- FALSE
    }    
  }
}

##############################
# CALCULATE LIFE CYCLE COST ##
##############################
#create arrays for capital cost, and add them to the list 

# some weighting thing to get the full life cycle, all unique values, weighted by capital cost
# melt them by the allowable capital cost / max capital outlay


