#RetrofitPermute.R
# Reads in measure names and generates all possible permutations.
# A copy of the list replaces permutations with combinations with identical simulation results.  
# E.g., if to measures are independent, then ab = ba, whereas for a third, independent measure c, ac <> ca.
# This copy is a "map" to back to the original permutation.  Finally, only unique simulations in the map are identified for simulation.  
# Saves permutation list, map, simulations required, and cost array to an .RData file.
#
# Building Science Group 2014
#
# Contributors: 
# Matthew G. Dahlhausen
#
# Package Dependencies: 
#
# clear all: 
rm(list=ls())
#
# function dependencies
source("./lib/permute.R")
source("./lib/vectorRecursion.R")

#list all files in the measure directory
measure.names <- list.dirs(path="./measures/",
                           full.names=FALSE,
                            recursive=FALSE)
measure.names
num.m <- length(measure.names)
if(num.m > 9) { stop("too many measures!") }

# Import costs for each measure.  
# costs are treated as functions.
# most return a fixed value, though some take in sizing information
# set null default argument as false
measure.cost.funclist <- list()
measure.dependence <- c(rep(0, num.m))
tryCatch(rm(cost, dependence), warning = function(w){})  # silent
i <- 1
for (measure in measure.names) {
  tryCatch({  
    source(paste("./measures/", measure, "/cost.R", sep=""))
      if(exists("cost")) {
        measure.cost.funclist[[i]] <- cost
        rm(cost)
      } else {
        stop(paste("invalid cost function in measure:", measure))
      }    
    },
    warning = function(w) {
      print(paste(measure, "does not have a cost.R file"))
    },
    error = function(e) { 
      print(paste(measure, "error reading cost.R file"))
    }
  )  
  tryCatch({
    source(paste("./measures/", measure, "/measure_flags.R", sep=""))
      if(exists("dependence")) {
        measure.dependence[i] <- dependence
        rm(dependence)
      } else {
        stop(paste("invalid dependence in measure:", measure))
      }     
    },
    warning = function(w) {
      print(paste(measure, "does not have a measure_flags.R file"))
    },
    error = function(e) { 
      print(paste(measure, "error reading measure_flags.R file"))
    }
  )  
  i <- i+1  
}
rm(measure, i)

# map measure names to letters for easier reading
measures <- data.frame(letter = letters[1:num.m],
                       name = measure.names,
                       depend = measure.dependence)

# generate all ordered permutations 
permutations <- matrix(measures$letter[permute(num.m)],ncol=num.m)  

# replace permutations with the simulation run name
for (i in 1:length(permutations[,1])) {  
  for (j in num.m:2) {
    permutations[i, j] <- vectorRecursion(permutations[i, 1:j], j)  
  }  
}

# generate the combinations for each pair
nondep <- combn(measures$letter[measures$depend %in% 0], 2, simplify = TRUE)
nondep.string <- apply(format(nondep), 2, paste, collapse="_")
nondep.rev <- nondep[nrow(nondep):1,]
nondep.rev.string <- apply(format(nondep.rev), 2, paste, collapse="_")

# create a map for the permutations to reference the simulation to refer to
permutations.map <- permutations

# search through the permutations for each reverse pair and replace it with the first pair
# keep doing this for the maximum length of a non-dependent string, 
# which is equal to the number of nondependent measures
max.len <- sum(measures$depend %in% 0)
for (i in 1:max.len) {
  for (j in 1:length(nondep.rev.string)) {
    permutations.map <- gsub(nondep.rev.string[j], nondep.string[j], permutations.map)
  }
}

# unique simulations
unique.sims <- unique(as.vector(permutations.map))
print(paste(length(unique.sims),"unique simulations", 
            "reduced from", 
            length(unique(as.vector(permutations))),
            "permutations"))
print(paste("estimated simulation time of",
            length(unique.sims)*3,
            "minutes,",
            length(unique.sims)*3/60,
            "hours"))

#save data to .RData file
save(measures,
     measure.cost.funclist,
     num.m,
     permutations, 
     permutations.map,
     file="./measures/measure_permutations.RData")
write(unique.sims, file="./measures/unique_sims.txt")
write.table(measures, file="./measures/measure_map.txt",
            quote=FALSE, row.names=FALSE, col.names=FALSE)
# clear all
rm(list=ls())