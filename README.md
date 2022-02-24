# Producing species distribution models (SDMs) for the DECIDE project

## Introduction

> DECIDE aims to collect these new data to improve biodiversity models for decision-making by putting recorders’ motivations at the heart of the process. Focusing initially on butterflies, moths and grasshoppers, this pioneering project aims to map 1,000 new species at fine-resolution and to improve these models through the records submitted by Recorders. Recorders will be guided where and when to make records in their region, so that their records can optimally improve the species maps - a process called ‘adaptive sampling’. https://www.ceh.ac.uk/our-science/projects/decide

The recorder tool is available here: https://decide.ceh.ac.uk/info/decide_info

For DECIDE we are running 'high-throughput' SDMs for butterflies and moths (and grasshoppers in future) at 100x100m resolution using a general set of bioclimactic variables, and land use. There is a vision to use earth observation data to improve these models in the course of the project. This is the repository for fitting SDMs and producing SDM predictions (for calculating species richness) and uncertainty (for the DECIDE score). This code also compiles the species-level predictions into seasonal species richness and uncertainty. This is a rework of the previous repo that worked on SDMs: https://github.com/TMondain/DECIDE_WP1

This repository does not deal with the 'recency of records' component of the DECIDE score as this is now processed dynamically in a different set of code.

## File structure




## Workflow

### Preparing data

None done here, all using outputs from other repository.

### Generating psudeo absences

`R/scripts/1_pseudoabsence_generation.Rmd`

Inputs:

 - `data/raw_data/traits/butterfly_moth_ecological_traits.csv` downloaded from: https://catalogue.ceh.ac.uk/documents/5b5a13b6-2304-47e3-9c9d-35237d1232c6
 - `data/derived_data/species/butterfly/records/butterfly_EastNorths_no_duplicates_2021_12_06.csv`
 - `data/derived_data/species/day_flying_moth/records/DayFlyingMoths_EastNorths_no_duplicates.csv`


Outputs:

 - `data/derived_data/species/pas.RDS`
 - `data/derived_data/species/species_list.RDS`
 - `data/derived_data/species/pas_meta_data.RDS`


### Fitting SDMs


`R/scripts/2_sun_SDMs.Rmd`

Inputs:

 - `data/derived_data/species/pas.RDS` generated in `1_pseudoabsence_generation.Rmd`
 - `data/derived_data/species/species_list.RDS` generated in `1_pseudoabsence_generation.Rmd`
 - `data/derived_data/environmental/envdata_fixedcoasts_nocorrs_100m_GB.gri` generated in previous environmental data sorting


Outputs:




### Making SDM predictions



### Combining to DECIDE score component 1: model uncertainty


### Transfer of data
