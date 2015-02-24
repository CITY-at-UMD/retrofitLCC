# ResultsReadSingleSimulation.R
# reads in the simulation results for one simulation result and charts it.
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
#
# 
rm(list=ls())  # clear variables 

# function for formating numbers in plots
fmt <- function(){
  function(x) format(x,nsmall=2,scientific=FALSE)
}

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

# only keep valid sql files
run.names <- run.names[lapply(sql.files, nchar) > 0] 
sql.files <- sql.files[lapply(sql.files, nchar) > 0]
num.files <- length(sql.files)

# target specific sql file
sql.file <- sql.files[grep("baseline", run.names)]

# peak load contributions
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


# annual energy end uses
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