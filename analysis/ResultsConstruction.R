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
# Import function dependencies
source("./lib/npv.R") # Import financial calculation
source("./lib/escalationRates.R") # Import NIST escalation rates
invisible(ImportEscalationRates())

# load measures data and simulation results
print(paste("loading simulation data..."))
load('./measures/measure_permutations.RData')
load('./run_scripts/results/simulation_results.RData')
nperms <- nrow(permutations.map)

#######################################
create.var.list <- FALSE 
if (create.var.list) {
  print(paste("creating variable list..."))
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
    assign(var, matrix(0, nrow=nperms, ncol=num.m))
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
  rm(list=vars,var)
} 
#######################################

# determine if the simulation result for a given permutation is available
print(paste("determining which permutations exist..."))
permutation.exists <- matrix(0, nrow=nperms, ncol=num.m)
for (i in 1:nperms) {
  for (j in 1:num.m) {
    run <- permutations.map[i,j]
    simulation.result <- simulation.results[simulation.results$run.name %in% run,]
    if (nrow(simulation.result) != 0) {
      permutation.exists[i,j] <- TRUE
        
      # populate the matrices for each variable, based on the simulation
      if (create.var.list) { 
          for (k in 1:length(vars)) {
            vars.list[[k]][i,j] <- simulation.result[,vars[k]]
          }  
        } 
      
    } else{
      permutation.exists[i,j] <- FALSE
    }    
  }
}
rm(simulation.result, i, j, run)
if (exists("k")) { rm(k) }

# calculating unique path options 
# the unique simulation does this; this is just to see unique combinations of the 7 measures
# duplicates <- duplicated(permutations.map[,ncol(permutations.map)])
# path.options <- permutations.map[!duplicates,]
# need to include at least one of the duplicates...


########################################
## CALCULATE BASELINE LIFE CYCLE COST ##
########################################
print(paste("calculating baseline life-cycle cost..."))
# LCC variables
lifetime <- 20   # Use a 20 year life time to calculate NPV
discount.rate <- 0.03   # 3% discount rate
cash.flow <- matrix(0, nrow = nperms, ncol = lifetime+1) # cash.flow includes year 0, for a total of 21 years calculation

# calculate NPV of baseline case
capital.cost <- c(rep(0, lifetime+1))
baseline.energy.cost <- simulation.results$total.annual.energy.cost[simulation.results$run.name %in% "baseline"]
energy.cost <- c(-1*rep(baseline.energy.cost, lifetime+1))
baseline.ghg.emissions <- simulation.results$ghg.emissions[simulation.results$run.name %in% "baseline"]
ghg.emissions <- c(rep(baseline.ghg.emissions, lifetime+1))
cash.flow <- capital.cost + energy.cost
baseline.npv <- npv(discount.rate, cash.flow)
energy.cost.baseline <- energy.cost
rm(capital.cost, energy.cost, cash.flow)

# HVAC replacement measures and cost functions
boiler.index <- grep("SetBoilerThermalEfficiencyAndAutosize", measures$name)
cu.index <- grep("SetCOPforTwoSpeedDXCoolingUnitsAndAutosize", measures$name)
boiler.letter <- as.character(measures$letter[boiler.index])
cu.letter <- as.character(measures$letter[cu.index])
boiler.cu.run <- paste(boiler.letter, cu.letter, sep="_")
cu.boiler.run <- paste(cu.letter, boiler.letter, sep="_")
boiler.cost <- measure.cost.funclist[[boiler.index]]
cu.cost <- measure.cost.funclist[[cu.index]]

# calculate NPV of baseline with CU replacements in year 5 and boiler replacement in year 10
cu.replace.year <- 5
boiler.replace.year <- 10
capital.cost <- c(rep(0, lifetime+1))
energy.cost <- c(rep(0, lifetime+1))
ghg.emissions <- c(rep(0, lifetime+1))
if (cu.replace.year < boiler.replace.year) {
  cu.size <- simulation.results$cu.size[simulation.results$run.name %in% cu.letter]
  boiler.size <- simulation.results$boiler.size[simulation.results$run.name %in% cu.boiler.run]
  capital.cost[(cu.replace.year+1)] <- -cu.cost(cu.size)
  capital.cost[(boiler.replace.year+1)] <- -boiler.cost(boiler.size)
  energy.cost[1 : cu.replace.year] <- simulation.results$total.annual.energy.cost[simulation.results$run.name %in% "baseline"]
  energy.cost[(cu.replace.year+1) : boiler.replace.year] <- simulation.results$total.annual.energy.cost[simulation.results$run.name %in% cu.letter]
  energy.cost[(boiler.replace.year+1) : (lifetime+1)] <- simulation.results$total.annual.energy.cost[simulation.results$run.name %in% cu.boiler.run]
} else if (cu.replace.year > boiler.replace.year) {
  boiler.size <- simulation.results$boiler.size[simulation.results$run.name %in% boiler.letter]
  cu.size <- simulation.results$cu.size[simulation.results$run.name %in% boiler.cu.run]
  capital.cost[(boiler.replace.year+1)] <- -boiler.cost(boiler.size)
  capital.cost[(cu.replace.year+1)] <- -cu.cost(cu.size)
  energy.cost[1 : boiler.replace.year] <- simulation.results$total.annual.energy.cost[simulation.results$run.name %in% "baseline"]
  energy.cost[(boiler.replace.year+1) : cu.replace.year] <- simulation.results$total.annual.energy.cost[simulation.results$run.name %in% boiler.letter]
  energy.cost[(cu.replace.year+1) : (lifetime+1)] <- simulation.results$total.annual.energy.cost[simulation.results$run.name %in% boiler.cu.run]
} else { #same year replacement
  cu.size <- simulation.results$cu.size[simulation.results$run.name %in% cu.letter]
  boiler.size <- simulation.results$cu.size[simulation.results$run.name %in% boiler.letter]
  capital.cost[(cu.replace.year+1)] <- -cu.cost(cu.size)
  capital.cost[(boiler.replace.year+1)] <- capital.cost[boiler.replace.year+1] - boiler.cost(boiler.size)
  energy.cost[1 : cu.replace.year] <- simulation.results$total.annual.energy.cost[simulation.results$run.name %in% "baseline"]
  energy.cost[(cu.replace.year+1) : (lifetime+1)] <- simulation.results$total.annual.energy.cost[simulation.results$run.name %in% cu.boiler.run]
} 
energy.cost.baseline.with.replacements <- energy.cost
cash.flow <- capital.cost + energy.cost
baseline.with.replacements.npv <- npv(discount.rate, cash.flow)
rm(cu.size, boiler.size, capital.cost, energy.cost, cash.flow)


########################################################
## CALCULATE LIFE CYCLE COST OF EACH UNIQUE SIMULATION##
########################################################
print(paste("calculating life-cycle cost for each unique simulation..."))
# calculate NPV of each unique simulation, installed in the first year
# this gives the NPV for path options under the no capital restrictions case
unique.sim.len = nrow(simulation.results)
net.present.value <- c(rep(0, unique.sim.len))
for (i in 1:unique.sim.len) {
  this.run.name <- simulation.results$run.name[i]
  first.year.cost <- 0
  letters <- strsplit(this.run.name, "_")
  for (j in 1:length(letters[[1]])) {    
    if (letters[[1]][j] == "baseline"){ 
      first.year.cost <- 0
    } else {   
      measure.index <- grep(letters[[1]][j], measures$letter)
      if (as.character(measures$letter[measure.index]) == boiler.letter) {      
        boiler.size <- simulation.results$boiler.size[simulation.results$run.name %in% this.run.name] # determine boiler size
        measure.cost <- boiler.cost(boiler.size)
      } else if (as.character(measures$letter[measure.index]) == cu.letter) {      
        cu.size <- simulation.results$cu.size[simulation.results$run.name %in% this.run.name] # determine cu size
        measure.cost <- cu.cost(cu.size)
      } else {
        measure.cost <- measure.cost.funclist[[measure.index]](0)
      }  
      first.year.cost <- first.year.cost + measure.cost
    }
  }
  capital.cost <- c(-first.year.cost, rep(0, lifetime))
  energy.cost <- c(-1*rep(simulation.results$total.annual.energy.cost[simulation.results$run.name %in% this.run.name], lifetime+1))
  ghg.emissions <- c(rep(simulation.results$ghg.emissions[simulation.results$run.name %in% this.run.name], lifetime+1))  
  cash.flow <- capital.cost + energy.cost
  net.present.value[i] <- npv(discount.rate, cash.flow)     
}
rm(this.run.name, first.year.cost, letters, measure.index, boiler.size, cu.size, measure.cost, capital.cost, energy.cost, cash.flow, i, j)

# calculate the NPV relative to the baseline case
npv.relative.to.base <- c(rep(baseline.npv, unique.sim.len)) - net.present.value
npv.relative.to.base.with.replace <- c(rep(baseline.with.replacements.npv, unique.sim.len)) - net.present.value
simulation.results <- cbind(simulation.results, net.present.value, npv.relative.to.base, npv.relative.to.base.with.replace)
rm(net.present.value, npv.relative.to.base, npv.relative.to.base.with.replace)
 
save(simulation.results, file="./run_scripts/results/simulation_results_LCC.RData")
print(paste("simulation results saved to: ./run_scripts/results/simulation_results_LCC.RData"))

############################################################################
## CALCULATE LIFE CYCLE COST OF EACH UNIQUE PATH, UNDER CAPITAL CONSTRAINT##
############################################################################
print(paste("expanding simulation results..."))
#THIS MAY BE UNNCESSARY
# use the permutation.map to populate simulation results for the non-unique simulations
for (i in 1:nperms) {
  for (j in 1:num.m) {
    perm.name <- permutations[i,j]
    run.name <- permutations.map[i,j]    
    if (!is.element(perm.name, simulation.results$run.name)) { 
      # if the perm.name doesn't exist in the simulation results, 
      # get the corresponding run.name, check to see if it exists, 
      # and add it if it exists
      if (permutation.exists[i,j]) {
        simulation.result <- simulation.results[simulation.results$run.name %in% run.name,]
        simulation.result$run.name <- perm.name
        simulation.results <- rbind(simulation.results, simulation.result)  
      } # else permutation does not exist, do nothing
    } # else perm.name is in run.name, do nothing
  }
}
rownames(simulation.results) <- NULL
rm(i, j, perm.name, run.name, simulation.result)

# OUR ANALYSIS
# The big contribution of our analysis will be to allow the size of the maximum invesment
# Parameters:
# 5 levels of capital cost allowance: unrestricted, $5/ft^2, $3/ft^2, $2/ft^2, $1/ft^2, and w/wo revolving fund  
# 3 real discount rates: 2%, 3%, 5%
# 2 lifetimes: 20 years, 30 years
# NIST GHG scenarios: default, low, high
# NIST energy price scenario: default, low, high
# Rysanek, Choudhary, Energy and Buildings 57 (2013), importance:
# 1) high capital costs, 2) low energy prices, 3) poor tech preformance, 4) no carbon tariffs, 5) lesser decarbonization
area.m2 <- 5518.33
area.ft2 <- area.m2/(0.3048^2)
capital.intensity = 1 # $/ft2 per year investment allowance
capital.annual = capital.intensity*area.ft2
revolving.fund = FALSE

print(paste("calculating life-cycle cost for each of the", nperms, "paths under capital constraint..."))
# calculate the NPV for the path options under capital restriction scenarios
# for each permutation row, compare annual capital requirement to the measure cost.
# If the next measure is less than available capital, then implement it, otherwise go to next year

for (perm.row in 1:2) { 
  measure.order <- strsplit(permutations[perm.row, num.m], "_") 
  capital.cost <- c(rep(0, lifetime+1))
  energy.cost <- c(-baseline.energy.cost, rep(0, lifetime))
  ghg.emissions <- c(baseline.ghg.emissions, rep(0, lifetime))
  capital.avail <- capital.annual
  prev.run.name <- "baseline"
  j <- 1 # index to next measure
  for (yr in 1:lifetime+1) { # year is an integer, based on the annual simulation limitation in the way the code is constructed
    # update the available capital amount
    capital.avail <- capital.avail + capital.annual  
    
    # determine the appropriate simulation run   
    this.run.name <-  permutations.map[perm.row, j]
        
    # determine the measure
    measure.index <- grep(measure.order[[1]][j], measures$letter)
    
    # calculate measure cost
    if (as.character(measures$letter[measure.index]) == boiler.letter) {      
      boiler.size <- simulation.results$boiler.size[simulation.results$run.name %in% this.run.name] # determine boiler size
      measure.cost <- boiler.cost(boiler.size)
    } else if (as.character(measures$letter[measure.index]) == cu.letter) {      
      cu.size <- simulation.results$cu.size[simulation.results$run.name %in% this.run.name] # determine cu size
      measure.cost <- cu.cost(cu.size)
    } else {
      measure.cost <- measure.cost.funclist[[measure.index]](0)
    }  
    
    if (measure.cost <= capital.avail) { # implement this measure, and use the corresponding simulation run
      capital.avail <- capital.avail - measure.cost
      capital.cost[yr] <- -measure.cost
      energy.cost[yr] <- -simulation.results$total.annual.energy.cost[simulation.results$run.name %in% this.run.name]
      ghg.emissions[yr] <- simulation.results$ghg.emissions[simulation.results$run.name %in% this.run.name]
      prev.run.name <- this.run.name
      j <- j + 1
    } else {  # use the previous simulation run
      energy.cost[yr] <- -simulation.results$total.annual.energy.cost[simulation.results$run.name %in% prev.run.name]
      ghg.emissions[yr] <- simulation.results$ghg.emissions[simulation.results$run.name %in% prev.run.name]
    }   
    
    if (revolving.fund) { # if revolving fund, add energy cost savings to available capital
      capital.avail <- capital.avail + (energy.cost.baseline.with.replacements[yr] - energy.cost[yr])
    }        
  }
cash.flow <- capital.cost + energy.cost
net.present.value <- npv(discount.rate, cash.flow)  
}
