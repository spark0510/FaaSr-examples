# Purpose: Create a dataset for surrogate development

# Notes:
# Data frame format: Parameter 1, parameter 2, temp/weather deviation, datetime, 
# variable, prediction, observation
# Arguments for FaaSr:
#   start, end : integers specifying the start and end (inclusive) of model scenario tot run
#   output_folder : string name of the outputt folder to store CSV outputs inside your S3 bucket
#   calibration_repo : string URL of git repository with calibration data
glm3_assemble_surrogate_dataset <- function(start, end, output_folder, calibration_repo)
{
    # load packages ----
    library(tidyverse)
    library(lubridate)
    library(glmtools)
    library(GLM3r)
    
    a <- Sys.time()
    
    system(paste0("git clone ", calibration_repo))
    # set working directory; you can change this to be any calibration folder ----
    setwd("./glm3_calibration") 

    # create matrix of parameter values using maximin space-filling design ----
    phyto_groups <- c("cyano","green","diatom")
    param_names <- c("pd%R_growth", "pd%w_p")

    # Latin hypercube function
    # n runs for m factors
    # so start with 1000 runs for 6 factors (parameters)

    mylhs <- function(n, m)
    {
        ## generate the Latin hypercube 
        l <- (-(n - 1)/2):((n - 1)/2)
        L <- matrix(NA, nrow=n, ncol=m)
        for(j in 1:m) L[,j] <- sample(l, n)
        
        ## draw the random uniforms and turn the hypercube into a sample
        U <- matrix(runif(n*m), ncol=m)
        X <- (L + (n - 1)/2 + U)/n
        colnames(X) <- paste0("x", 1:m)
        
        ## return the design and the grid it lives on for visualization
        return(list(X=X, g=c((l + (n - 1)/2)/n,1)))
    }

    Dlist <- mylhs(n = 1000, m = 6)

    # data wrangling to get parameter values in correct range
    scale_R_growth <- function(x, na.rm = FALSE) x*3 + 0.5
    scale_w_p <- function(x, na.rm = FALSE)
    {
        for(i in 1:length(x)){
        if(x[i] == 0.5){x[i] <- 0} else if(x[i] < 0.5){x[i] <- x[i]*-2} else {x[i] <- (x[i]-0.5)*2}
        }
        
        return(x)
    }

    param_values <- tibble(data.frame(Dlist$X)) %>%
    mutate_at(c("x1","x2","x3"), scale_R_growth) %>%
    mutate_at(c("x4","x5","x6"), scale_w_p)
    colnames(param_values) <- c("R_growth_cyano","R_growth_green","R_growth_diatom","w_p_cyano","w_p_green","w_p_diatom")

    # set nml filepath
    nml_file <- file.path('./aed/aed2_phyto_pars_27NOV23_MEL.nml')

    # set file location of output
    nc_file <- file.path('./output/output.nc') 

    # save starting version of nml in environment so you can reset after
    start_nml <- glmtools::read_nml(nml_file = nml_file)

    # for-loop to run GLM using different parameter values
    
    for(j in start:end){
        # read in nml
        nml <- glmtools::read_nml(nml_file = nml_file)
        
        # get current parameter values
        curr_R_growth <- nml$phyto_data[[param_names[1]]]
        curr_w_p <- nml$phyto_data[[param_names[2]]]
        
        # replace parameter value as desired
        curr_R_growth <- unname(unlist(param_values[j,c(1:3)]))
        curr_w_p <- unname(unlist(param_values[j,c(4:6)]))
        
        # set nml parameter values
        new_nml <- glmtools::set_nml(nml, arg_name = param_names[1], arg_val = curr_R_growth)
        new_nml1 <- glmtools::set_nml(new_nml, arg_name = param_names[2], arg_val = curr_w_p)
        
        # create path to write permuted nml to file
        write_path <- nml_file
        
        # write permuted nml to file
        glmtools::write_nml(new_nml1, file = write_path)
        
        # run GLM-AED using GLM3r
        GLM3r::run_glm()

        # pull variable of interest from model output
        var <- glmtools::get_var(nc_file, var_name = "PHY_tchla", reference="surface", z_out=1.6)
        
        # pull parameters from model output
        R_growth <- new_nml1$phyto_data$`pd%R_growth`
        w_p <- new_nml1$phyto_data$`pd%w_p`
        
        # assemble dataframe for that model run
        temp <- data.frame(R_growth_cyano = R_growth[1],
                            R_growth_green = R_growth[2],
                            R_growth_diatom = R_growth[3],
                            w_p_cyano = w_p[1],
                            w_p_green = w_p[2],
                            w_p_diatom = w_p[3],
                            deviation = 0,
                            datetime = var$DateTime,
                            variable = "PHY_tchla_1.6",
                            prediction = var$PHY_tchla_1.6)

        # make sure you reset nml
        glmtools::write_nml(start_nml, file = nml_file)
        
        # write model run and corresponding parameters to file
        filename <- paste0("model_scenario_",j,".csv")
        model_run_file <- paste0("./output/",filename)
        write.csv(temp, file = model_run_file,row.names = FALSE)
        faasr_put_file(local_file=model_run_file, remote_folder=output_folder, remote_file=filename)
    }
    
    b <- Sys.time()
    readr::write_rds(a, "exec_start.RDS")
    readr::write_rds(b, "exec_end.RDS")
    FaaSr::faasr_put_file(remote_folder=paste0(.faasr$FaaSrLog, "/", .faasr$InvocationID, "/", .faasr$FunctionInvoke), 
                          remote_file="exec_start.RDS", 
                          local_file="exec_start.RDS")
    FaaSr::faasr_put_file(remote_folder=paste0(.faasr$FaaSrLog, "/", .faasr$InvocationID, "/", .faasr$FunctionInvoke), 
                          remote_file="exec_end.RDS", 
                          local_file="exec_end.RDS")
}
