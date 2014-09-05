# RetrofitCharts.R
# Takes in the data frames from ResultsConstruction and uses it to produce graphics
#
# Building Science Group 2014
#
# Contributors: 
# Matthew G. Dahlhausen
#
# Package Dependencies: 
library(grid)
library(ggplot2)
library(scales)
library(reshape2)
library(gridExtra)
library(zoo)
#
rm(list=ls())  # clear variables 
#
### Import function dependencies
source("./lib/npv.R") # Import financial calculation
source("./lib/escalationRates.R") # Import NIST escalation rates
source("./lib/permute.R")
source("./lib/vectorRecursion.R")
invisible(ImportEscalationRates())

##############################
# IMPORT SIMULATION RESULTS ##
##############################
# simulation data requirement:

#test data as a matrix
test.cost<- matrix(0, nrow=r, ncol=c)
for (j in 1:c) {
  for(i in 1:r) {
    test.cost[i,j]  <- runif(1, (c-j+1)*5, (c-j+1)*10)
  }
}
test.energy <- matrix(0, nrow=r, ncol=c)
for (j in 1:c) {
  for(i in 1:r) {
    test.energy[i,j]  <- runif(1, (c-j+1)*5, (c-j+1)*10)
  }
}

# central data frames


##############################
# CALCULATE LIFE CYCLE COST ##
##############################
lifetime <- 20   # Use a 20 year life time to calculate NPV (include year 0 in costs) 
discount.rate <- 0.03 	# 3% discount rate
cash.flow <- matrix(0, nrow = num.runs, ncol = lifetime + 1) 

# CREATE PATHS FOR REPRESENTATIVE CASES
# BASELINE CASE
baseline.case <- simulation.results[simulation.results$run.names %in% c("Baseline",
                                                                        "CU",
                                                                        "Boiler",
                                                                        "CU_Boiler"),]
capital.cost <- c(rep(0, 6),
                  -cu.cost(simulation.results$cu.size[simulation.results$run.names %in% "CU"]), 
                  rep(0, 4),
                  -boiler.cost(simulation.results$cu.size[simulation.results$run.names %in% "CU"]),
                  rep(0, 9))
energy.cost <- c(-1*rep(simulation.results$total.annual.energy.cost[simulation.results$run.names %in% "Baseline"], 6),
                 -1*rep(simulation.results$total.annual.energy.cost[simulation.results$run.names %in% "CU"], 5),
                 -1*rep(simulation.results$total.annual.energy.cost[simulation.results$run.names %in% "CU_Boiler"], 10))
cash.flow <- capital.cost + energy.cost
npv.baseline <- npv(discount.rate, cash.flow)
rm(capital.cost, energy.cost, cash.flow)

# HEATING REDUCTION
heating.case <- simulation.results[simulation.results$run.names %in% c("HeatSetback_CoolSetback",
                                                                       "HeatSetback_CoolSetback_Infltr30",
                                                                       "HeatSetback_CoolSetback_AEDGExtWall",
                                                                       "HeatSetback_CoolSetback_Infltr30_AEDGExtWall"),]
net.present.value <- c(rep(0, 4) )
npv.relative <- c(rep(0, 4) )
for (i in 1:4) {
  this.run.name <- heating.case$run.names[i]
  first.year.cost <- 0
  names <- strsplit(this.run.name, "_")
  for (j in 1:length(names[[1]])) {
    measure.cost <- measures$cost[measures$name %in% names[[1]][j]]
    first.year.cost <- first.year.cost + measure.cost
  }
  cu.run.name <- paste(this.run.name, "_CU", sep="")  
  cu.boiler.run.name <- paste(this.run.name, "_CU_Boiler", sep="")
  capital.cost <- c(-first.year.cost,
                    rep(0, 5),
                    -cu.cost(simulation.results$cu.size[simulation.results$run.names %in% cu.run.name]), 
                    rep(0, 4),
                    -boiler.cost(simulation.results$cu.size[simulation.results$run.names %in% cu.boiler.run.name]),
                    rep(0, 9))
  energy.cost <- c(-1*rep(simulation.results$total.annual.energy.cost[simulation.results$run.names %in% this.run.name], 6),
                   -1*rep(simulation.results$total.annual.energy.cost[simulation.results$run.names %in% cu.run.name], 5),
                   -1*rep(simulation.results$total.annual.energy.cost[simulation.results$run.names %in% cu.boiler.run.name], 10))
  print(this.run.name)
  print(capital.cost)
  print(energy.cost)
  cash.flow <- capital.cost + energy.cost
  net.present.value[i] <- npv(discount.rate, cash.flow)   
  npv.relative[i] <- net.present.value[i] - npv.baseline
}
heating.case <- cbind(heating.case, net.present.value, npv.relative)
rm(first.year.cost, names, measure.cost, this.run.name, cu.run.name, cu.boiler.run.name, capital.cost, energy.cost, cash.flow, net.present.value, npv.relative)                                                                       
                                                         
# COOLING REDUCTION                                                                       
cooling.case <- simulation.results[simulation.results$run.names %in% c("HeatSetback_CoolSetback",
                                                                       "HeatSetback_CoolSetback_ReduceLPD",
                                                                       "HeatSetback_CoolSetback_ReduceNightLight",
                                                                       "HeatSetback_CoolSetback_WindowFilm",
                                                                       "HeatSetback_CoolSetback_ReduceLPD_WindowFilm",
                                                                       "HeatSetback_CoolSetback_ReduceNightLight_ReduceLPD",
                                                                       "HeatSetback_CoolSetback_ReduceNightLight_WindowFilm",
                                                                       "HeatSetback_CoolSetback_ReduceNightLight_ReduceLPD_WindowFilm"),]
net.present.value <- c(rep(0, 8) )
npv.relative <- c(rep(0, 8) )
for (i in 1:8) {
  this.run.name <- cooling.case$run.names[i]
  first.year.cost <- 0
  names <- strsplit(this.run.name, "_")
  for (j in 1:length(names[[1]])) {
    measure.cost <- measures$cost[measures$name %in% names[[1]][j]]
    first.year.cost <- first.year.cost + measure.cost
  }
  cu.run.name <- paste(this.run.name, "_CU", sep="")  
  cu.boiler.run.name <- paste(this.run.name, "_CU_Boiler", sep="")
  capital.cost <- c(-first.year.cost,
                    rep(0, 5),
                    -cu.cost(simulation.results$cu.size[simulation.results$run.names %in% cu.run.name]), 
                    rep(0, 4),
                    -boiler.cost(simulation.results$cu.size[simulation.results$run.names %in% cu.boiler.run.name]),
                    rep(0, 9))
  energy.cost <- c(-1*rep(simulation.results$total.annual.energy.cost[simulation.results$run.names %in% this.run.name], 6),
                   -1*rep(simulation.results$total.annual.energy.cost[simulation.results$run.names %in% cu.run.name], 5),
                   -1*rep(simulation.results$total.annual.energy.cost[simulation.results$run.names %in% cu.boiler.run.name], 10))
  print(this.run.name)
  print(capital.cost)
  print(energy.cost)
  cash.flow <- capital.cost + energy.cost
  net.present.value[i] <- npv(discount.rate, cash.flow)   
  npv.relative[i] <- net.present.value[i] - npv.baseline
}
cooling.case <- cbind(cooling.case, net.present.value, npv.relative)
rm(first.year.cost, names, measure.cost, this.run.name, cu.run.name, cu.boiler.run.name, capital.cost, energy.cost, cash.flow, net.present.value, npv.relative)                                                                       

############################################################
# PLOTS OF NET PRESENT VALUE VERSUS SITE ENERGY INTENSITY ##
############################################################

area <- 59398.75 # ft^2
baseline.site.energy <- (0.947817120/10.7639)*simulation.results$site.energy.intensity[simulation.results$run.names %in% "Baseline"]
plot.heating <- ggplot(data = heating.case, 
      aes(x = (0.947817120/10.7639)*site.energy.intensity, 
          y = (1/area)*npv.relative,
          label = run.names)) + 
  geom_point(size = 3) +   
  
  geom_text(size=4, hjust=1) +
  coord_cartesian(xlim=c(95, 80),ylim=c(-20, 2.50)) + 
  scale_y_continuous(breaks=seq(-20, 2.5, 2.50), labels = dollar) +
  scale_x_reverse() +
  labs(title = "(a) Measures For Heating Load Reduction",
       x = expression(paste("Site Energy Use Intensity (kBtu/ft^2)"))) + 
  xlab(expression(paste("Site Energy Use Intensity (", kBtu/ft^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey",size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12)) + 
  geom_vline(xintercept = baseline.site.energy, color='red') + 
  geom_hline(yintercept = 0, color='red') + 
  annotate("text", x=baseline.site.energy, y=0, label="Baseline", hjust = 0, vjust = 1, size = 4) +
  annotate("point", x=baseline.site.energy, y=0, label="Baseline", hjust = 0, vjust = 1, size = 3)
  
plot.cooling <- ggplot(data = cooling.case, 
                       aes(x = (0.947817120/10.7639)*site.energy.intensity, 
                           y = (1/area)*npv.relative,
                           label = run.names)) + 
  geom_point(size = 3) +  
  geom_text(size=4, hjust=1) +
  coord_cartesian(xlim=c(95, 80),ylim=c(-2.5, 2.5)) + 
  scale_y_continuous(breaks=seq(-2.5, 2.5, 0.5), labels = dollar) +
  scale_x_reverse() +
  labs(title = "(b) Measures For Cooling Load Reduction",
       x = expression(paste("Site Energy Use Intensity (kBtu/ft^2)"))) + 
  xlab(expression(paste("Site Energy Use Intensity (", kBtu/ft^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey",size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12)) + 
  geom_vline(xintercept = baseline.site.energy, color='red') + 
  geom_hline(yintercept = 0, color='red') + 
  annotate("text", x=baseline.site.energy, y=0, label="Baseline", hjust = 0, vjust = 1, size = 4) +
  annotate("point", x=baseline.site.energy, y=0, label="Baseline", hjust = 0, vjust = 1, size = 3)

pushViewport(viewport(layout = grid.layout(9, 1, heights = unit(c(1, 9), "null"))))
print(plot.heating, vp = viewport(layout.pos.row = 2:5, layout.pos.col = 1))
print(plot.cooling, vp = viewport(layout.pos.row = 6:9, layout.pos.col = 1))
grid.text("Life Cycle Cost of Measure Bundle Options Relative to Baseline", 
          gp=gpar(fontsize=20), vp = viewport(layout.pos.row = 1, layout.pos.col = 1))

if (FALSE) {
  net.present.value <- c(rep(0, num.runs) )
  for (i in 1:num.runs) {
    cash.flow[i,] <- c(-1*rep(simulation.results$total.annual.energy.cost[i], lifetime + 1))
    net.present.value[i] <- npv(discount.rate, cash.flow[i,])
  }
  simulation.results <- cbind(simulation.results, net.present.value)
  npv.baseline <- simulation.results$net.present.value[simulation.results$run.names %in% "Baseline"]
  npv.relative <- simulation.results$net.present.value - npv.baseline # NPV relative to baseline NPV
  simulation.results <- cbind(simulation.results, npv.relative)

area <- 59398.75 # ft^2
baseline.site.energy <- (0.947817120/10.7639)*simulation.results$site.energy.intensity[simulation.results$run.names %in% "Baseline"]
npv.eui <- ggplot(data = simulation.results,
                       aes(x = site.energy.intensity*0.947817120/10.7639, y = npv.relative/area, label = run.names)) + 
  geom_point() +
  scale_x_reverse() +
  coord_cartesian(ylim=c(-1, 7), xlim=c(100, 75)) + 
  scale_y_continuous(breaks=seq(-1, 7, 0.5), labels = dollar) + 
  labs(title = "Net Present Value of Measure Options Relative to Baseline",
       x = expression(paste("Site Energy Use Intensity (kBtu/ft^2)"))) + 
  xlab(expression(paste("Site Energy Use Intensity (", kBtu/ft^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey",size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12)) + 
  geom_vline(xintercept = baseline.site.energy, color='red') + 
  geom_hline(yintercept = 0, color='red') + 
  annotate("text", x=baseline.site.energy, y=0, label="Baseline", hjust = 0, vjust = 1, size = 4)
plot(npv.eui)

#pushViewport(viewport(layout = grid.layout(2, 4, heights = unit(c(1, 9), "null"))))
#print(npv.eui, vp = viewport(layout.pos.row = 2, layout.pos.col = 1:2))
#grid.text("Impact of Setbacks on Annual Energy Use and Cost", gp=gpar(fontsize=20), vp = viewport(layout.pos.row = 1, layout.pos.col = 1:4))
}