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
### Import data
load('./run_scripts/results/simulation_results_LCC.RData')
baseline <- simulation.results[simulation.results$run.name %in% c("baseline"),]

npv.vs.eui <- ggplot(data = simulation.results,
                      aes(x = site.energy.intensity*0.947817120/10.7639, y = npv.relative.to.base, label = run.name)) + 
  geom_point() +
  annotate("point", x = (0.947817120/10.7639)*baseline$site.energy.intensity, y = baseline$npv.relative.to.base, color = "red", size = 3) +
  #geom_text(hjust=1, vjust=1, size = 3) + 
  #coord_cartesian(ylim=c(-100000, 135000), xlim=c(100, 75)) + 
  #scale_y_continuous(breaks=seq(100000, 135000, 5000), labels = dollar) + 
  labs(title = "Net Present Value Relative to Baseline for Measure Combinations",
       x = expression(paste("Site Energy Use Intensity (kBtu/ft^2)"))) + 
  xlab(expression(paste("Site Energy Use Intensity (", kBtu/ft^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey",size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12))
plot(npv.vs.eui)

cusize.vs.eui <- ggplot(data = simulation.results,
                        aes(x = site.energy.intensity*0.947817120/10.7639, y = cu.size, label = run.name)) + 
  geom_point() +
  annotate("point", x = (0.947817120/10.7639)*baseline$site.energy.intensity, y = baseline$cu.size, color = "red", size = 3) +
  #geom_text(hjust=1, vjust=1, size = 3) + 
  #coord_cartesian(ylim=c(350000, 500000), xlim=c(100, 75)) + 
  #scale_y_continuous(breaks=seq(350000, 500000, 25000)) + 
  labs(title = "Condensing Unit Size of Measure Options",
       x = expression(paste("Site Energy Use Intensity (kBtu/ft^2)"))) + 
  xlab(expression(paste("Site Energy Use Intensity (", kBtu/ft^2, ")", sep=""))) + 
  ylab(expression(paste("Capacity (W)"))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey",size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12))
plot(cusize.vs.eui)

boilersize.vs.eui <- ggplot(data = simulation.results,
                            aes(x = site.energy.intensity*0.947817120/10.7639, y = boiler.size, label = run.name)) + 
  geom_point() +
  annotate("point", x = (0.947817120/10.7639)*baseline$site.energy.intensity, y = baseline$boiler.size, color = "red", size = 3) +
  #geom_text(hjust=1, vjust=1, size = 3) + 
  #coord_cartesian(ylim=c(350000, 500000), xlim=c(100, 75)) + 
  #scale_y_continuous(breaks=seq(350000, 500000, 25000)) + 
  labs(title = "Boiler Size of Measure Options",
       x = expression(paste("Site Energy Use Intensity (kBtu/ft^2)"))) + 
  xlab(expression(paste("Site Energy Use Intensity (", kBtu/ft^2, ")", sep=""))) + 
  ylab(expression(paste("Capacity (W)"))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey",size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12))
plot(boilersize.vs.eui)

#pushViewport(viewport(layout = grid.layout(2, 4, heights = unit(c(1, 9), "null"))))
#print(npv.eui, vp = viewport(layout.pos.row = 2, layout.pos.col = 1:2))
#grid.text("Impact of Setbacks on Annual Energy Use and Cost", gp=gpar(fontsize=20), vp = viewport(layout.pos.row = 1, layout.pos.col = 1:4))

############################################################
# PLOTS OF NET PRESENT VALUE VERSUS SITE ENERGY INTENSITY ##
############################################################
if (FALSE) {

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