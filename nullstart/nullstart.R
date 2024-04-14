nullstart <- function() {
    # Example function that does nothing but log a short string
    # Can be used, for example, as a start function that triggers concurrent executions
    
    faasr_log("nullstart successfully invoked")

    a <- Sys.time()
    readr::write_rds(a, "start_invoke.RDS")
    FaaSr::faasr_put_file(remote_folder=paste0(.faasr$FaaSrLog, "/", .faasr$InvocationID), 
                          remote_file="start_invoke.RDS", 
                          local_file="start_invoke.RDS")
}
