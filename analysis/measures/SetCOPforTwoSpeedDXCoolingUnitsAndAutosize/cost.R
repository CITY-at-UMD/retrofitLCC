cost <- function(size) {
  fixed <- 7909
  variable <- 766*(1/(0.293071*12000)) # $ per ton / ton per W 
  return (size*variable + fixed)
  }