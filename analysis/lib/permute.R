# permutation function
permute <- function(n) {   
  if(n==1){
    return(matrix(1))
  } else {
    sp <- permute(n-1)
    p <- nrow(sp)
    A <- matrix(nrow=n*p,ncol=n)
    for(i in 1:n){
      A[(i-1)*p+1:p,] <- cbind(i,sp+(sp>=i))
    }
    return(A)
  }
}