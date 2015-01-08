# ResultsConstruction.R
# Takes in the simulation results and duplicate simulation mapping file. 
# Creates cash flows for each permutation, with and without capital constraint
#
# Building Science Group 2014-2015
#
# Contributors: 
# Matthew G. Dahlhausen
#
# Package Dependencies: 
# (none)
# 
rm(list=ls())  # clear variables 
#
# Import function dependencies
source("./lib/npv.R") # Import financial calculation
source("./lib/escalationRates.R") # Import NIST escalation rates
escalation.rates <- invisible(ImportEscalationRates())

# load measures data and simulation results
print(paste("loading simulation data..."))
load('./measures/measure_permutations.RData')
load('./run_scripts/results/simulation_results.RData')
nperms <- nrow(permutations.map)

##################################################
## CHECK TO SEE WHICH SIMULATIONS ARE AVAILABLE ##
##################################################
# determine if the simulation result for a given permutation is available
print(paste("determining which permutations exist..."))
permutation.exists <- matrix(0, nrow=nperms, ncol=num.m)
for (i in 1:nperms) {
  for (j in 1:num.m) {
    run <- permutations.map[i,j]
    simulation.result <- simulation.results[simulation.results$run.name %in% run,]
    if (nrow(simulation.result) != 0) {
      permutation.exists[i,j] <- TRUE
    } else{
      permutation.exists[i,j] <- FALSE
    }    
  }
}
rm(simulation.result, i, j, run)
if (exists("k")) { rm(k) }

################################
## LIFE CYCLE COST PARAMETERS ##
################################
# The significant contribution of this analysis is to quantify the financial performance difference depending on maximum annual capital expenditure
# Parameters:
# 2 lifetimes: 20 years, 30 years
# 3 real discount rates: 2%, 3%, 5%
# NIST GHG scenarios: default, low, high
# NIST energy price scenario: default, low, high
# 5 levels of capital cost allowance: unrestricted, $5/ft^2, $3/ft^2, $2/ft^2, $1/ft^2 (w/wo revolving fund ?) 
#
# Importance of various financial parameters from Rysanek, Choudhary, Energy and Buildings 57 (2013):
# 1) high capital costs, 2) low energy prices, 3) poor tech preformance, 4) no carbon tariffs, 5) lesser decarbonization

lifetime <- 20   # Use a 20 year life time to calculate NPV
discount.rate <- 0.03   # 3% discount rate
nist.ghg.scenario <- 'none' # 'none', 'default', 'high', or 'low'
nist.energy.scenario <- 'none' # 'none' or 'default'
capital.intensity <- 1 # $/ft2 per year investment allowance
revolving.fund <- FALSE
area.m2 <- 5518.33
area.ft2 <- area.m2/(0.3048^2)  
capital.annual <- capital.intensity*area.ft2 
scenario.name <- paste('DR', discount.rate*100,
                       '_LT', lifetime,                         
                       '_GHG', nist.ghg.scenario,
                       '_ENERGY', nist.energy.scenario,
                       '_CI', capital.intensity, sep = '')
debug.flag <- FALSE
run.eachsim.flag <- TRUE
run.expansion.flag <- TRUE
run.paths.flag <- TRUE
save.flag <- TRUE

########################################
## CALCULATE BASELINE LIFE CYCLE COST ##
########################################
print(paste("calculating baseline life-cycle cost..."))

# calculate NPV of baseline case
baseline.annual.elec.cost <- simulation.results$annual.electric.cost[simulation.results$run.name %in% "baseline"]
baseline.annual.gas.cost <- simulation.results$annual.gas.cost[simulation.results$run.name %in% "baseline"]
baseline.elec.costs <- c(-1*rep(baseline.annual.elec.cost, lifetime+1))
baseline.gas.costs <- c(-1*rep(baseline.annual.gas.cost, lifetime+1))
if (nist.energy.scenario != 'none') {
  baseline.elec.costs <- ApplyEscalationRates(baseline.elec.costs, region = "ca1", sector = 'Commercial', 'Electricity', start.year = "2013")
  baseline.gas.costs <- ApplyEscalationRates(baseline.gas.costs, region = "ca1", sector = 'Commercial', 'Natural.Gas', start.year = "2013")
}
baseline.energy.costs <- baseline.elec.costs + baseline.gas.costs
baseline.annual.ghg.emissions <- simulation.results$ghg.emissions[simulation.results$run.name %in% "baseline"]
baseline.ghg.emissions <- c(rep(baseline.annual.ghg.emissions, lifetime+1))
baseline.lifecycle.ghg.emissions <- sum(baseline.ghg.emissions)
if (nist.ghg.scenario != 'none') {
  baseline.ghg.costs <- -ApplyGHGCosts(baseline.ghg.emissions, scenario = "default", start.year = "2013")
} else {
  baseline.ghg.costs <- 0*baseline.ghg.emissions
}
baseline.capital.cost <- c(rep(0, lifetime+1))
baseline.cash.flow <- baseline.capital.cost + baseline.energy.costs + baseline.ghg.costs
baseline.npv <- npv(discount.rate, baseline.cash.flow)

# calculate NPV of baseline case with HVAC replacement measures and cost functions
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
elec.cost <- c(rep(0, lifetime+1))
gas.cost <- c(rep(0, lifetime+1))
ghg.emissions <- c(rep(0, lifetime+1))
if (cu.replace.year < boiler.replace.year) {
  cu.size <- simulation.results$cu.size[simulation.results$run.name %in% cu.letter]
  boiler.size <- simulation.results$boiler.size[simulation.results$run.name %in% cu.boiler.run]
  capital.cost[(cu.replace.year+1)] <- -cu.cost(cu.size)
  capital.cost[(boiler.replace.year+1)] <- -boiler.cost(boiler.size)
  elec.cost[1 : cu.replace.year] <- simulation.results$annual.electric.cost[simulation.results$run.name %in% "baseline"]
  elec.cost[(cu.replace.year+1) : boiler.replace.year] <- simulation.results$annual.electric.cost[simulation.results$run.name %in% cu.letter]
  elec.cost[(boiler.replace.year+1) : (lifetime+1)] <- simulation.results$annual.electric.cost[simulation.results$run.name %in% cu.boiler.run]
  gas.cost[1 : cu.replace.year] <- simulation.results$annual.gas.cost[simulation.results$run.name %in% "baseline"]
  gas.cost[(cu.replace.year+1) : boiler.replace.year] <- simulation.results$annual.gas.cost[simulation.results$run.name %in% cu.letter]
  gas.cost[(boiler.replace.year+1) : (lifetime+1)] <- simulation.results$annual.gas.cost[simulation.results$run.name %in% cu.boiler.run]
  ghg.emissions[1 : cu.replace.year] <- simulation.results$ghg.emissions[simulation.results$run.name %in% "baseline"]
  ghg.emissions[(cu.replace.year+1) : boiler.replace.year] <- simulation.results$ghg.emissions[simulation.results$run.name %in% cu.letter]
  ghg.emissions[(boiler.replace.year+1) : (lifetime+1)] <- simulation.results$ghg.emissions[simulation.results$run.name %in% cu.boiler.run]
} else if (cu.replace.year > boiler.replace.year) {
  boiler.size <- simulation.results$boiler.size[simulation.results$run.name %in% boiler.letter]
  cu.size <- simulation.results$cu.size[simulation.results$run.name %in% boiler.cu.run]
  capital.cost[(boiler.replace.year+1)] <- -boiler.cost(boiler.size)
  capital.cost[(cu.replace.year+1)] <- -cu.cost(cu.size)
  elec.cost[1 : boiler.replace.year] <- simulation.results$annual.electric.cost[simulation.results$run.name %in% "baseline"]
  elec.cost[(boiler.replace.year+1) : cu.replace.year] <- simulation.results$annual.electric.cost[simulation.results$run.name %in% boiler.letter]
  elec.cost[(cu.replace.year+1) : (lifetime+1)] <- simulation.results$annual.electric.cost[simulation.results$run.name %in% boiler.cu.run]
  gas.cost[1 : boiler.replace.year] <- simulation.results$annual.gas.cost[simulation.results$run.name %in% "baseline"]
  gas.cost[(boiler.replace.year+1) : cu.replace.year] <- simulation.results$annual.gas.cost[simulation.results$run.name %in% boiler.letter]
  gas.cost[(cu.replace.year+1) : (lifetime+1)] <- simulation.results$annual.gas.cost[simulation.results$run.name %in% boiler.cu.run]
  ghg.emissions[1 : boiler.replace.year] <- simulation.results$ghg.emissions[simulation.results$run.name %in% "baseline"]
  ghg.emissions[(boiler.replace.year+1) : cu.replace.year] <- simulation.results$ghg.emissions[simulation.results$run.name %in% boiler.letter]
  ghg.emissions[(cu.replace.year+1) : (lifetime+1)] <- simulation.results$ghg.emissions[simulation.results$run.name %in% boiler.cu.run]
} else { #same year replacement
  cu.size <- simulation.results$cu.size[simulation.results$run.name %in% cu.letter]
  boiler.size <- simulation.results$cu.size[simulation.results$run.name %in% boiler.letter]
  capital.cost[(cu.replace.year+1)] <- -cu.cost(cu.size)
  capital.cost[(boiler.replace.year+1)] <- capital.cost[boiler.replace.year+1] - boiler.cost(boiler.size)
  elec.cost[1 : cu.replace.year] <- simulation.results$annual.electric.cost[simulation.results$run.name %in% "baseline"]
  elec.cost[(cu.replace.year+1) : (lifetime+1)] <- simulation.results$annual.electric.cost[simulation.results$run.name %in% cu.boiler.run]
  gas.cost[1 : cu.replace.year] <- simulation.results$annual.gas.cost[simulation.results$run.name %in% "baseline"]
  gas.cost[(cu.replace.year+1) : (lifetime+1)] <- simulation.results$annual.gas.cost[simulation.results$run.name %in% cu.boiler.run]
  ghg.emissions[1 : cu.replace.year] <- simulation.results$ghg.emissions[simulation.results$run.name %in% "baseline"]
  ghg.emissions[(cu.replace.year+1) : (lifetime+1)] <- simulation.results$ghg.emissions[simulation.results$run.name %in% cu.boiler.run]
} 
if (nist.energy.scenario != 'none') {
  elec.cost <- ApplyEscalationRates(elec.cost, region = "ca1", sector = 'Commercial', 'Electricity', start.year = "2013")
  gas.cost <- ApplyEscalationRates(gas.cost, region = "ca1", sector = 'Commercial', 'Natural.Gas', start.year = "2013")
}
baseline.eqrep.energy.costs <- -(elec.cost + gas.cost)
baseline.eqrep.lifecycle.ghg.emissions <- sum(ghg.emissions)
if (nist.ghg.scenario != 'none') {
  baseline.eqrep.ghg.costs <- -ApplyGHGCosts(ghg.emissions, scenario = "default", start.year = "2013")
} else {
  baseline.eqrep.ghg.costs <- 0*ghg.emissions
}
baseline.eqrep.cash.flow <- capital.cost + baseline.eqrep.energy.costs + baseline.eqrep.ghg.costs
baseline.eqrep.npv <- npv(discount.rate, baseline.eqrep.cash.flow)


########################################################
## CALCULATE LIFE CYCLE COST OF EACH UNIQUE SIMULATION##
########################################################
if(run.eachsim.flag) {
  print(paste("calculating life-cycle cost for each unique simulation..."))
  # calculate NPV of each unique simulation, installed in the first year
  # this gives the NPV for path options under the no capital restrictions case
  unique.sim.len = nrow(simulation.results)
  net.present.value <- c(rep(0, unique.sim.len))
  lifecycle.ghg.emissions <- c(rep(0, unique.sim.len))
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
    elec.cost <- c(-1*rep(simulation.results$annual.electric.cost[simulation.results$run.name %in% this.run.name], lifetime+1))
    gas.cost <- c(-1*rep(simulation.results$annual.gas.cost[simulation.results$run.name %in% this.run.name], lifetime+1))
    ghg.emissions <- c(rep(simulation.results$ghg.emissions[simulation.results$run.name %in% this.run.name], lifetime+1))  
    if (nist.energy.scenario != 'none') {
      elec.cost <- ApplyEscalationRates(elec.cost, region = "ca1", sector = 'Commercial', 'Electricity', start.year = "2013")
      gas.cost <- ApplyEscalationRates(gas.cost, region = "ca1", sector = 'Commercial', 'Natural.Gas', start.year = "2013")
    }
    energy.cost <- elec.cost + gas.cost
    if (nist.ghg.scenario != 'none') {
      ghg.costs <- -ApplyGHGCosts(ghg.emissions, scenario = "default", start.year = "2013")
    } else {
      ghg.costs <- 0*ghg.emissions
    }
    cash.flow <- capital.cost + energy.cost + ghg.costs
    net.present.value[i] <- npv(discount.rate, cash.flow)
    lifecycle.ghg.emissions[i] <- sum(ghg.emissions)
  }

  # calculate the NPV relative to the baseline case
  npv.rel.to.base <- net.present.value - c(rep(baseline.npv, unique.sim.len)) 
  npv.rel.to.base.eqrep <-  net.present.value - c(rep(baseline.eqrep.npv, unique.sim.len))
  ghg.rel.to.base <- lifecycle.ghg.emissions/baseline.lifecycle.ghg.emissions
  ghg.rel.to.base.eqrep <- lifecycle.ghg.emissions/baseline.eqrep.lifecycle.ghg.emissions
  simulation.results <- cbind(simulation.results, 
                              net.present.value, 
                              npv.rel.to.base, 
                              npv.rel.to.base.eqrep,
                              ghg.rel.to.base,
                              ghg.rel.to.base.eqrep,
                              discount.rate = discount.rate,
                              lifetime = lifetime, 
                              nist.ghg.scenario = nist.ghg.scenario,
                              nist.energy.scenario = nist.energy.scenario,
                              capital.intensity = capital.intensity)   
  if (save.flag) {
    save(simulation.results, file = paste('./run_scripts/results/unique_sims_', scenario.name, '.RData', sep = ''))
    print(paste('simulation results saved to:', paste('./run_scripts/results/unique_sims_', scenario.name, '.RData', sep = '')))
  }
} # END if(run.eachsim.flag)


##############################
## EXPAND SIMULATION RESULTS##
##############################
if(run.expansion.flag) { 
  # use the permutation.map to populate simulation results for the non-unique simulations
  # this takes a while to run; import it instead if simulations results are unchanged
  
  print(paste("expanding simulation results..."))
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
  rm(i, j, simulation.result)
} # END if(run.expansion.flag)


############################################################################
## CALCULATE LIFE CYCLE COST OF EACH UNIQUE PATH, UNDER CAPITAL CONSTRAINT##
############################################################################
if(run.paths.flag) {
  # calculate the performance of all possible retrofit paths for given financial criteria  
  print(paste("calculating life-cycle cost for each of the", nperms, "paths under capital constraint of $", capital.intensity, "/ft^2"))
  
  # calculate the NPV for the path options under capital restriction scenarios
  # for each permutation row, compare annual capital requirement to the measure cost.
  # If the next measure is less than available capital, then implement it, and other measures that can, otherwise go to next year
  
  if(debug.flag){ nperms <- 1 } # for debugging, use much smaller number of permutations
  net.present.value <- c(rep(0, nperms*num.m))
  last.measure <- c(rep(0, nperms*num.m))
  avg.site.energy.intensity <- c(rep(0, nperms*num.m))
  lifecycle.ghg.emissions <- c(rep(0, nperms*num.m))
  
  for (i in 1:num.m) {
    for (perm.row in 1:nperms) {      
      measure.order <- strsplit(permutations[perm.row, i], "_") 
      capital.cost <- c(rep(0, lifetime+1))
      site.energy.intensity <- c(simulation.results$site.energy.intensity[simulation.results$run.name %in% "baseline"], rep(0, lifetime))
      elec.cost <- c(-baseline.elec.costs[1], rep(0, lifetime))
      gas.cost <- c(-baseline.gas.costs[1], rep(0, lifetime))
      ghg.emissions <- c(baseline.ghg.emissions[1], rep(0, lifetime))
      capital.avail <- capital.annual
      prev.run.name <- "baseline"
      j <- 1 # index to next measure      
      if(debug.flag){ print(paste('')) } ### DEBUGGING LINE ###
      if(debug.flag){ print(paste(" START, path:", permutations[perm.row, i])) } ### DEBUGGING LINE ###      
      yr <- 1
      first.measure.in.year <- TRUE
      
      while (yr <= (lifetime+1)) { # year is an integer, based on the annual simulation limitation in the way the code is constructed
        
        if(debug.flag){ print(paste("year:", yr)) } ### DEBUGGING LINE ### 
        if(debug.flag){ print(paste("capital.avail:", capital.avail)) } ### DEBUGGING LINE ### 
        
        if (j > length(measure.order[[1]])) { # check to see if next measure exists
          run.this.measure <- FALSE
        } else {
          run.this.measure <- TRUE
        }
        if(debug.flag){ print(paste("try.this.measure:", run.this.measure)) } ### DEBUGGING LINE ### 
        
        if (run.this.measure == TRUE) {            
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
          if(debug.flag){ print(paste("measure.cost:", measure.cost)) } ### DEBUGGING LINE ### 
          
          # if capital is available, implement this measure, and use the corresponding simulation run for current year
          if (measure.cost <= capital.avail) { 
            capital.avail <- capital.avail - measure.cost
            capital.cost[yr] <- capital.cost[yr] - measure.cost
            site.energy.intensity[yr] <- simulation.results$site.energy.intensity[simulation.results$run.name %in% this.run.name]
            elec.cost[yr] <- -simulation.results$annual.electric.cost[simulation.results$run.name %in% this.run.name]
            gas.cost[yr] <- -simulation.results$annual.gas.cost[simulation.results$run.name %in% this.run.name]
            ghg.emissions[yr] <- simulation.results$ghg.emissions[simulation.results$run.name %in% this.run.name]
            prev.run.name <- this.run.name
            j <- j + 1 # go to next measure    
            first.measure.in.year <- FALSE
            if(debug.flag){ print(paste("measure:", as.character(measures$letter[measure.index]), "implemented")) } ### DEBUGGING LINE ### 
          } else {
            run.this.measure <- FALSE
          }
          if(debug.flag){ print(paste("measure implemented?:", run.this.measure)) } ### DEBUGGING LINE ### 
          
        } #END run.this.measure == TRUE
        
        if (run.this.measure == FALSE) {
          if (first.measure.in.year == FALSE) {
            # skip to next year
          } else {
            # use the previous simulation run
            site.energy.intensity[yr] <- simulation.results$site.energy.intensity[simulation.results$run.name %in% prev.run.name]        
            elec.cost[yr] <- -simulation.results$annual.electric.cost[simulation.results$run.name %in% prev.run.name]
            gas.cost[yr] <- -simulation.results$annual.gas.cost[simulation.results$run.name %in% prev.run.name]
            ghg.emissions[yr] <- simulation.results$ghg.emissions[simulation.results$run.name %in% prev.run.name]
          }
          if(debug.flag){ print(paste('capital.cost', capital.cost[yr], 'energy.cost', energy.cost[yr], 'cash flow:', capital.cost[yr] + energy.cost[yr])) } ### DEBUGGING LINE ###
          
          # update iteration
          yr <- yr + 1
          first.measure.in.year <- TRUE          
          capital.avail <- capital.avail + capital.annual 
          if (revolving.fund) { # if revolving fund, add energy cost savings to available capital
            # need to account for the time it takes to pay back the capital expenditure; not yet included
            capital.avail <- capital.avail + (energy.cost.baseline.eqrep[yr] - energy.cost[yr])
          }          
        } #END run.this.measure == FALSE          
      } # END while loop
      
    if (nist.energy.scenario != 'none') {
      elec.cost <- ApplyEscalationRates(elec.cost, region = "ca1", sector = 'Commercial', 'Electricity', start.year = "2013")
      gas.cost <- ApplyEscalationRates(gas.cost, region = "ca1", sector = 'Commercial', 'Natural.Gas', start.year = "2013")
    }
    energy.cost <- elec.cost + gas.cost
    if (nist.ghg.scenario != 'none') {
      ghg.costs <- -ApplyGHGCosts(ghg.emissions, scenario = "default", start.year = "2013")
    } else {
      ghg.costs <- 0*ghg.emissions
    }
    cash.flow <- capital.cost + energy.cost + ghg.costs
    net.present.value[(i-1)*nperms + perm.row] <- npv(discount.rate, cash.flow)
    lifecycle.ghg.emissions[(i-1)*nperms + perm.row] <- sum(ghg.emissions)
    last.measure[(i-1)*nperms + perm.row] <- j - 1
    if(debug.flag){ print(paste("LAST measure?:", (j-1))) } ### DEBUGGING LINE ###     
    avg.site.energy.intensity[(i-1)*nperms + perm.row] <- sum(site.energy.intensity)/length(site.energy.intensity)
    
    } # END for n.perms
  } # END for num.m
  
  # calculate the NPV relative to the baseline case
  npv.rel.to.base <- net.present.value - c(rep(baseline.npv, nperms*num.m)) 
  npv.rel.to.base.eqrep <-  net.present.value - c(rep(baseline.eqrep.npv, nperms*num.m))
  ghg.rel.to.base <- lifecycle.ghg.emissions/baseline.lifecycle.ghg.emissions
  ghg.rel.to.base.eqrep <- lifecycle.ghg.emissions/baseline.eqrep.lifecycle.ghg.emissions
  
  path.name <- c(rep(permutations[1:nperms, num.m], num.m))
  for (k in 1:(nperms*num.m)) {
    path.name[k] = substr(path.name[k], 1, last.measure[k] + (last.measure[k]-1))
  }
  
  # create data frame of retrofit paths
  paths <- data.frame(path.name,
                      net.present.value, 
                      npv.rel.to.base, 
                      npv.rel.to.base.eqrep,
                      avg.site.energy.intensity,
                      lifecycle.ghg.emissions,
                      ghg.rel.to.base, 
                      ghg.rel.to.base.eqrep,                      
                      discount.rate = discount.rate, 
                      lifetime = lifetime, 
                      nist.ghg.scenario = nist.ghg.scenario,
                      nist.energy.scenario = nist.energy.scenario,
                      capital.intensity = capital.intensity)
  unique.paths <- unique(paths)  
  if (save.flag) {
    save(unique.paths, file = paste('./run_scripts/results/retrofit_paths_', scenario.name, '.RData', sep = ''))
    print(paste('simulation results saved to:', paste('./run_scripts/results/retrofit_paths_', scenario.name, '.RData', sep = '')))
  }  
} #END If(run.paths.flag)