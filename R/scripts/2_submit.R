# working directory needs to be set to the project directory
if(grepl("R/scripts/",getwd())){
  set_wd("../../")
}

#load pacakges required by this script
library(rslurm)
library(rmarkdown)

#load packages needed by 2_run_SDMS.Rmd
library(dplyr)
library(raster)
library(terra)
library(randomForest)
library(mgcv)
library(dismo)
library(ggplot2)

# queue for lotus
queue_name = 'long-serial'

# time requirement
time = '47:59:59'

# memory requirement in MB
mem_req = 40000

#which group(s) to run models for?
#group_to_process <- c("butterfly","day_flying_moth","night_flying_moth")
group_to_process <- c("butterfly")

species_list <- readRDS("~/R/DECIDE_SDMs/species_list.RDS") %>% 
  filter(group %in% group_to_process) %>% 
  pull(species) %>%
  tolower() %>% gsub(" ","_",.)

#define which models we want to run for each species
models <- c("glm","gam","rf","maxent")

#create a dataframe of parameters for each job
params <- expand.grid(n_folds = 10,
                      species_name = species_list,
                      model_to_run = models,
                      plot_diagnostics = F,
                      run_test = F)

#wrap the render() function for running the Rmarkdown document in a function. This function can then be used
trigger_job <- function(n_folds,species_name,model_to_run,plot_diagnostics = F,run_test = F){
  params_list <- list(
    n_folds = n_folds,
    species_name = species_name,
    model_to_run = model_to_run,
    plot_diagnostics = plot_diagnostics,
    run_test = run_test
  )
  
  #create a species directory if it doesn't already exist
  if (!dir.exists(paste0("docs/models/",species_name))){
    dir.create(paste0("docs/models/",species_name))
  }
  
  #generate a filename for the rendered output
  out_file <- paste0(species_name,"_",model_to_run,".html")
  
  rmarkdown::render("R/scripts/2_run_SDMs.Rmd", 
                    params= params_list,
                    output_file = out_file,
                    output_dir = paste0("docs/models/",species_name,"/"))
}


#do a test to see if it works
trigger_job(n_folds = 10, species_name = "pieris_brassicae", model_to_run = "glm",run_test = T)

#generate temporary files for running the slurm job
slurm_apply(f = trigger_job, 
            params = params,
            nodes = nrow(params),
            job_name = "test",
            cpus_per_node = 1,
            slurm_options = list(partition = queue_name,
                                 time = as.character(time),
                                 mem = mem_req),
            submit = F,
            rscript_path = ""
            )



