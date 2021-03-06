#JEFFREY YOUNG, 2017
#there are 4 options for activation functions, 3 with a derivative

sigmoid <- function(x,dx){
  if(dx==FALSE)
    temp <- (1/(1+exp(-x))) else temp <- (1/(1+exp(-x)))*(1-(1/(1+exp(-x))))
    return(temp)
}
tootoo <- function(x,dx){
  if(dx==FALSE)
    temp <- (tanh(x)) else temp <- (1/(cosh(x))^2)
    return(temp)
}
#actually leaky ReLu since 0.01 is not 0.00
relu <- function(x,dx){
  if(dx==FALSE)
    temp <- (x<=0)*(0.01*x)+(x>0)*(x) else temp <- (x<=0)*(0.01)+(x>0)*(1)
    return(temp)
}
#Siraj says in https://www.youtube.com/watch?v=-7scQpJT7uo
#to use ReLu for hidden layers and use SOFTMAX for output for classifications
#but use linear activation for regression
## from http://tr.im/hH5A
softmax <- function (x){
  y <- max(x)
  z <- exp(x-y)
  s <- sum(z)
  logsumexp <- y + log(s)
  return(exp(x-logsumexp))
}

#mini-batch sample of 5 subjects/individuals
#3 input variables
input <- t(cbind(c(0,0,1),c(1,1,1),
                 c(1,0,1),c(0,1,1),c(1,0,0)))
colnames(input) <- c("feature 1","feature 2","feature 3")
rownames(input) <- c("subject 1","subject 2",
                     "subject 3","subject 4","subject 5")
output <- rbind(0,1,1,0,1)
colnames(output) <- c("output")
rownames(output) <- c("subject 1","subject 2",
                      "subject 3","subject 4","subject 5")
                      
#choose activation function
activate <- relu

#This code only works when there is 1 output node (last entry in q)...output is a column vector
#however, the last digit could be 1,2,3,...,k nodes if you wanted,
#just be sure to know that there are k-output vectors in the training
#and that you have to CBIND(output,output,...,output) to have the same
#number of columns as what you have (so you could have multivariate outcome)
q <- c(3,2,ncol(as.matrix(output)))
H <- length(q)
W <- list()
#first weights include bias (+1 random number row)
W[[1]] <- (matrix(runif((q[1])*(ncol(input)+1)),nrow=ncol(input)+1,ncol=q[1]))
#even weights matrices are transposed, even are not
#the dimensions are formulaic, try plugging in i=2,3,... and see
for (i in 2:(H)){
  if(i%%2==0) W[[i]] <- t(matrix(runif((ncol(W[[i-1]])+1)*(q[i])),nrow=q[i],ncol=ncol(W[[i-1]])+1))
  if(i%%2==1) W[[i]] <- (matrix(runif((q[i])*(ncol(W[[i-1]])+1)),nrow=ncol(W[[i-1]])+1,ncol=q[i]))
}
#last weights are column vector
W[[H]] <- matrix(runif((ncol(W[[H-1]])+1)*(1)),nrow=ncol(W[[H-1]])+1,ncol=q[H])

#ReLu can BLOW UP activations if you have too large a learning rate
#but at least you avoid the vanishing gradient common to TANH(X) and SIG(X)
learn <- 0.001
momentum <- 0.5
errors <- list()
gradients <- list()
layers <- list()
descent <- list()
#number of epochs for training
EEP <- 100000
WW <- list()
#train that mess
for (i in 1:EEP){

  #first or zero-th layer is just the unweighted, unbiased input data
  #first hidden layer is weighted input and bias
  layers[[1]] <- input
  #subsequent layers are the weighted inputs and biases
  for (k in 2:(H)){
    layers[[k]] <- activate(cbind(1,layers[[k-1]])%*%(W[[k-1]]),dx=FALSE)
  }
  #the predicted output is the output layer, i.e., the layer after the
  #last hidden layer, that is, layer H (output is H+1 in the network)
  layers[[H+1]] <- (cbind(1,layers[[k]])%*%(W[[k]]))
  
  #first error is the difference between predicted output (last layer)
  #and actual output
  errors[[1]] <- output-layers[[length(layers)]]
  #save the average error at the i_th epoch for a nice graph
  descent[[i]] <- mean(abs(errors[[1]]))
  if (i %% 1000 == 0) {print(c("Error=",mean(abs(errors[[1]]))))}
  gradients[[1]] <- errors[[1]]*(activate(layers[[length(layers)]],dx=T))
  #compute the errors and gradients at each layer, backpropagating the errors through the network
  for (j in 2:(H)){
    errors[[j]] <- gradients[[j-1]]%*%t(W[[length(layers)-j+1]][-1,])
    gradients[[j]] <- errors[[j]]*(activate(layers[[length(layers)-(j-1)]],dx=T))
  }
  #calculate the weight change from previous i, for using momentum
  for (g in 1:H){
    if(i==1)
    #if true, add no change in W (it is the first epoch, nothing has changed)
    #make sure same dimensions as W without the bias
      WW[[g]] <- 0*W[[g]][-1,] else WW[[g]] <- ((t(layers[[g]])%*%gradients[[(length(1:H)+1)-g]])*learn+WW[[g]]*momentum)
  }
#update weights using the estimated gradient
  for (m in 1:(H)){
    #the m_th weight matrix exluding bias#    #change to W scaled by learning rate#    #previous change to W scaled by momentum#
    W[[m]][-1,] <- W[[m]][-1,]+(t(layers[[m]])%*%gradients[[(length(1:H)+1)-m]])*learn+WW[[m]]*momentum
  }
}

#check out the (hopefully) descending gradient!
plot(NULL,xlim = c(1,length(descent)),ylim = c(min(as.numeric(descent)),
                                      0.1*max(as.numeric(descent))),
     main = "Gradient Descent",xlab="Epoch",ylab = "Average Error")
lines(as.numeric(descent),col="red")

#initialize the forecasted observation
TEST <- cbind(0,1,1) # answer should be 0 (see data)
#add bias
neurons <- list(cbind(1,TEST))
#pass new input forward through the network
for (i in 1:(H - 1)) {
  temp <- neurons[[i]] %*% W[[i]]
  act.temp <- activate(temp,dx=F)
  neurons[[i + 1]] <- cbind(1, act.temp)
}
#calculate predicted output
temp <- (neurons[[H]] %*% W[[H]])
temp

#initialize the forecasted observation
TEST <- cbind(1,0,0) # answer should be 1 (see data)
#add bias
neurons <- list(cbind(1,TEST))
#pass new input forward through the network
for (i in 1:(H - 1)) {
  temp <- neurons[[i]] %*% W[[i]]
  act.temp <- activate(temp,dx=F)
  neurons[[i + 1]] <- cbind(1, act.temp)
}
#calculate predicted output
temp <- (neurons[[H]] %*% W[[H]])
temp



