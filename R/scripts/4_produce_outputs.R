setwd("../../")

library(dplyr)

library(terra)

phenology <- readRDS("data/derived_data/species/phenology.RDS")

group_to_process <- "night_flying_moth" 



data_location <- list(
  night_flying_moth = "../../thoval/DECIDE/SDMs/outputs/nightflying_moth/combined_model_outputs/PA_thinned_10000nAbs_2021_12_08"
)

file_name_template <- list(
  night_flying_moth = list(
    mean = "_PA_thinned_10000nAbs_2021_12_08_mean_score_weightedmeanensemble.grd",
    variation = "_PA_thinned_10000nAbs_2021_12_08_mean_score_weightedvariationensemble.grd",
    auc = "_mean_score_aucOuts.csv"
  )   
)


species_list <- readRDS("data/derived_data/species/species_list.RDS") %>% 
  filter(group == group_to_process) %>% 
  pull(species) %>%
  #tolower() %>% 
  gsub(" ","_",.)


phenology <- phenology %>% filter(scientific_name %in% (species_list %>% gsub("_"," ",.)))

prediction_files <- paste0(species_list,file_name_template[[group_to_process]][["mean"]])
sd_files <- paste0(species_list,file_name_template[[group_to_process]][["variation"]])


file_check_df <- data.frame(species = species_list,
                            prediction_file = prediction_files,
                            sd_file = sd_files)

#files we have
files_available <- list.files(data_location[[group_to_process]],pattern = ".grd")


#check the target files against files that are available and add a new column to the df reporting on this check
file_check_df$prediction_check <- file_check_df$prediction_file %in% files_available
file_check_df$sd_check <- file_check_df$sd_file %in% files_available

#highlight missing species models but continues none-the-less and makes the outputs with whatever species it has predictions for.

species_to_use <- file_check_df %>% filter(prediction_check, prediction_check) %>% dplyr::select(species,prediction_check,sd_check) %>% pull(species)

print("Species with predictions:")
#species_to_use

#species with missing predictions
print("Species with missing predictions:")
file_check_df %>% filter(!prediction_check |!prediction_check) %>% dplyr::select(species,prediction_check,sd_check)

#file_check_df

#get the filenames we want to use
file_check_df <- file_check_df %>% filter(sd_check,prediction_check)
prediction_files <- file_check_df$prediction_file
sd_files <- file_check_df$sd_file
species_to_use <- file_check_df$species



#prediction raster
prediction_raster <- terra::rast(paste0(data_location[[group_to_process]],"/",prediction_files))
names(prediction_raster) <- species_to_use
prediction_raster
mem_info(prediction_raster)
raster_extent <- ext(prediction_raster[[1]])

#sd raster
sd_raster <- terra::rast(paste0(data_location[[group_to_process]],"/",sd_files))
names(sd_raster) <- species_to_use
sd_raster
mem_info(sd_raster)







#specify where the files should be saved to
richness_output_location <- paste0("data/derived_data/combined_model_outputs/",group_to_process,"/species_richness/")
uncertainty_output_location <- paste0("data/derived_data/combined_model_outputs/",group_to_process,"/model_uncertainty/")


#moths in lowercase
months_lower <- tolower(month.abb)


#build all time richness and model uncertainty layers
terra::app(prediction_raster,sum,filename = paste0(richness_output_location,"raster_all_year.tif"),overwrite = T)



terra::app(sd_raster,mean,filename =  paste0(uncertainty_output_location,"raster_all_year.tif"),overwrite = T)


#seasonal
#looping through richness then uncertainty in the hope that accessing a consistent set of files makes it faster (this might be superstition)
for(product in c("richness","uncertainty")){
  for (i in 1:12){
    species <- phenology %>% filter(month_num == i,value) %>% pull(scientific_name) %>% gsub(" ","_",.)
    
    if (length(species)!=0){
      if(product == "richness"){
        prediction_raster[[names(prediction_raster) %in% species]] %>% 
          terra::app(.,sum,filename = paste0(richness_output_location,group_to_process,"_species_richness_raster_",months_lower[i],".tif"),overwrite = T)
      } else {
        sd_raster[[names(sd_raster) %in% species]] %>% 
          terra::app(.,mean, filename = paste0(uncertainty_output_location,group_to_process,"_sdm_var_raster_",months_lower[i],".tif"),overwrite = T)
      }
    }
    
  }
}
