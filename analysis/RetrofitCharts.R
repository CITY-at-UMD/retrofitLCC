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

if (FALSE) { 
  # optional combine results; needs to be done if running RetrofitCharts.R for the first time with a new dataset
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
area.m2 <- 5518.33
area.ft2 <- area.m2/(0.3048^2)  
#get retrofit paths in terms of $/ft^2
retrofit.paths$net.present.value <- retrofit.paths$net.present.value/area.ft2
retrofit.paths$npv.rel.to.base <- retrofit.paths$npv.rel.to.base/area.ft2
retrofit.paths$npv.rel.to.base.eqrep <- retrofit.paths$npv.rel.to.base.eqrep/area.ft2

baseline <- unique.sims[unique.sims$run.name %in% 'baseline',]
baseline <- baseline[baseline$capital.intensity %in% '100',]
baseline.eqrep <- retrofit.paths[retrofit.paths$path.name %in% 'baseline.eqrep',]
baseline.eqrep <- baseline.eqrep[baseline.eqrep$capital.intensity %in% '100',]

# examples of limiting dataset
#retrofit.paths <- retrofit.paths[order(retrofit.paths$npv.rel.to.base.eqrep, decreasing = TRUE), ]
#retrofit.paths <- retrofit.paths[retrofit.paths$npv.rel.to.base.eqrep > 0, ]
#retrofit.paths <- retrofit.paths[(retrofit.paths$capital.intensity == 100), ]
#retrofit.paths <- retrofit.paths[(retrofit.paths$nist.energy.scenario == 'default'), ]
#retrofit.paths <- retrofit.paths[!(retrofit.paths$nist.ghg.scenario == 'none'), ]
#retrofit.paths <- retrofit.paths[!(grepl('a', retrofit.paths$path.name)), ]
#retrofit.paths <- retrofit.paths[!(grepl('_', retrofit.paths$path.name)), ]

############################################################
# PLOTS OF NET PRESENT VALUE VERSUS SITE ENERGY INTENSITY ##
############################################################
fmt <- function(){
  function(x) format(x,nsmall=2,scientific=FALSE)
}

eui_conv_ip <- 0.947817120/10.7639
eui_conv_si <- 1/3.6
npv.rel.to.base.eqrep.min <- min(retrofit.paths$npv.rel.to.base.eqrep)
npv.rel.to.base.eqrep.max <- max(retrofit.paths$npv.rel.to.base.eqrep)

#FIGURE 5(a) Net present value of retrofit paths relative to the baseline factored by the measure cost modifier
npv.vs.eui1 <- ggplot(data = retrofit.paths,
                     aes(x = avg.site.energy.intensity*eui_conv_si, 
                         y = npv.rel.to.base.eqrep,
                         color = factor(cost.modifier))) + 
  geom_point(size = 0.5) +
  scale_color_grey(name = 'Cost Modifier') +
  coord_cartesian(xlim=c(305, 225), ylim=c(-20, 2)) + 
  scale_x_reverse(breaks=seq(225, 305, by=10)) + 
  scale_y_continuous(breaks=seq(-20, 2, by=2), labels = fmt()) +
  annotate('segment', 
           x = baseline.eqrep$avg.site.energy.intensity[1]*eui_conv_si, 
           xend = -baseline.eqrep$avg.site.energy.intensity[1]*eui_conv_si,
           y = -20, 
           yend = 2, 
           color = 'black', size = 1, alpha = 0.6) + 
  annotate('text', x = 285, y = -18, vjust = 1, hjust = 0, label = 'Baseline', size = 6) +
  annotate('rect', xmin = 255, xmax = 305, ymin = -2.5, ymax = 1.5, alpha = 0, color = 'red') +
  annotate('text', x = 255, y = 1.5, vjust = 1, hjust = 1, label = '(b)', color = 'red', size = 8) +
  labs(title = '(a) Net Present Value of Retrofit Paths by Cost Modifier') + 
  xlab(expression(paste("Avg. Site Energy Use Intensity over 20-yr Lifetime (", kWh/m^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  guides(colour = guide_legend(override.aes = list(size=5))) +
  theme(title = element_text(face = 'bold', size = 16),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey20", size=0.5),
        panel.grid.minor = element_line(color = "grey80", size=0.5),
        axis.text.y = element_text(color = "grey20", size = 14, hjust = 0),
        axis.text.x = element_text(color = "grey20", size = 16),
        axis.title = element_text(size=20),
        legend.key.size = unit(1.5,'cm'),
        legend.key = element_rect(fill = 'white'),
        legend.text = element_text(size = 16))
#plot(npv.vs.eui1)

#FIGURE 5(b) Net present value of retrofit paths relative to the baseline factored by NIST GHG price scenarios
npv.vs.eui2 <- ggplot(data = retrofit.paths,
                      aes(x = avg.site.energy.intensity*eui_conv_si, 
                          y = npv.rel.to.base.eqrep,
                          color = factor(nist.ghg.scenario, levels=c(c('high','default','low','none'))))) + 
  geom_point(size = 1.25) +
  #scale_color_grey(name = 'NIST GHG Scenario') +
  scale_color_brewer(palette='Set1', name = 'NIST GHG Scenario') +
  coord_cartesian(xlim=c(305, 255),ylim=c(-2.5, 1.5)) + 
  scale_x_reverse(breaks=seq(255,305,by=5)) + 
  scale_y_continuous(breaks=seq(-2.5, 1.5, by=0.5),labels = fmt()) +
  annotate('segment', 
           x = baseline.eqrep$avg.site.energy.intensity[1]*eui_conv_si, 
           xend = -baseline.eqrep$avg.site.energy.intensity[1]*eui_conv_si,
           y = -2.5, 
           yend = 1.5, 
           color = 'black', size = 1, alpha = 0.6) + 
  annotate('text', x = baseline.eqrep$avg.site.energy.intensity[1]*eui_conv_si, 
           y = 1.35, vjust = 1, hjust = 1, label = 'Baseline', size = 6) +  
  #annotate('rect', xmin = 81, xmax = 90, ymin = 0, ymax = 1.5, alpha = 0, color = 'red') +
  #annotate('text', x = 81, y = 1.5, vjust = 1, hjust = 1, label = '(c)', color = 'red') +
  labs(title = '(b) Net Present Value of Retrofit Paths by NIST GHG Scenario') + 
  xlab(expression(paste("Avg. Site Energy Use Intensity over 20-yr Lifetime (", kWh/m^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  guides(colour = guide_legend(override.aes = list(size=5))) +
  theme(title = element_text(face = 'bold', size = 16),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey20", size=0.5),
        panel.grid.minor = element_line(color = "grey80", size=0.5),
        axis.text.y = element_text(color = "grey20", size = 14, hjust = 0),
        axis.text.x = element_text(color = "grey20", size = 16),
        axis.title = element_text(size=20),
        legend.key.size = unit(1.5,'cm'),
        legend.key = element_rect(fill = 'white'),
        legend.text = element_text(size = 16))
#plot(npv.vs.eui2)
grid.arrange(npv.vs.eui1, npv.vs.eui2, ncol=2)

retrofit.paths <- retrofit.paths[order(retrofit.paths$capital.intensity, decreasing = FALSE), ]
npv.vs.eui3 <- ggplot(data = retrofit.paths,
                      aes(x = avg.site.energy.intensity*eui_conv_ip, 
                          y = npv.rel.to.base.eqrep,
                          color = factor(capital.intensity))) + 
  geom_point(size = 1.75) +
  scale_color_brewer(palette='Set1', name = 'Capital Intensity') +
  coord_cartesian(xlim=c(90, 81),ylim=c(0, 1.5)) + 
  scale_x_reverse(breaks=seq(81,90,by=1)) + 
  scale_y_continuous(breaks=seq(0, 1.5, by=0.25),labels = fmt()) +
  labs(title = '(c) Net Present Value of Retrofit Paths by Capital Intensity') + 
  xlab(expression(paste("Avg. Site Energy Use Intensity over Lifetime (", kBtu/ft^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey", size=0.5),
        axis.text.y = element_text(size = 12, hjust = 0),
        axis.text.x = element_text(size = 12),
        legend.key.size = unit(2,'cm'),
        legend.key = element_rect(fill = 'white'),
        legend.text = element_text(size = 14))
plot(npv.vs.eui3)

###########################
# PLOTS OF GHG INTENSITY ##
###########################
npv.bins <- retrofit.paths[(retrofit.paths$npv.rel.to.base.eqrep > 0),]
#npv.bins$discrete <- cut(npv.bins$npv.rel.to.base.eqrep, c(5,0), include.lowest=T)

# Figure 8 - Relative 20-year greenhouse gas emissions dependent on the capital availability and
# measure costs for retrofit paths with positive net present value 
# relative to the net present value for the baseline case
ghg.graph <- ggplot(data = npv.bins,
                    aes(x = factor(capital.intensity), 
                        y = ghg.rel.to.base.eqrep, 
                        fill = factor(cost.modifier))) + 
  geom_violin() + 
  scale_fill_grey(name = 'Cost Modifier') +
  coord_cartesian(ylim=c(0.84, 1.04)) +  
  scale_y_continuous(breaks=seq(0.84, 1.04, by=0.02),labels = fmt()) +
  #annotate('rect', xmin = 81, xmax = 90, ymin = 0, ymax = 1.5, alpha = 0, color = 'red') +
  #annotate('text', x = 81, y = 1.5, vjust = 1, hjust = 1, label = '(c)', color = 'red') +
  #labs(title = 'Relative 20-yr GHG Emissions Compared to Baseline Case') + 
  xlab(expression(paste("Capital Availability ($/", ft^2, ")", sep=""))) + 
  ylab("Relative 20-yr GHG emissions") + 
  theme(title = element_text(face = 'bold', size = 18),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey20", size=0.5),
        panel.grid.minor = element_line(color = "grey80", size=0.5),
        axis.text.y = element_text(color = "grey20", size = 16, hjust = 0),
        axis.text.x = element_text(color = "grey20", size = 16),
        legend.key.size = unit(2,'cm'),
        legend.key = element_rect(fill = 'white'),
        legend.text = element_text(size = 14))
plot(ghg.graph)

###############################
# PLOTS OF CAPITAL INTENSITY ##
###############################

# Show measure paths with positive NPV and reduced energy use, and group them together into path groups
i <- 1
ptm <- proc.time()
for (nist.ghg.scenario in c('default','low','high','none')) {
  for (cost.modifier in c(0.5, 1)) {
    subset.df <- retrofit.paths[((retrofit.paths$nist.ghg.scenario == nist.ghg.scenario) & (retrofit.paths$cost.modifier == cost.modifier)), ]
    df <- subset.df[(subset.df$npv.rel.to.base.eqrep > 0),]
    df <- df[(df$capital.intensity == 100),]
    df <- df[order(df$npv.rel.to.base.eqrep, decreasing = TRUE),]
    for (path in df$path.name){
      df.group <- subset.df[(subset.df$path.name %in% path),] 
      df.group <- cbind(df.group, path.group = i)
      if ( i == 1 ) { 
        ci.df <- df.group      
      } else { 
        ci.df <- rbind(ci.df, df.group) 
      }
      i <- i + 1
    }
    print(paste('nist.ghg.scenario:', nist.ghg.scenario, 
                'cost.modifier:', cost.modifier,
                'time elapsed:', (proc.time() - ptm)[3], 'seconds')) 
  }  
}

# For each financial scenario, show the best measure path ranked by NPV in the full capital intensity option
top.num <- 1 # number of best paths to show
i <- 1
for (nist.ghg.scenario in c('default','low','high','none')) {
  for (cost.modifier in c(0.5, 1)) {
    subset.df <- retrofit.paths[((retrofit.paths$nist.ghg.scenario == nist.ghg.scenario) & (retrofit.paths$cost.modifier == cost.modifier)), ]
    # eliminate single replacement options
    subset.df <- subset.df[!(subset.df$path.name %in% c('c','f','g','c_f','f_c','c_g','g_c','g_f','f_g')),] 
    subset.df <- subset.df[order(subset.df$npv.rel.to.base.eqrep, decreasing = TRUE),]
    top <- as.character(unique(subset.df$path.name))[1:top.num]
    for (j in 1:top.num){     
      df <- subset.df[(subset.df$path.name %in% top[j]),]
      df <- cbind(df, path.group = (i + (j-1)))
      if ( (i + (j-1)) == 1 ) { 
        ci.df <- df      
      } else { 
        ci.df <- rbind(ci.df, df) 
      }
    }
    i <- i + top.num
  }  
}


#Figure 6 - Optimal path options depending on the financial scenario
ci.drop <- ggplot(data = ci.df,
                  aes(x = avg.site.energy.intensity*eui_conv_si, 
                      y = npv.rel.to.base.eqrep,
                      group = path.group)) + 
  geom_point(aes(shape = factor(nist.ghg.scenario, levels=c(c('high','default','low','none'))),
                 color = factor(capital.intensity)),
             size = 5) +
  scale_shape_manual(values=c(16,17,18,6),name = 'NIST GHG Scenario') +
  scale_color_brewer(palette='Set1', name = expression(paste("Capital Availability ($/", ft^2, ")", sep=""))) +
  geom_line(alpha = 0.5) +
  geom_text(data = ci.df[((ci.df$capital.intensity == 100) & (ci.df$nist.ghg.scenario == 'high')), ],
            aes(label = paste("  ", path.name, ", Cost modifier=", cost.modifier, sep='')),
            hjust=0.6, vjust=-0.5, angle = 0, size = 5) + 
  geom_text(data = ci.df[((ci.df$capital.intensity == 100) & !(ci.df$nist.ghg.scenario == 'high')), ],
            aes(label = paste("  ", path.name, ", Cost modifier=", cost.modifier, sep='')),
            hjust=0, vjust=0.5, angle = 0, size = 5) +
  coord_cartesian(xlim=c(274,263),ylim=c(0, 1.5)) + 
  scale_x_reverse(breaks=seq(263,274,by=1)) + 
  scale_y_continuous(breaks=seq(0.25, 1.5, by=0.25),labels = fmt()) +
  xlab(expression(paste("Avg. Site Energy Use Intensity (", kWh/m^2, ")", sep=""))) + 
  ylab(expression(paste("Net Present Value ($/", ft^2, ")", sep=""))) +
  guides(colour = guide_legend(override.aes = list(size=5,shape=15))) +
  guides(shape = guide_legend(override.aes = list(size=5))) + 
  theme(title = element_text(face = 'bold', size = 20),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey20", size=0.5),
        panel.grid.minor = element_line(color = "grey80", size=0.5),
        axis.text.y = element_text(color = "grey20", size = 18, hjust = 0),
        axis.text.x = element_text(color = "grey20", size = 18),
        axis.title = element_text(size=20),
        legend.key.size = unit(2,'cm'),
        legend.key = element_rect(fill = 'white'),
        legend.text = element_text(size = 16, face='bold'),
        legend.title = element_text(size=18, face='bold'))
plot(ci.drop)

################################
# PLOTS OF INSTALLATION ORDER ##
################################
# run this once
retrofit.paths <- cbind(retrofit.paths, order.group = 0, order.group.name = retrofit.paths$path.name, num.m = 1)

# match all groups of the same letter combinations as the same order group using regex
i <- 1
ptm <- proc.time()
for (num.m in 2:7) {
  str.len <- num.m + num.m - 1
  len.match <- (nchar(as.character(retrofit.paths$path.name)) == str.len)
  retrofit.paths$num.m[len.match] <- num.m
  order.df <- retrofit.paths[len.match, ]  
  while ( nrow(order.df) > 0 ) {
    str <- as.character(order.df$path.name[1])
    str <- paste('([', str, ']){', str.len, ',}', sep='')
    match.logical <- grepl(str, as.character(order.df$path.name))
    match.list <- unique(order.df$path.name[(match.logical)])
    retrofit.paths$order.group[(as.character(retrofit.paths$path.name) %in% match.list)] <- i
    retrofit.paths$order.group.name[(as.character(retrofit.paths$path.name) %in% match.list)] <- as.character(order.df$path.name[1])
    order.df <- order.df[!(match.logical),]
    i <- i + 1
  }
  print(paste('num.m:', num.m, 'time elapsed:', (proc.time() - ptm)[3], 'seconds'))  
}

# for each path group, in each scenario combination, calculate the relative and maximum difference of ordering
first.iter <- TRUE
ptm <- proc.time()
for (nist.ghg.scenario in c('default','low','high','none')) {
  for (cost.modifier in c(0.5, 1)) {
    for (capital.intensity in c(1,2,3,5,100)){
      num.groups <- max(retrofit.paths$order.group)
      max.diff <- c(rep(0, num.groups))
      rel.diff <- c(rep(0, num.groups))
      num.m <- c(rep(0, num.groups))
      order.group.name <- c(rep('', num.groups))
      for (order.group in 1:num.groups) {
        v <- retrofit.paths$npv.rel.to.base.eqrep[(retrofit.paths$order.group == order.group) 
                                                  & (retrofit.paths$nist.ghg.scenario == nist.ghg.scenario) 
                                                  & (retrofit.paths$cost.modifier == cost.modifier)
                                                  & (retrofit.paths$capital.intensity == capital.intensity)]  
        order.group.name[order.group] <- as.character(retrofit.paths$order.group.name[(retrofit.paths$order.group == order.group)][1])
        max.diff[order.group] <- (max(v) - min(v))
        rel.diff[order.group] <- abs((max(v) - min(v)) / mean(v))
        num.m[order.group] <- retrofit.paths$num.m[retrofit.paths$order.group == order.group][1] 
      }
      if (first.iter == TRUE) {
        order.df <- data.frame(order.group = 1:num.groups, order.group.name, num.m, max.diff, rel.diff, 
                               cost.modifier, nist.ghg.scenario, capital.intensity)
        first.iter <- FALSE
      } else {
        order.df <- rbind(order.df, 
                          data.frame(order.group = 1:num.groups, order.group.name, num.m, max.diff, rel.diff, 
                                     cost.modifier  = cost.modifier,
                                     nist.ghg.scenario = nist.ghg.scenario,
                                     capital.intensity = capital.intensity))
      }
      print(paste('cost.modifier:', cost.modifier,
                  'nist.ghg.scenario:', nist.ghg.scenario,
                  'capital.intensity:', capital.intensity,
                  'time elapsed:', (proc.time() - ptm)[3], 'seconds'))
    }
  }
}
order.df <- order.df[order(order.df$max.diff, decreasing = TRUE), ]
best.order.group.num <- retrofit.paths$order.group[(retrofit.paths$path.name %in% "b_g_f_c")][1]
best.order.group <- order.df[(order.df$order.group %in% best.order.group.num), ]

worst.order <- retrofit.paths[((retrofit.paths$capital.intensity == 100)
                               & (retrofit.paths$path.name %in% c('b_g_f_c','b_g_c_f','b_c_g_f','b_c_f_g','b_f_c_g','b_f_g_c',
                                                                  'c_b_f_g','c_b_g_f','c_f_b_g','c_f_g_b','c_g_f_b','c_g_b_f',
                                                                  'f_b_c_g','f_b_g_c','f_c_b_g','f_c_g_b','f_g_b_c','f_g_c_b',
                                                                  'g_b_c_f','g_b_f_c','g_c_b_f','g_c_f_b','g_f_b_c','g_f_c_b'))),]
worst.order <- retrofit.paths[((retrofit.paths$capital.intensity == 2) &
                                 (retrofit.paths$path.name %in% c('b_g_f_c','b_g_c_f','b_c_g_f','b_c_f_g','b_f_c_g','b_f_g_c',
                                                                  'c_b_f_g','c_b_g_f','c_f_b_g','c_f_g_b','c_g_f_b','c_g_b_f',
                                                                  'f_b_c_g','f_b_g_c','f_c_b_g','f_c_g_b','f_g_b_c','f_g_c_b',
                                                                  'g_b_c_f','g_b_f_c','g_c_b_f','g_c_f_b','g_f_b_c','g_f_c_b'))),]
worst.order <- worst.order[order(worst.order$net.present.value, decreasing = TRUE),]
# this worst order gives the best and worst retrofit paths for a given capital.intensity.  
# In particular, for CI = 1, the best order is always fcgb and the worst order is always bcgf

worst.order <- retrofit.paths[((retrofit.paths$cost.modifier %in% c(0.5,1)) & 
                                !(retrofit.paths$path.name %in% c('f','c','g','f_c','c_f')) &
                                (retrofit.paths$npv.rel.to.base.eqrep>0)),]
worst.order <- worst.order[order(worst.order$npv.rel.to.base.eqrep, decreasing = TRUE),]

order.graph <- ggplot(data = order.df,
                      aes(x = factor(capital.intensity), 
                          y = max.diff, 
                          fill = factor(num.m))) + 
  geom_boxplot(outlier.size = 1) +
  scale_fill_grey(name = 'Measures Considered') +
  coord_cartesian(ylim=c(0, 2.5)) +  
  scale_y_continuous(breaks=seq(0, 2.5, by=0.25),labels = fmt()) +
  #annotate('rect', xmin = 81, xmax = 90, ymin = 0, ymax = 1.5, alpha = 0, color = 'red') +
  #annotate('text', x = 81, y = 1.5, vjust = 1, hjust = 1, label = '(c)', color = 'red') +
  #labs(title = 'Measure order') + 
  xlab(expression(paste("Capital Availability ($/", ft^2, ")", sep=""))) + 
  ylab(expression(paste("Maximum Difference in Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 18),
        panel.background = element_blank(),
        panel.grid.major = element_blank(),#element_line(color = "grey20", size=0.5),
        panel.grid.minor = element_line(color = "grey80", size=0.5),
        axis.text.y = element_text(color = "grey20", size = 16, hjust = 0),
        axis.text.x = element_text(color = "grey20", size = 16),
        legend.key.size = unit(2,'cm'),
        legend.key = element_rect(fill = 'white'),
        legend.text = element_text(size = 14),
        legend.position = c(0.92, 0.66))
plot(order.graph)

# Figure 7 - Net present values with changing capital availability resulting in different implementation order 
# from the optimal retrofit path, worst retrofit path, which changes depending on the financial scenario.
order.graph2 <- ggplot(data = best.order.group,
                      aes(x = factor(capital.intensity), 
                          y = max.diff)) + 
  geom_boxplot() +
  coord_cartesian(ylim=c(0, 0.5)) +  
  scale_y_continuous(breaks=seq(0, 0.5, by=0.05),labels = fmt()) +
  #annotate('rect', xmin = 81, xmax = 90, ymin = 0, ymax = 1.5, alpha = 0, color = 'red') +
  #annotate('text', x = 81, y = 1.5, vjust = 1, hjust = 1, label = '(c)', color = 'red') +
  xlab(expression(paste("Capital Availability ($/", ft^2, ")", sep=""))) + 
  ylab(expression(paste("Maximum Difference in Net Present Value ($/", ft^2, ")", sep=""))) + 
  theme(title = element_text(face = 'bold', size = 18),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "grey80", size=0.5),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text.y = element_text(color = "grey20", size = 16, hjust = 0),
        axis.text.x = element_text(color = "grey20", size = 16),
        legend.key.size = unit(2,'cm'),
        legend.key = element_rect(fill = 'white'),
        legend.text = element_text(size = 14),
        legend.position = c(0.92, 0.7))
plot(order.graph2)