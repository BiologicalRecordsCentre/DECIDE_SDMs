# DECIDE_SDMs

Supercedes https://github.com/TMondain/DECIDE_WP1

## Introduction

Running SDMs for the DECIDE project

## File structure

`/data` - contains data
`/R` - contains R code



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
