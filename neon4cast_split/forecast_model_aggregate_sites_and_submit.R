forecast_model_aggregate_sites_and_submit <- function(folder, model_id, start, end){

  dir.create("temp")
  setwd("temp")

  # use library tidyverse
  library("tidyverse")
  library("neon4cast")
  
  # get the temporary the site data one by one from the bucket.
  for (i in as.numeric(start):as.numeric(end)){
    forecast_file <- paste0("aquatics","-",model_id,"-",i,".csv.gz")
    FaaSr::faasr_get_file(local_file=forecast_file, remote_folder=folder, remote_file=forecast_file)
  }

  # merge the data
  file_lists <- list.files()
  result <- map_dfr(file_lists, read_csv)
  
  # set the data and file name
  file_date <- Sys.Date() #forecast$reference_datetime[1]
  forecast_file <- paste0("aquatics","-",file_date,"-",model_id,".csv.gz")
  
  # write file and put to the bucket
  write_csv(result, forecast_file)

  # submit forecast
  neon4cast::submit(forecast_file = forecast_file, metadata = NULL, ask = FALSE)
  FaaSr::faasr_put_file(local_file=forecast_file, remote_folder=folder, remote_file=forecast_file)
  
  # delete the temporary files
  for (i in as.numeric(start):as.numeric(end)){
    forecast_file <- paste0("aquatics","-",model_id,"-",i,".csv.gz")
    FaaSr::faasr_delete_file(remote_folder=folder, remote_file=forecast_file)
  }
}
