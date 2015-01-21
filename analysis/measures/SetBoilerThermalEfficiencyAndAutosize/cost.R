cost <- function(size) {
  fixed <- 20706.115
  variable <- 13.833*(1/293.071) #13.83 per MBH
  return (size*variable + fixed)
  }