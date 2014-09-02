# recursion function to replace names
vectorRecursion <- function(v, n) {   
  if(n==1){
    return(v[1])
  } else {
    prior <- vectorRecursion(v[1:n-1], n-1)
    v[n] <- paste(prior, v[n], sep="_")
    return(v[n])
  }  
}