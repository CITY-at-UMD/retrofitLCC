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

if (FALSE) { # optional combine results
  print(paste("importing and combining results..."))

  unique.sims.files <- list.files(path = './run_scripts/results',
                                    pattern = 'unique_sims*',
                                    recursive = FALSE,
                                    full.names = TRUE)
  unique.sims.files <- unique.sims.files[lapply(unique.sims.files, nchar) > 0]
  for (i in 1:length(unique.sims.files)) {
    load(unique.sims.files[i])
    if (i == 1) {
      unique.sims <- simulation.results
    } else {
      unique.sims <- rbind(unique.sims, simulation.results)
    }    
  }
  rm(unique.sims.files, simulation.results, i)
  
  retrofit.path.files <- list.files(path = './run_scripts/results',
                                    pattern = 'retrofit_paths*',
                                    recursive = FALSE,
                                    full.names = TRUE)
  retrofit.path.files <- retrofit.path.files[lapply(retrofit.path.files, nchar) > 0]
  for (i in 1:length(retrofit.path.files)) {
    load(retrofit.path.files[i])
    
    # add in column if forgotten in ResultsConstrution.R
    #if (grepl('CM0.5', retrofit.path.files[i]) == 1) {
    #  unique.paths <- cbind(unique.paths, cost.modifier = 0.5)
    #} else {      
    #  unique.paths <- cbind(unique.paths, cost.modifier = 1)
    #}
    
    if (i == 1) {
      retrofit.paths <- unique.paths      
    } else {
      retrofit.paths <- rbind(retrofit.paths, unique.paths)
    }    
  }
  rm(retrofit.path.files, unique.paths, i)
  
  retrofit.paths <- retrofit.paths[!(retrofit.paths$avg.site.energy.intensity %in% 0), ]
  save(unique.sims, retrofit.paths, file = paste('./run_scripts/results/final_results.RData', sep = ''))
  print(paste('final results saved to:', paste('./run_scripts/results/final_results.RData', sep = '')))
  rm(list=ls())
}

print(paste("loading final results..."))
load('./run_scripts/results/final_results.RData')
baseline <- unique.sims[unique.sims$run.name %in% 'baseline',]
baseline <- baseline[baseline$capital.intensity %in% '100',]
baseline.eqrep <- retrofit.paths[retrofit.paths$path.name %in% 'baseline.eqrep',]
baseline.eqrep <- baseline.eqrep[baseline.eqrep$capital.intensity %in% '100',]

# examples of limiting dataset
#retrofit.paths <- retrofit.paths[retrofit.paths$npv.rel.to.base.eqrep > 0, ]
#retrofit.paths <- retrofit.paths[(retrofit.paths$capital.intensity == 100), ]
#retrofit.paths <- retrofit.paths[(retrofit.paths$nist.energy.scenario == 'default'), ]
#retrofit.paths <- retrofit.paths[!(retrofit.paths$nist.ghg.scenario == 'none'), ]
#retrofit.paths <- retrofit.paths[!(grepl('a', retrofit.paths$path.name)), ]
#retrofit.paths <- retrofit.paths[!(grepl('_', retrofit.paths$path.name)), ]
#retrofit.paths <- retrofit.paths[order(retrofit.paths$npv.rel.to.base.eqrep, decreasing = TRUE), ]

############################################################
# PLOTS OF NET PRESENT VALUE VERSUS SITE ENERGY INTENSITY ##
############################################################
eui_conv <- 0.947817120/10.7639
npv.rel.to.base.eqrep.min <- min(retrofit.paths$npv.rel.to.base.eqrep)
npv.rel.to.base.eqrep.max <- max(retrofit.paths$npv.rel.to.base.eqrep)

npv.vs.eui <- ggplot(data = retrofit.paths,
                     aes(x = avg.site.energy.intensity*eui_conv, y = npv.rel.to.base.eqrep, label = path.name)) + 
  geom_point(aes(color = factor(capital.intensity))) +
  annotate("segment", x = baseline.eqrep$avg.site.energy.intensity[1]*eui_conv, xend = -baseline.eqrep$avg.site.energy.intensity[1]*eui_conv,
           y = npv.rel.to.base.eqrep.min, yend = npv.rel.to.base.eqrep.max, color = 'black', size = 1.5) +
  scale_x_reverse() + 
  #coord_cartesian(ylim=c(0, round(npv.rel.to.base.eqrep.max, digits = -4)), xlim=c(100, 75)) + 
  scale_y_continuous(labels = dollar) +
  #scale_y_continuous(breaks = seq(round(npv.rel.to.base.eqrep.min, digits = -4), 
  #                                round(npv.rel.to.base.eqrep.max, digits = -4),  
  #                                round((npv.rel.to.base.eqrep.max - npv.rel.to.base.eqrep.min)/5, digits = -4)),
  #                                labels = dollar) +   
  labs(title = "Net Present Value of Retrofit Paths",
       x = expression(paste("Site Energy Use Intensity (kBtu/ft^2)"))) + 
  xlab(expression(paste("Avg. Site Energy Use Intensity (", kBtu/ft^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey",size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12))
plot(npv.vs.eui)

npv.vs.eui2 <- ggplot(data = retrofit.paths,
                     aes(x = avg.site.energy.intensity*eui_conv, y = npv.rel.to.base.eqrep, label = path.name)) + 
  geom_point(aes(color = factor(cost.modifier))) +
  annotate("segment", x = baseline.eqrep$avg.site.energy.intensity[1]*eui_conv, xend = -baseline.eqrep$avg.site.energy.intensity[1]*eui_conv,
           y = npv.rel.to.base.eqrep.min, yend = npv.rel.to.base.eqrep.max, color = 'black', size = 1.5) +
  scale_x_reverse() + 
  #coord_cartesian(ylim=c(0, round(npv.rel.to.base.eqrep.max, digits = -4)), xlim=c(100, 75)) + 
  scale_y_continuous(labels = dollar) +
  #scale_y_continuous(breaks = seq(round(npv.rel.to.base.eqrep.min, digits = -4), 
  #                                round(npv.rel.to.base.eqrep.max, digits = -4),  
  #                                round((npv.rel.to.base.eqrep.max - npv.rel.to.base.eqrep.min)/5, digits = -4)),
  #                                labels = dollar) +   
  labs(title = "Net Present Value of Retrofit Paths",
       x = expression(paste("Site Energy Use Intensity (kBtu/ft^2)"))) + 
  xlab(expression(paste("Avg. Site Energy Use Intensity (", kBtu/ft^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey",size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12))
plot(npv.vs.eui2)

npv.vs.eui3 <- ggplot(data = retrofit.paths,
                      aes(x = avg.source.energy.intensity*eui_conv, y = npv.rel.to.base.eqrep, label = path.name)) + 
  geom_point(aes(color = factor(nist.ghg.scenario))) +
  annotate("segment", x = baseline.eqrep$avg.source.energy.intensity[1]*eui_conv, xend = -baseline.eqrep$avg.source.energy.intensity[1]*eui_conv,
           y = npv.rel.to.base.eqrep.min, yend = npv.rel.to.base.eqrep.max, color = 'black', size = 1.5) +
  scale_x_reverse() + 
  #coord_cartesian(ylim=c(0, round(npv.rel.to.base.eqrep.max, digits = -4)), xlim=c(100, 75)) + 
  scale_y_continuous(labels = dollar) +
  #scale_y_continuous(breaks = seq(round(npv.rel.to.base.eqrep.min, digits = -4), 
  #                                round(npv.rel.to.base.eqrep.max, digits = -4),  
  #                                round((npv.rel.to.base.eqrep.max - npv.rel.to.base.eqrep.min)/5, digits = -4)),
  #                                labels = dollar) +   
  labs(title = "Net Present Value of Retrofit Paths",
       x = expression(paste("Site Energy Use Intensity (kBtu/ft^2)"))) + 
  xlab(expression(paste("Avg. Site Energy Use Intensity (", kBtu/ft^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey",size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12))
plot(npv.vs.eui3)

npv.vs.ghg <- ggplot(data = retrofit.paths,
                     aes(x = ghg.rel.to.base.eqrep, y = npv.rel.to.base.eqrep, label = path.name)) + 
  geom_point(aes(color = factor(capital.intensity))) +
  scale_x_reverse() + 
  labs(title = "Relative GHG Emissions of Retrofit Paths",
       x = expression(paste("Site Energy Use Intensity (kBtu/ft^2)"))) + 
  xlab(expression(paste("Relative GHG Emissions", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey",size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12))
plot(npv.vs.ghg)

################################
# PLOTS OF INSTALLATION ORDER ##
################################


###############################
# PLOTS OF CAPITAL INTENSITY ##
###############################
# show the impact of NPV in capital intensity for the best retrofit paths by scenario
i <- 1
for (nist.ghg.scenario in c('default','low','high','none')) {
  for (cost.modifier in c(1)) {
    subset.df <- retrofit.paths[((retrofit.paths$nist.ghg.scenario == nist.ghg.scenario) & (retrofit.paths$cost.modifier == cost.modifier)), ]
    df <- subset.df[(subset.df$npv.rel.to.base.eqrep == max(subset.df$npv.rel.to.base.eqrep)),]
    #if ( nrow(df) > 1 ) { df <- df[1,] }
    df <- subset.df[(subset.df$path.name %in% df$path.name),]
    df <- cbind(df, path.group = i)
    if ( i == 1 ) { 
      ci.df <- df      
    } else { 
      ci.df <- rbind(ci.df, df) 
    }
    i <- i + 1
  }  
}

ci.drop <- ggplot(data = ci.df,
                      aes(x = avg.site.energy.intensity*eui_conv, y = npv.rel.to.base.eqrep, label = path.name)) + 
  geom_point(aes(color = factor(capital.intensity), shape = factor(nist.ghg.scenario)), size = 3) +
  annotate("segment", x = baseline.eqrep$avg.site.energy.intensity[1]*eui_conv, xend = -baseline.eqrep$avg.site.energy.intensity[1]*eui_conv,
           y = min(ci.df$npv.rel.to.base.eqrep), yend = max(ci.df$npv.rel.to.base.eqrep), color = 'black', size = 1) +
  scale_x_reverse() + 
  #coord_cartesian(ylim=c(0, round(npv.rel.to.base.eqrep.max, digits = -4)), xlim=c(100, 75)) + 
  scale_y_continuous(labels = dollar) +  
  labs(title = "Net Present Value of Retrofit Paths",
       x = expression(paste("Site Energy Use Intensity (kBtu/ft^2)"))) + 
  xlab(expression(paste("Avg. Site Energy Use Intensity (", kBtu/ft^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey",size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12))
plot(ci.drop)


################
# OTHER PLOTS ##
################
if (FALSE) {
npv.vs.eui <- ggplot(data = simulation.results,
                      aes(x = site.energy.intensity*0.947817120/10.7639, y = npv.relative.to.base, label = run.name)) + 
  geom_point() +
  annotate("point", x = (0.947817120/10.7639)*baseline$site.energy.intensity, y = baseline$npv.relative.to.base, color = "red", size = 3) +
  #geom_text(hjust=1, vjust=1, size = 3) + 
  #coord_cartesian(ylim=c(-100000, 135000), xlim=c(100, 75)) + 
  #scale_y_continuous(breaks=seq(100000, 135000, 5000), labels = dollar) + 
  scale_x_reverse() + 
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
  scale_x_reverse() + 
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
  scale_x_reverse() + 
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
}


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