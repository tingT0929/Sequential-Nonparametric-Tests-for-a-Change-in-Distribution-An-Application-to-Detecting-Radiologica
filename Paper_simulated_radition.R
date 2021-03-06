

## Code that can be used to replicate the results in Table 2.
## To replicate a line of such table you first need to run "Paper_generate_radiation_ground_truth.R" 
### There you need to set the pre and post change densities desired. Once that has been selected, and run
###  this script will compute delay times under different scenarios for different values of 
###  the total intensity of photons

setwd(paste(working_directory,"/Code_J",sep=""))


theta0 = background_train
thetac = sim_spectrum

matplot(cbind(theta0,thetac),type ="l")


### 
d = floor(log(length(thetac))/log(2))## this is 11 in all cases, as there are 2^11  bins


source("Generate_data.R")
## ploting pre and post change densities
matplot(cbind(theta0,thetac),type="l")



###  setting parameters for simulations
####Time horizon for each trial
T_grid   =   c(700)
####  2^{d_grid[i]} is the number of bins, in our case this is just 2^11
d_grid = c(11)
#### 2^d  * Total_rate_factor_grid is the total number of photon counts 
Total_rate_factor_grid = c(100/2^d,500/2^d,1000/2^d) #c(2,3,4)
####  For every setting, NMC is the number of  trials over wich we average
NMC = 50
#### Window size
L_grid = c(50)

size_prob  = .999 ### 1 - size_prob  is the probability of a false alarm


#####  Arrays to store thresholds
k_alpha_grid = c(1.36) ## this is changed later
k_alpha_grid_star = c(1.36)
level_grid =  c(.5) #c(.95,.99)
level_grid_dir = c(.5) 
log_A_grid = c(0) ## this is changed later
k_alpha_grid_old = c(1.36)
tresd_hold_mle_grid = c(0)

tres_hold_KS = rep(0,length(k_alpha_grid))
tres_hold_KS_old = rep(0,length(k_alpha_grid_old))
tres_hold_log_Rnf = rep(0,length(log_A_grid))
tresd_hold_mle_grid = c(0)

#v = min(floor(runif(1)*T),T)
######################################################### ######################################   
ind_T  = 1
ind_d  = 1
ind_TRF = 1
T = T_grid[ind_T]
d = d_grid[ind_d]


####  Arrays to store false alarms
average_false_alarms_KS_old = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid),length(k_alpha_grid_old),length(L_grid)))
average_false_alarms_KS = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid),length(k_alpha_grid),length(L_grid)))
average_false_alarms_Rnf = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid),length(log_A_grid),length(L_grid)))
average_false_alarms_mle = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid),length(tresd_hold_mle_grid),length(L_grid)))
average_false_alarms_KS_star = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid),length(k_alpha_grid_star),length(L_grid)))
average_false_alarms_cusum = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid)))


#### Arrays to store delay time for different methods
average_delay_time_mle = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid),length(tresd_hold_mle_grid),length(L_grid)))
average_delay_time_KS = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid),length(k_alpha_grid),length(L_grid)))
average_delay_time_KS_old = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid),length(k_alpha_grid_old),length(L_grid)))
average_delay_time_Rnf = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid),length(log_A_grid),length(L_grid)))
average_delay_time_KS_star = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid),length(k_alpha_grid_star),length(L_grid)))
average_delay_time_cusum = array(0, c(length(T_grid),length(d_grid),length(Total_rate_factor_grid) ))



for(ind_L in 1:length(L_grid))
{
  L = L_grid[ind_L]
  
  for(ind_T in 1:length(T_grid))
  {
    T = T_grid[ind_T]
    ######################################  
    for(ind_d in 1:length(d_grid))
    {
      d = d_grid[ind_d]
      ######################################  
      for(ind_TRF in 1:length(Total_rate_factor_grid))
      {
        Total_rate_factor = Total_rate_factor_grid[ind_TRF ]
        
        ###  True normalized pre and post densities 
        ## pre change
        
        m = 2^d
        
        lambda0 = Total_rate_factor*m*theta0
        lambdac = Total_rate_factor*m*thetac
        
        
        ###  Training period
        temp = Training_period(ntraining = 1000,m,d,lambda0) 
        #  F0 = temp$F0
        alpha = temp$alpha
        total_rate = temp$total_rate

        theta0_hat = temp$theta0
        F0 =  cumsum(theta0)
        ###########################
        ### KS star
        k_alpha_grid_star[1]  = sqrt(log(2*1000*(L+1))/2)
        
        ################################################################  
        #       N = 500
        kappa_grid = 10^seq(-5,-1,length= 20)
        
        ################################################################      
        ## KS tres_hold
        NS =  100
 
        k_alpha_grid[1]  = 0
        KSnew = matrix(0,NS,1000)
        for(i in 1:NS)
        {
          KSnew [i,] =   new_choose_tres_hold_KS(N = 1000,theta0,total_rate,d,F0, size_prob,L)
        }
        lower = min(KSnew )
        upper = max(KSnew )
        
        threshold_grid  =  seq(lower,upper,length = 1000)
        Expected_false_alarms = rep(0,length(threshold_grid ))
        
        for(j in 1:length(threshold_grid))
        {
          aux = rep(0,NS)
          for(i in 1:NS)
          {
            aux[i] =    length(which(KSnew[i,]> threshold_grid[j]))
          }
          Expected_false_alarms[j] =  mean(aux)     
        }
        
        j_best =  which.min(abs(Expected_false_alarms - 1))
        
        k_alpha_grid[1]  =  threshold_grid[j_best]
        
        ################################################################      
        ## Ks old
        
        KS = matrix(0,NS,1000)
        k_alpha_grid_old[1]  = 0
        for(i in 1:NS)
        {
          KS[i,] = new_choose_tres_hold_KS_old(1,N = 1000,theta0,total_rate,d,F0, size_prob,L)
        }
        
        lower = min(KS)
        upper = max(KS)
        
        threshold_grid  =  seq(lower,upper,length = 1000)
        Expected_false_alarms = rep(0,length(threshold_grid ))
        
        for(j in 1:length(threshold_grid))
        {
          aux = rep(0,NS)
          for(i in 1:NS)
          {
            aux[i] =    length(which(KS[i,]> threshold_grid[j]))
          }
          Expected_false_alarms[j] =  mean(aux)     
        }
        
        j_best =  which.min(abs(Expected_false_alarms - 1))
        
        k_alpha_grid_old[1]  =  threshold_grid[j_best]  
        
        
        ################################################################      
        ### log_Rnf tresd_hold
        
        log_A_grid[1]  =  0
        log_Rnf  = matrix(0,NS,1000)
        for(i in 1:NS)
        {
          log_Rnf[i,] = new_choose_tres_hold_log_Rnf(N = 1000,theta0,sum(lambda0),d, size_prob,L)
        }    
        
        lower = min( log_Rnf)
        upper = max( log_Rnf)
        
        threshold_grid  =  seq(lower,upper,length = 1000)
        Expected_false_alarms = rep(0,length(threshold_grid ))
        
        for(j in 1:length(threshold_grid))
        {
          aux = rep(0,NS)
          for(i in 1:NS)
          {
            aux[i] =    length(which(log_Rnf[i,]> threshold_grid[j]))
          }
          Expected_false_alarms[j] =  mean(aux)     
        }
        
        j_best =  which.min(abs(Expected_false_alarms - 1))
        
        log_A_grid[1] =  threshold_grid[j_best]  
        
        
        ################################################################        
        ### MLE tres_hold
        
        tresd_hold_mle_grid[1]   = 0
        mle  = matrix(0,NS,1000)
        for(i in 1:NS)
        {
          mle[i,] =    new_choose_tres_hold_mle(N = 1000,theta0,lambda0,d, size_prob,L)
        }   
        
        lower = min( mle)
        upper = max( mle)
        
        threshold_grid  =  seq(lower,upper,length = 1000)
        Expected_false_alarms = rep(0,length(threshold_grid ))
        
        for(j in 1:length(threshold_grid))
        {
          aux = rep(0,NS)
          for(i in 1:NS)
          {
            aux[i] =    length(which(mle[i,]> threshold_grid[j]))
          }
          Expected_false_alarms[j] =  mean(aux)     
        }
        
        j_best =  which.min(abs(Expected_false_alarms - 1))
        
        tresd_hold_mle_grid[1] =  threshold_grid[j_best]  
        
        
        ######################################################
        ###################################################
        ######## cusum
        cusum = matrix(0,NS,1000)
        
        for(i in 1:NS)
        {
          temp  = choose_treshold_np_cusum(1,N = 1000,lambda0,d,size_prob,L)
          cusum[i,] = temp$y        
        }
        d_prob = temp$d_prob
        
        lower = min( cusum)
        upper = max( cusum)
        
        threshold_grid  =  seq(lower,upper,length = 1000)
        Expected_false_alarms = rep(0,length(threshold_grid ))
        
        for(j in 1:length(threshold_grid))
        {
          aux = rep(0,NS)
          for(i in 1:NS)
          {
            aux[i] =    length(which( cusum[i,]> threshold_grid[j]))
          }
          Expected_false_alarms[j] =  mean(aux)     
        }
        
        j_best =  which.min(abs(Expected_false_alarms - 1))
        
        cusum_threshold  =  threshold_grid[j_best]  
        
        
        ######################################    
        
        false_alarms_KS = matrix(0,NMC,length(k_alpha_grid))
        false_alarms_KS_star = matrix(0,NMC,length(k_alpha_grid_star))
        false_alarms_KS_old = matrix(0,NMC,length(k_alpha_grid_old))
        false_alarms_Rnf = matrix(0,NMC,length(log_A_grid))
        false_alarms_mle = matrix(0,NMC,length(tresd_hold_mle_grid))
        false_alarms_cusum = rep(0,NMC)        
        
        delay_time_KS =   matrix(0,NMC,length(k_alpha_grid)) 
        delay_time_KS_star =   matrix(0,NMC,length(k_alpha_grid_star)) 
        delay_time_KS_old =   matrix(0,NMC,length(k_alpha_grid_old)) 
        delay_time_Rnf = matrix(0,NMC,length(log_A_grid))
        delay_time_mle =   matrix(0,NMC,length(tresd_hold_mle_grid)) 
        delay_time_cusum =   rep(0,NMC) 
        
        
        
        v_array = rep(0,NMC )
        
        for(iter in 1:NMC)
        { 
          print("iter")
          print(iter) 
          
          KS = rep(0,T) 
          KS_old = rep(0,T) 
          log_Rnf = rep(0,T) 
          mle = rep(0,T) 
          cusum =  rep(0,T)
          x =  matrix(0,T,m)
          
          
          v = min(floor( runif(1)*((T-1-100)-100) + 100    ),T)
          v_array[iter] = v
          
          cum_x = rep(0,length(lambda0))
          
          
          ptm <- proc.time()
          for(t in 1:T)
          {
            lambda0_t = lambda0 
            
            lambdac_t = lambdac 
            
            if(t <= v) 
            { 
              x[t, ] =rpois(length(theta0), lambda0_t )
            }  
            if(t > v)
            { 
              x[t,] = rpois(length(theta0),lambdac_t)
            }
            
            cum_x = cum_x + x[t,]
            
            KS_old[t] =  sqrt(sum(cum_x))*kolmogorov_statistic(cum_x,F0)
            
            #
            log_Rnf[t] = logRnf(t,1,1,x,L,lambda0)
            
            mle[t] = mle_detection(x,t,L,lambda0)
            
            KS[t] = sequential_KS_statistics(x,t,F0,L)
            
            #####  cusum 
            
            if(t==1)
            {
              S1_prev = rep(0,m+1)
              S2_prev = rep(0,m+1)
            }
            temp  = cusum_statistic(c(x[t,]-lambda0,0),d_prob,S1_prev,S2_prev,k=0)
            cusum[t] =  temp$y            
            S1_prev = temp$S1_now
            S2_prev = temp$S2_now
            
          }## close for 1:T      
          proc.time() - ptm
          
          for(j in 1:length(k_alpha_grid))
          {
            false_alarms_KS[iter,j] = length(which( KS[1:v]> k_alpha_grid[j]))
          }
          
          for(j in 1:length(k_alpha_grid))
          {
            false_alarms_KS_star[iter,j] = length(which( KS[1:v]> k_alpha_grid_star[j]))
          }
          
          
          for(j in 1:length(k_alpha_grid_old))
          {
            false_alarms_KS_old[iter,j] = length(which( KS_old[1:v]> k_alpha_grid_old[j]))
          }
          
          for(j in 1:length(log_A_grid))
          {
            false_alarms_Rnf[iter,j] = length(which( log_Rnf[1:v]> log_A_grid[j]  ))
          } 
          for(j in 1:length(tresd_hold_mle_grid))
          {
            false_alarms_mle[iter,j] = length(which( mle[1:v]> tresd_hold_mle_grid[j]))
          }
          
          false_alarms_cusum[iter] = length(which(cusum > cusum_threshold))
          
          ## update delayed time
          
          for(j in 1:length(k_alpha_grid))
          {
            ind2 = which(KS[(1+v):T] > k_alpha_grid[j])
            delay_time_KS[iter ,j] = T - (v+1)
            
            if( length(ind2) > 0)
            {
              delay_time_KS[iter,j ] = min(ind2) -1
            }
          }
          for(j in 1:length(k_alpha_grid_star))
          {
            ind2 = which(KS[(1+v):T] > k_alpha_grid_star[j])
            delay_time_KS_star[iter ,j] = T - (v+1)
            
            if( length(ind2) > 0)
            {
              delay_time_KS_star[iter,j ] = min(ind2) -1
            }
          }
          
          for(j in 1:length(k_alpha_grid_old))
          {
            ind2 = which(KS_old[(1+v):T] > k_alpha_grid_old[j])
            delay_time_KS_old[iter ,j] = T - (v+1)
            
            if( length(ind2) > 0)
            {
                  delay_time_KS_old[iter,j ] = min(ind2) -1
            }
          }
          for(j in 1:length(tresd_hold_mle_grid  ))
          {
            ind2 = which(mle[(1+v):T] > tresd_hold_mle_grid[j])
            delay_time_mle[iter ,j] = T - (v+1)
            
            if( length(ind2) > 0)
            {
              delay_time_mle[iter,j ] = min(ind2) -1
            }
          } 
          for(j in 1:length(log_A_grid))
          {
            ind2 = which(log_Rnf[(1+v):T] > log_A_grid[j])
            delay_time_Rnf[iter ,j] = T - (v+1)
            if( length(ind2) > 0)
            {
              #             delay_time_Rnf[iter ,j] = T - (v+1)
              #             if( length(ind2) >0 ){delay_time_Rnf[iter,j ] = min(ind2) -1}
              #             indices_detected_trials_Rnf[iter,j] = 1 
              delay_time_Rnf[iter,j ] = min(ind2) -1
            }
          }
          #### cusum
          
          ind = which(cusum[(1+v):T] > cusum_threshold)
          delay_time_cusum[iter] = T - (v+1)
          
          if( length(ind) > 0)
          {
            delay_time_cusum[iter] = min(ind) -1
          }
          
        }## close for NMC simulations, iter
        
        for(j in 1:length(k_alpha_grid_old))
        {
          average_delay_time_KS_old[ind_T,ind_d,ind_TRF,j,ind_L] = mean( delay_time_KS_old[,j])
          average_false_alarms_KS_old[ind_T,ind_d,ind_TRF,j,ind_L] = mean(false_alarms_KS_old[,j])
        }
        for(j in 1:length(k_alpha_grid))
        {
          average_delay_time_KS[ind_T,ind_d,ind_TRF,j,ind_L] = mean( delay_time_KS[,j])
          average_false_alarms_KS[ind_T,ind_d,ind_TRF,j,ind_L] = mean(false_alarms_KS[,j])
        }
        for(j in 1:length(k_alpha_grid_star))
        {
          average_delay_time_KS_star[ind_T,ind_d,ind_TRF,j,ind_L] = mean( delay_time_KS_star[,j])
          average_false_alarms_KS_star[ind_T,ind_d,ind_TRF,j,ind_L] = mean(false_alarms_KS_star[,j])
        }
        for(j in 1:length( tresd_hold_mle_grid ))
        {
          average_delay_time_mle[ind_T,ind_d,ind_TRF,j,ind_L] = mean( delay_time_mle[,j])
          average_false_alarms_mle[ind_T,ind_d,ind_TRF,j,ind_L] = mean(false_alarms_mle[,j])
        }
        for(j in 1:length(log_A_grid))
        {
          average_delay_time_Rnf[ind_T,ind_d,ind_TRF,j,ind_L] = mean( delay_time_Rnf[,j])
          average_false_alarms_Rnf[ind_T,ind_d,ind_TRF,j,ind_L] = mean(false_alarms_Rnf[,j])
        }
        
        average_delay_time_cusum[ind_T,ind_d,ind_TRF] = mean( delay_time_cusum)
        average_false_alarms_cusum[ind_T,ind_d,ind_TRF] = mean(false_alarms_cusum)
        
        
        print("L")
        print(L)
        print("average v")
        print(mean(v_array))
        print("average_delay_time_KS")
        print(average_delay_time_KS[ind_T,ind_d,ind_TRF,,ind_L])
        print("average_delay_time_KS_star")
        print(average_delay_time_KS_star[ind_T,ind_d,ind_TRF,,ind_L])
        print("average_delay_time_KS_old")
        print(average_delay_time_KS_old[ind_T,ind_d,ind_TRF,,ind_L] )
        print("average_delay_time_Rnf")
        print(average_delay_time_Rnf[ind_T,ind_d,ind_TRF,,ind_L] )
        print("average_delay_time_mle")
        print(average_delay_time_mle[ind_T,ind_d,ind_TRF,,ind_L])
        print("average_delay_time_cusum")
        print(average_delay_time_cusum[ind_T,ind_d,ind_TRF])
        
        
        print(" average_false_alarms_KS")
        print( average_false_alarms_KS[ind_T,ind_d,ind_TRF,,ind_L])
        print(" average_false_alarms_KS_star")
        print( average_false_alarms_KS_star[ind_T,ind_d,ind_TRF,,ind_L])
        print("average_false_alarms_KS_old")
        print(average_false_alarms_KS_old[ind_T,ind_d,ind_TRF,,ind_L] )
        print("average_false_alarms_Rnf")
        print(average_false_alarms_Rnf[ind_T,ind_d,ind_TRF,,ind_L] )
        print(" average_false_alarms_mle")
        print( average_false_alarms_mle[ind_T,ind_d,ind_TRF,,ind_L])
        print(" average_false_alarms_cusum")
        print( average_false_alarms_cusum[ind_T,ind_d,ind_TRF])
        
        
      }## close for Total rate
    }## close for d
  }## close for T
}### close for L


