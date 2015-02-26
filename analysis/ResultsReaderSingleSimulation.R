# ResultsReaderSingleSimulation.R
# Reads in the simulation results for a single simulation generates load component information and energy use breakdown.
#
# Building Science Group 2014
#
# Contributors: 
# Matthew G. Dahlhausen
#
# Package Dependencies: 
library(sqldf) # perform SQL selects on R data frames
library(ggplot2)
library(reshape2)
library(grid)
library(ggplot2)
library(scales)
library(reshape2)
library(gridExtra)
library(zoo)
source('./lib/multiplot.R')
#
# Data requirements: 
# .sql file WITH LOAD COMPONENTS.  See example .idf file in ./model/load components for a list of what to include, or read from the .rdd file 
#
# Recommend clearing variables, as data.frames from sql files are memory intensive
rm(list=ls())  

# function for formating numbers in plots
fmt <- function(){
  function(x) format(x,nsmall=2,scientific=FALSE)
}


##########################
# ZONE LOAD COMPONENTS ##
#########################
# Note: The EnergyPlus Output is limmited to 255 output variables, which will not allow reporting all the variables necessary for total load balance on each zone. 
# To override this, see the section on ReadVarsESO in the EnergyPlus InputOutputReference
# 

# Read .sql file in data folder, or type .sql filename here: sql.file <- "myfile.sql"
sql.file <- list.files(path="./model/load components/", pattern="*.sql", full.names = TRUE)
sql.file <- sql.file[1]

# Load variable data dictionary
variable.data.dictionary <- sqldf("SELECT * FROM ReportVariableDataDictionary", dbname = sql.file)
load.names <- sqldf("SELECT distinct VariableName FROM ReportVariableDataDictionary", dbname = sql.file)

# Load time table.  Function changes necessary if not reported in 1/2 hour increments
time <- sqldf("SELECT * FROM Time", dbname = sql.file)

# Determine zone loads for a specific load, e.g. Zone Infiltration Sensible Heat Gain Energy
LoadsByType <- function(sql.filename, VariableName) {
  # load variable data dictionary if not present
  if (!exists("variable.data.dictionary")) {
    tryCatch({
      sql.statement <- "SELECT * FROM ReportVariableDataDictionary"
      variable.data.dictionary <- sqldf(sql.statement, dbname = sql.file)
    }, error = function(err) {
      stop("variable.data.dictionary not found!")
    }, finally = {})
  }
  # Check for SQL file
  if (!exists("sql.file")) {
    stop("sql.file not found!")
  }
  
  index.in.dictionary <- variable.data.dictionary$VariableName == VariableName
    if (sum(index.in.dictionary) == 0) {
      stop(paste(VariableName, " not found in variable data dictionary"))
    }  
  data.index <- variable.data.dictionary$ReportVariableDataDictionaryIndex[index.in.dictionary]  
  index.numbers <- paste(data.index, collapse = ',')
  sql.begin <- "SELECT * FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN "
  sql.statement <- paste(sql.begin, "(", index.numbers, ")", sep="")
  print(paste("loading '", VariableName, "' instances from '", sql.filename, "'...", sep=""))
  data <- sqldf(sql.statement, dbname = sql.filename)
  
  # Drop extraneous column
  drop <- "ReportVariableExtendedDataIndex"
  data <- data[,!(names(data) %in% drop)]
  
  # Replace ReportVariableDataDictionaryIndex in data with KeyValue from variable.data.dictionary
  for (i in data.index) {
    data$ReportVariableDataDictionaryIndex[data$ReportVariableDataDictionaryIndex == i] <- variable.data.dictionary$KeyValue[variable.data.dictionary$ReportVariableDataDictionaryIndex == i]
  }
  col.index <- grep("ReportVariableDataDictionaryIndex", colnames(data))
  colnames(data)[col.index] <- "KeyValue"
  
  # Replace TimeIndex with Hour.  Replace with the appropriate time series in the future.
  for (i in 1:length(data.index)){
    start = (i-1)*8760 + 1
    end = i*8760
    data$TimeIndex[start:end] <- 1:8760
  }
  col.index <- grep("TimeIndex", colnames(data))
  colnames(data)[col.index] <- "Hour"
  print(paste("data.frame size:", format(object.size(data), units = "Mb")))
  
  return(data)
}

# Determine all loads in a zone
LoadsByZone <- function(sql.filename, VariableName) {  
  stop("function in development")
}

SumLoadByHour <- function(df) {
  load.sum <- aggregate(VariableValue ~ Hour, data = df, FUN = sum)
  return(load.sum)
}

SumLoadByZone <- function(df) {
  load.sum <- aggregate(df$VariableValue, by = list(df$KeyValue), FUN = sum)
  col.names(load.sum) <- c("KeyValue","Value") 
  return(load.sum)
}


people.sensible <- SumLoadByHour(LoadsByType(sql.file, "Zone People Sensible Heating Rate"))
lights.total <- SumLoadByHour(LoadsByType(sql.file, "Zone Lights Total Heating Rate"))
elec.equipment.radiant <- SumLoadByHour(LoadsByType(sql.file, "Zone Electric Equipment Radiant Heating Rate"))
elec.equipment.convective <- SumLoadByHour(LoadsByType(sql.file, "Zone Electric Equipment Convective Heating Rate"))
window.gain <- SumLoadByHour(LoadsByType(sql.file, "Zone Windows Total Heat Gain Rate"))
window.loss <- SumLoadByHour(LoadsByType(sql.file, "Zone Windows Total Heat Loss Rate"))
infiltration <- SumLoadByHour(LoadsByType(sql.file, "Zone Air Heat Balance Outdoor Air Transfer Rate"))
interzone <- SumLoadByHour(LoadsByType(sql.file, "Zone Air Heat Balance Interzone Air Transfer Rate"))
system.air<- SumLoadByHour(LoadsByType(sql.file, "Zone Air Heat Balance System Air Transfer Rate"))
system.convective <- SumLoadByHour(LoadsByType(sql.file, "Zone Air Heat Balance System Convective Heat Gain Rate"))
opaque.conduction <- (people.sensible + lights.total + elec.equipment.radiant + 
                      elec.equipment.convective + window.gain - window.loss + infiltration + 
                      interzone + system.air + system.convective)$VariableValue
opaque.conduction <- as.data.frame(cbind(Hour = people.sensible$Hour, VariableValue = opaque.conduction))
sensible.heat.gains <- data.frame(Hour = people.sensible$Hour,
                                  people.sensible = people.sensible$VariableValue,
                                  lights.total  = lights.total$VariableValue,
                                  elec.equipment = (elec.equipment.radiant$VariableValue + elec.equipment.convective$VariableValue),
                                  window = (window.gain$VariableValue - window.loss$VariableValue),
                                  infiltration = infiltration$VariableValue, 
                                  interzone = interzone$VariableValue, 
                                  hvac = (system.air$VariableValue + system.convective$VariableValue),
                                  surface.transfer.and.residual = opaque.conduction$VariableValue)

sensible.heat.gain.summary <- sqldf("SELECT * FROM TabularDataWithStrings WHERE ReportName = 'SensibleHeatGainSummary'", dbname = sql.file)

# calculate the difference?
window.solar <- SumLoadByHour(LoadsByType(sql.file, "Zone Windows Total Transmitted Solar Radiation Rate"))
total.internal.radiant <- SumLoadByHour(LoadsByType(sql.file, "Zone Total Internal Radiant Heating Rate"))
total.internal.convective <- SumLoadByHour(LoadsByType(sql.file, "Zone Total Internal Convective Heating Rate"))
air.internal.convective <- SumLoadByHour(LoadsByType(sql.file, "Zone Air Heat Balance Internal Convective Heat Gain Rate"))
air.storage <- SumLoadByHour(LoadsByType(sql.file, "Zone Air Heat Balance Air Energy Storage Rate"))
air.surface <- SumLoadByHour(LoadsByType(sql.file, "Zone Air Heat Balance Surface Convection Rate"))
opaque.gain <- SumLoadByHour(LoadsByType(sql.file, "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Rate"))
opaque.loss <- SumLoadByHour(LoadsByType(sql.file, "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Rate"))

#calculate annual and peak load information - import from SensibleHeatGainSummary?
all.loads <- cbind(sensible.heat.gains, 
                   window.solar = window.solar$VariableValue, 
                   total.internal.radiant = total.internal.radiant$VariableValue, 
                   air.internal.convective = air.internal.convective$VariableValue, 
                   air.storage = air.storage$VariableValue, 
                   air.surface = air.surface$VariableValue, 
                   opaque.transfer = (opaque.gain$VariableValue - opaque.loss$VariableValue)) 

load.components <- sqldf("SELECT * FROM TabularDataWithStrings WHERE ReportName = 'ZoneComponentLoadSummary'", dbname = sql.file)
unique.zones <- sqldf("SELECT distinct ReportForString FROM TabularDataWithStrings WHERE ReportName = 'ZoneComponentLoadSummary'", dbname = sql.file)$ReportForString
unique.loads <- sqldf("SELECT distinct RowName FROM TabularDataWithStrings WHERE ReportName = 'ZoneComponentLoadSummary' and ColumnName <> 'Value' and RowName <> 'Grand Total'", dbname = sql.file)$RowName

# peak cooling components
df <- load.components[load.components$TableName %in% c("Estimated Cooling Peak Load Components"),]
df.peak.by.zone <- df[(df$RowName %in% c("Grand Total") & df$ColumnName %in% c("Total")),]
total.load <- sum(as.double(df.peak.by.zone$Value))
zone.weights <- data.frame(zones = unique.zones, weight = as.double(df.peak.by.zone$Value) / total.load)
percents <- df[df$ColumnName %in% c("%Grand Total"),]
contribution.by.load <- matrix(nrow = length(unique.loads), ncol = length(unique.zones))
dimnames(contribution.by.load) <- list(unique.loads, unique.zones)
for (load in unique.loads) {    
  for (zone in unique.zones) {
    # load = zone weight * percent contribution of that load to total zone load at peak
    contribution.by.load[load, zone] <-  
      zone.weights$weight[zone.weights$zones %in% zone] * 
      as.double(percents$Value[(percents$RowName %in% c(load) & percents$ReportForString %in% c(zone))])
  }
}
peak.cooling.load.percents <- data.frame(variable = rownames(contribution.by.load), percent = rowSums(contribution.by.load))

# peak heating components
df <- load.components[load.components$TableName %in% c("Estimated Heating Peak Load Components"),]
df.peak.by.zone <- df[(df$RowName %in% c("Grand Total") & df$ColumnName %in% c("Total")),]
total.load <- sum(as.double(df.peak.by.zone$Value))
zone.weights <- data.frame(zones = unique.zones, weight = as.double(df.peak.by.zone$Value) / total.load)
percents <- df[df$ColumnName %in% c("%Grand Total"),]
contribution.by.load <- matrix(nrow = length(unique.loads), ncol = length(unique.zones))
dimnames(contribution.by.load) <- list(unique.loads, unique.zones)
for (load in unique.loads) {    
  for (zone in unique.zones) {
    # load = zone weight * percent contribution of that load to total zone load at peak
    contribution.by.load[load, zone] <-  
      zone.weights$weight[zone.weights$zones %in% zone] * 
      as.double(percents$Value[(percents$RowName %in% c(load) & percents$ReportForString %in% c(zone))])
  }
}
peak.heating.load.percents <- data.frame(variable = rownames(contribution.by.load), percent = rowSums(contribution.by.load))

#########
# PLOTS #
#########

loads.plot <- melt(all.loads[1:168,], id.vars = "Hour")
loads.plot <- ggplot(data = loads.plot, aes(x = Hour,  y = value, color = variable)) + 
  geom_line() + 
  theme_minimal()
plot(loads.plot)

df <- peak.heating.load.percents[peak.heating.load.percents$percent != 0 | peak.cooling.load.percents$percent != 0, ]
df$percent <- df$percent/100
peak.heating <- ggplot(data = df, aes(x = variable, y = percent)) + 
  geom_bar(stat="identity", ymin = 0, fill = "grey80") +
  geom_text(aes(x = variable, y = percent, label = percent(round(percent, 2)), hjust=ifelse(sign(percent)>0, 1, 0))) +
  scale_y_continuous(labels = percent_format()) +
  coord_flip() + 
  labs(title = "Peak Heating Loads") +
  theme(title = element_text(face = 'bold', size = 18),
        panel.background = element_blank(), 
        panel.grid.major.x = element_line(size=0.5, linetype = 'solid', color='#999999'),
        axis.text.y = element_text(face = 'bold', color = "grey20", size = 16, hjust = 0.5), 
        axis.text.x = element_text(color = "grey20", size = 16),
        axis.ticks.y = element_blank(),
        axis.title = element_blank(),
        axis.line = element_line(size=1, color="#999999"), 
        axis.line.y = element_blank())
df <- peak.cooling.load.percents[peak.heating.load.percents$percent != 0 | peak.cooling.load.percents$percent != 0, ]
df$percent <- df$percent/100
peak.cooling <- ggplot(data = df, aes(x = variable, y = percent)) + 
  geom_bar(stat="identity", ymin = 0, fill = "grey80") +  
  geom_text(aes(x = variable, y = percent, label = percent(round(percent, 2)), hjust=ifelse(sign(percent)>0, 1, 0))) +
  scale_y_continuous(labels = percent_format()) +
  coord_flip() +
  labs(title = "Peak Cooling Loads") +
  theme(title = element_text(face = 'bold', size = 16),
        panel.background = element_blank(),
        panel.grid.major.x = element_line(size=0.5, linetype = 'solid', color='#999999'),
        axis.title = element_blank(), 
        axis.text.y = element_blank(),
        axis.text.x = element_text(color = "grey20", size = 16),
        axis.ticks.y = element_blank(),
        axis.line = element_line(size=1, color="#999999"), 
        axis.line.y = element_blank())

pushViewport(viewport(layout = grid.layout(2, 5, heights = unit(c(1, 9), "null"))))
grid.text("(b) Percent Contributions of Component Loads to Thermal Zones' Peak Heating and Cooling", vp = viewport(layout.pos.row = 1, layout.pos.col = 1:5))
print(peak.cooling, vp = viewport(layout.pos.row = 2, layout.pos.col = 1:2))
print(peak.heating, vp = viewport(layout.pos.row = 2, layout.pos.col = 3:5))

######################################################
# SENSIBLE PEAK COMPONENTS, AVAILABLE IN OUTPUT HTML #
######################################################

# sql statements for accessing primary information
peak.heat.sql <- "SELECT * FROM TabularDataWithStrings WHERE TABLENAME='Peak Heating Sensible Heat Gain Components' AND ROWNAME='Total Facility'"
peak.cool.sql <- "SELECT * FROM TabularDataWithStrings WHERE TABLENAME='Peak Cooling Sensible Heat Gain Components' AND ROWNAME='Total Facility'"
peak.heat.df <- sqldf(peak.heat.sql, dbname = sql.file)[,c("ColumnName","Value","Units")]
peak.cool.df <- sqldf(peak.cool.sql, dbname = sql.file)[,c("ColumnName","Value","Units")]
peak.heat.amt <- as.numeric(peak.heat.df[(peak.heat.df$ColumnName == "HVAC Input Sensible Air Heating"),"Value"])
peak.cool.amt <- as.numeric(peak.cool.df[(peak.cool.df$ColumnName == "HVAC Input Sensible Air Cooling"),"Value"])
peak.heat.df <- peak.heat.df[!(peak.heat.df$ColumnName %in% c('Time of Peak','HVAC Input Sensible Air Heating','HVAC Input Sensible Air Cooling',
                                                              'HVAC Input Heated Surface Heating','HVAC Input Cooled Surface Cooling',
                                                              'Interzone Air Transfer Heat Addition','Interzone Air Transfer Heat Removal',
                                                              'Equipment Sensible Heat Removal','Opaque Surface Conduction and Other Heat Addition',
                                                              'Window Heat Addition','Infiltration Heat Addition')),]
peak.cool.df <- peak.cool.df[!(peak.cool.df$ColumnName %in% c('Time of Peak','HVAC Input Sensible Air Heating','HVAC Input Sensible Air Cooling',
                                                              'HVAC Input Heated Surface Heating','HVAC Input Cooled Surface Cooling',
                                                              'Interzone Air Transfer Heat Addition','Interzone Air Transfer Heat Removal',
                                                              'Equipment Sensible Heat Removal','Opaque Surface Conduction and Other Heat Addition',
                                                              'Window Heat Removal','Infiltration Heat Removal')),]
peak.loads <- data.frame(name=c('People','Lights','Equipment','Windows','Infiltration','Opaque Surfaces'),
                         heat=-100*as.numeric(peak.heat.df$Value)/peak.heat.amt,
                         cool=-100*as.numeric(peak.cool.df$Value)/peak.cool.amt)

peak.plot1 <- ggplot(data = peak.loads, aes(x=name, y=heat)) +
  geom_bar(stat="identity", fill='grey40') +
  ylab("% Contribution to Peak Load") + 
  coord_cartesian(ylim=c(-20, 60)) +
  scale_y_continuous(breaks=seq(-20, 60, by=20)) + 
  xlab('') + 
  labs(title='(b) Peak Heating Loads') +
  coord_flip() +
  theme(title = element_text(face = 'bold', size = 18),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey20", size=0.5),
        panel.grid.minor = element_line(color = "grey80", size=0.5),
        axis.text.y = element_blank(),
        axis.text.x = element_text(color = "grey20", size = 16))
peak.plot2 <- ggplot(data = peak.loads, aes(x=name, y=cool)) +
  geom_bar(stat="identity", , fill='grey40') +
  ylab("% Contribution to Peak Load") + 
  coord_cartesian(ylim=c(-20, 80)) +
  scale_y_continuous(breaks=seq(-20, 80, by=20)) + 
  xlab('') + 
  labs(title='(c) Peak Cooling Loads') +
  coord_flip() +
  theme(title = element_text(face = 'bold', size = 18),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey20", size=0.5),
        panel.grid.minor = element_line(color = "grey80", size=0.5),
        axis.text.y = element_text(color = "grey20", size = 16, face = 'bold', hjust = 0),
        axis.text.x = element_text(color = "grey20", size = 16))
library(grid)
pushViewport(viewport(layout = grid.layout(1, 7)))
print(peak.plot1, vp = viewport(layout.pos.row = 1, layout.pos.col = 1:3))
print(peak.plot2, vp = viewport(layout.pos.row = 1, layout.pos.col = 4:7))


###################################################
# ANNUAL ENERGY END USE, AVAILABLE IN OUTPUT HTML #
###################################################
end.use.sql <- "SELECT * FROM TabularDataWithStrings WHERE REPORTNAME='AnnualBuildingUtilityPerformanceSummary' AND TABLENAME='End Uses' AND (COLUMNNAME = 'Electricity' OR COLUMNNAME ='Natural Gas')"
end.use.df <- sqldf(end.use.sql, dbname = sql.file)[,c("RowName","ColumnName","Value","Units")]
end.use.df <- end.use.df[!(end.use.df$RowName %in% c('','Exterior Lighting','Exterior Equipment','Heat Rejection',
                                                     'Humidification','Heat Recovery','Refrigeration','Generators',
                                                     'Total End Uses')),]
end.use.df$RowName[grep("Interior Lighting",end.use.df$RowName)] <- "Lighting"
end.use.df$RowName[grep("Interior Equipment",end.use.df$RowName)] <- "Equipment"
end.use.df$RowName[grep("Water Systems",end.use.df$RowName)] <- "Hot Water"
end.use.df$Value <- as.numeric(end.use.df$Value)
end.use.df <- end.use.df[!(end.use.df$Value == 0),]
end.use.df <- aggregate( cbind(Value) ~ RowName + Units, data = end.use.df, FUN = sum)
end.use.df <- end.use.df[order(end.use.df$Value, decreasing = TRUE),]
end.use.df <- cbind(end.use.df, plot=c(1))
for (i in 1:length(end.use.df[,1])) {
  if(i == 1){
    add <- data.frame(RowName=as.character(end.use.df$RowName[i]),Units='GJ',
                      Value=0,plot=0)  
  } else {
    add <- data.frame(RowName=as.character(end.use.df$RowName[i]),Units='GJ',
                      Value=sum(end.use.df$Value[1:i-1]),plot=0)
  }
  end.use.df <- rbind(end.use.df,add)
}
end.use.df <- end.use.df[order(end.use.df$plot),]

area.m2 <- 5518.33
area.ft2 <- area.m2/(0.3048^2)  
eui_conv <- 0.947817120/10.7639
end.use.plot <- ggplot(data = end.use.df,
                       aes(x=reorder(RowName,Value), y=Value*(1000/area.m2)*eui_conv,label=RowName)) +
  geom_bar(stat="identity", aes(fill=factor(plot), alpha=plot)) +
  scale_fill_manual(values = c('grey60','grey40'), guide=FALSE) +
  scale_alpha(range=c(0,1), guide=FALSE) +  
  ylab(expression(paste("Site Energy Use Intensity (", kBtu/ft^2, ")", sep=""))) + 
  xlab("Energy End Use") + 
  labs(title='(a) Energy End Use Breakout') +
  coord_cartesian(ylim=c(0, 100)) +
  scale_y_continuous(breaks=seq(0, 100, by=10)) +
  theme(title = element_text(face = 'bold', size = 18),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey20", size=0.5),
        panel.grid.minor = element_line(color = "grey80", size=0.5),
        axis.text.y = element_text(color = "grey20", size = 16, hjust = 0),
        axis.text.x = element_text(color = "grey20", size = 16))
plot(end.use.plot)