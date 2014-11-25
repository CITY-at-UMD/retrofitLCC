# ResultsReader.R
# reads in the simulation results and saves them to an .RData file.
#
# Building Science Group 2014
#
# Contributors: 
# Matthew G. Dahlhausen
#
# Package Dependencies: 
library(DBI) # interface definitions for communicating with relational databases
library(RSQLite)  # embeds SQLite database in R for DBI
library(sqldf) # perform SQL selects on R data frames
#
# 
rm(list=ls())  # clear variables 

print(paste("reading simulation results..."))
# locate directories where to find .sql files
dirs <- list.dirs(path = "./run_scripts/results",
                                    recursive = FALSE)
num.dirs <- length(dirs)
run.names <- gsub(".*/results/","", dirs)

# read all .sql files in data folders
sql.files <- c(rep("", num.dirs))
missing.sql.files <- c(rep("", num.dirs))
for (i in 1:num.dirs) {
  sql.exists <- list.files(path = dirs[i], 
                             pattern="*.sql", 
                             recursive = TRUE,
                             include.dirs = TRUE,
                             full.names = TRUE)
  if(length(sql.exists) == 0) {
    print(paste(".sql file for", run.names[i], "not found"))
    missing.sql.files <- run.names[i]
  } else {
    sql.files[i] <- sql.exists
  }
}

#only keep valid sql files
run.names <- run.names[lapply(sql.files, nchar) > 0] 
sql.files <- sql.files[lapply(sql.files, nchar) > 0]
num.files <- length(sql.files)

# sql statements for accessing primary information
site.energy.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName = 'Site and Source Energy' AND RowName = 'Total Site Energy' And ColumnName = 'Total Energy'"
source.energy.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName = 'Site and Source Energy' AND RowName = 'Total Source Energy' And ColumnName = 'Total Energy'"
site.energy.intensity.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName = 'Site and Source Energy' AND RowName = 'Total Site Energy' And ColumnName = 'Energy Per Total Building Area'"
source.energy.intensity.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName = 'Site and Source Energy' AND RowName = 'Total Source Energy' And ColumnName = 'Energy Per Total Building Area'"
annual.electric.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName = 'End Uses' AND RowName = 'Total End Uses' And ColumnName = 'Electricity'"
annual.gas.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName = 'End Uses' AND RowName = 'Total End Uses' And ColumnName = 'Natural Gas'" 
peak.electric.demand.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'EnergyMeters' AND ReportForString='Entire Facility' AND TableName = 'Annual and Peak Values - Electricity' AND RowName = 'Electricity:Facility' And ColumnName = 'Electricity Maximum Value'"
ghg.emissions.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'EnergyMeters' AND ReportForString='Entire Facility' AND TableName = 'Annual and Peak Values - Other by Weight/Mass' AND RowName = 'CarbonEquivalentEmissions:Carbon Equivalent' And ColumnName = 'Annual Value'"
annual.electric.cost.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'Economics Results Summary Report' AND ReportForString='Entire Facility' AND TableName = 'Annual Cost' AND RowName = 'Cost' And ColumnName = 'Electric'"
annual.gas.cost.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'Economics Results Summary Report' AND ReportForString='Entire Facility' AND TableName = 'Annual Cost' AND RowName = 'Cost' And ColumnName = 'Gas'"
total.annual.energy.cost.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'Economics Results Summary Report' AND ReportForString='Entire Facility' AND TableName = 'Annual Cost' AND RowName = 'Cost' And ColumnName = 'Total'"
annual.energy.cost.intensity.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'Economics Results Summary Report' AND ReportForString='Entire Facility' AND TableName = 'Annual Cost' AND RowName = 'Cost per Total Building Area' And ColumnName = 'Total'"
boiler.size.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'EquipmentSummary' AND ReportForString='Entire Facility' AND TableName = 'Central Plant' AND ColumnName = 'Nominal Capacity'"
cu.size.sql <- "SELECT RowName, Value, Units FROM TabularDataWithStrings WHERE ReportName = 'EquipmentSummary' AND ReportForString='Entire Facility' AND TableName = 'Cooling Coils' AND ColumnName = 'Nominal Total Capacity'"

# placeholder variable values and units for data.frame
vars <- c("site.energy", "site.energy.units", "source.energy", "source.energy.units", 
          "site.energy.intensity", "site.energy.intensity.units", "source.energy.intensity", "source.energy.intensity.units", 
          "annual.electric", "annual.electric.units", "annual.gas", "annual.gas.units",
          "peak.electric.demand", "peak.electric.demand.units", "ghg.emissions", "ghg.emissions.units",
          "annual.electric.cost", "annual.electric.cost.units", "annual.gas.cost", "annual.gas.cost.units",
          "total.annual.energy.cost", "total.annual.energy.cost.units", 
          "annual.energy.cost.intensity", "annual.energy.cost.intensity.units",
          "boiler.size", "cu.size")
for (var in vars) {
  assign(var, c(rep(0,num.files)))
}

# make data.frame of results from energy simulations in folder 'data'
for (i in 1:num.files) {
  sql.file <- sql.files[i]
  run.name <- run.names[i]
  tryCatch({
    site.energy[i] <- as.numeric(sqldf(site.energy.sql, dbname = sql.file)[,"Value"])
    site.energy.units[i] <- sqldf(site.energy.sql, dbname = sql.file)[,"Units"]        
  }, error = function(e) {print(paste("site.energy unavailable for run:", run.name))})  
  tryCatch({
    source.energy[i] <- as.numeric(sqldf(source.energy.sql, dbname = sql.file)[,"Value"])
    source.energy.units[i] <- sqldf(source.energy.sql, dbname = sql.file)[,"Units"]    
  }, error = function(e) {print(paste("source.energy unavailable for run:", run.name))}) 
  tryCatch({
    site.energy.intensity[i] <- as.numeric(sqldf(site.energy.intensity.sql, dbname = sql.file)[,"Value"])
    site.energy.intensity.units[i] <- sqldf(site.energy.intensity.sql, dbname = sql.file)[,"Units"]        
  }, error = function(e) {print(paste("site.energy.intensity unavailable for run:", run.name))}) 
  tryCatch({
    source.energy.intensity[i] <- as.numeric(sqldf(source.energy.intensity.sql, dbname = sql.file)[,"Value"])
    source.energy.intensity.units[i] <- sqldf(source.energy.intensity.sql, dbname = sql.file)[,"Units"]        
  }, error = function(e) {print(paste("source.energy.intensity unavailable for run:", run.name))}) 
  tryCatch({
    annual.electric[i] <- as.numeric(sqldf(annual.electric.sql, dbname = sql.file)[,"Value"])
    annual.electric.units[i] <- sqldf(annual.electric.sql, dbname = sql.file)[,"Units"]        
  }, error = function(e) {print(paste("annual.electric unavailable for run:", run.name))}) 
  tryCatch({
    annual.gas[i] <- as.numeric(sqldf(annual.gas.sql, dbname = sql.file)[,"Value"])
    annual.gas.units[i] <- sqldf(annual.gas.sql, dbname = sql.file)[,"Units"]        
  }, error = function(e) {print(paste("annual.gas unavailable for run:", run.name))})   
  tryCatch({
    peak.electric.demand[i] <- as.numeric(sqldf(peak.electric.demand.sql, dbname = sql.file)[,"Value"])
    peak.electric.demand.units[i] <- sqldf(peak.electric.demand.sql, dbname = sql.file)[,"Units"]        
  }, error = function(e) {print(paste("peak.electric.demand unavailable for run:", run.name))}) 
  tryCatch({
    ghg.emissions[i] <- as.numeric(sqldf(ghg.emissions.sql, dbname = sql.file)[,"Value"])
    ghg.emissions.units[i] <- sqldf(ghg.emissions.sql, dbname = sql.file)[,"Units"]        
  }, error = function(e) {print(paste("ghg.emissions unavailable for run:", run.name))}) 
  tryCatch({
    annual.electric.cost[i] <- as.numeric(sqldf(annual.electric.cost.sql, dbname = sql.file)[,"Value"])
    annual.electric.cost.units[i] <- sqldf(annual.electric.cost.sql, dbname = sql.file)[,"Units"]        
  }, error = function(e) {print(paste("annual.electric.cost unavailable for:", run.name))}) 
  tryCatch({
    annual.gas.cost[i] <- as.numeric(sqldf(annual.gas.cost.sql, dbname = sql.file)[,"Value"])
    annual.gas.cost.units[i] <- sqldf(annual.gas.cost.sql, dbname = sql.file)[,"Units"]        
  }, error = function(e) {print(paste("annual.gas.cost unavailable for run:", run.name))}) 
  tryCatch({
    total.annual.energy.cost[i] <- as.numeric(sqldf(total.annual.energy.cost.sql, dbname = sql.file)[,"Value"])
    total.annual.energy.cost.units[i] <- sqldf(total.annual.energy.cost.sql, dbname = sql.file)[,"Units"]        
  }, error = function(e) {print(paste("total.annual.energy.cost unavailable for run:", run.name))}) 
  tryCatch({
    annual.energy.cost.intensity[i] <- as.numeric(sqldf(annual.energy.cost.intensity.sql, dbname = sql.file)[,"Value"])
    annual.energy.cost.intensity.units[i] <- sqldf(annual.energy.cost.intensity.sql, dbname = sql.file)[,"Units"]        
  }, error = function(e) {print(paste("annual.energy.cost.intensity unavailable for run:", run.name))}) 
  tryCatch({
    boiler.size[i] <- as.numeric(sqldf(boiler.size.sql, dbname = sql.file)[,"Value"])    
  }, error = function(e) {print(paste("boiler.size unavailable for run:", run.name))}) 
  tryCatch({
    cu.size[i] <- sum(as.numeric(sqldf(cu.size.sql, dbname = sql.file)[,"Value"])) 
  }, error = function(e) {print(paste("cu.size unavailable for run:", run.name))}) 
}

# bind them together to create the data.frame
simulation.results <- data.frame(run.name = run.names, site.energy, site.energy.units, source.energy, source.energy.units, 
                                 site.energy.intensity, site.energy.intensity.units, source.energy.intensity, source.energy.intensity.units, 
                                 annual.electric, annual.electric.units, annual.gas, annual.gas.units,
                                 peak.electric.demand, peak.electric.demand.units, ghg.emissions, ghg.emissions.units,
                                 annual.electric.cost, annual.electric.cost.units, annual.gas.cost, annual.gas.cost.units,
                                 total.annual.energy.cost, total.annual.energy.cost.units, 
                                 annual.energy.cost.intensity, annual.energy.cost.intensity.units,
                                 boiler.size, cu.size, 
                                 stringsAsFactors=FALSE)
save(simulation.results, file="./run_scripts/results/simulation_results.RData")
print(paste("simulation results saved to: ./run_scripts/results/simulation_results.RData"))
rm(list=ls()) 