
# Producing species distribution models (SDMs) for the DECIDE project

## Introduction

> DECIDE aims to collect these new data to improve biodiversity models
> for decision-making by putting recorders’ motivations at the heart of
> the process. Focusing initially on butterflies, moths and
> grasshoppers, this pioneering project aims to map 1,000 new species at
> fine-resolution and to improve these models through the records
> submitted by Recorders. Recorders will be guided where and when to
> make records in their region, so that their records can optimally
> improve the species maps - a process called ‘adaptive sampling’.
> <https://www.ceh.ac.uk/our-science/projects/decide>

The recorder tool is available here:
<https://decide.ceh.ac.uk/info/decide_info>

For DECIDE we are running ‘high-throughput’ SDMs for butterflies and
moths (and grasshoppers in future) at 100x100m resolution using a
general set of bioclimactic variables, and land use. There is a vision
to use earth observation data to improve these models in the course of
the project. This is the repository for fitting SDMs and producing SDM
predictions (for calculating species richness) and uncertainty (for the
DECIDE score). This code also compiles the species-level predictions
into seasonal species richness and uncertainty. This is a rework of the
previous repo that worked on SDMs:
<https://github.com/TMondain/DECIDE_WP1>

This repository does not deal with the ‘recency of records’ component of
the DECIDE score as this is now processed dynamically in a different set
of code.

## Workflow

### Preparing data

Currenty data processing is not done here, all using outputs from
previous repository `DECIDE_WP1`.

### Generating psudeo absences

Here we are using the general background of recording activity to see
where records have NOT been made of the target species to generate
‘pseudoabsences’.

`R/scripts/1_pseudoabsence_generation.Rmd`

Inputs:

-   `data/raw_data/traits/butterfly_moth_ecological_traits.csv`
    downloaded from:
    <https://catalogue.ceh.ac.uk/documents/5b5a13b6-2304-47e3-9c9d-35237d1232c6>
-   `data/derived_data/species/butterfly/records/butterfly_EastNorths_no_duplicates_2021_12_06.csv`
-   `data/derived_data/species/day_flying_moth/records/DayFlyingMoths_EastNorths_no_duplicates.csv`

Outputs:

-   `data/derived_data/species/pas.RDS`
-   `data/derived_data/species/species_list.RDS`
-   `data/derived_data/species/pas_meta_data.RDS`

### Fitting SDMs and making SDM predictions

`R/scripts/2_run_SDMs.Rmd`

Inputs:

-   `data/derived_data/species/pas.RDS` generated in
    `1_pseudoabsence_generation.Rmd`
-   `data/derived_data/species/species_list.RDS` generated in
    `1_pseudoabsence_generation.Rmd`
-   `data/derived_data/environmental/envdata_fixedcoasts_nocorrs_100m_GB.gri`
    envronmental data generated in previous environmental data sorting

Outputs:

The outputs are saved in their corresponding folder in
`data/derived_data/model_outputs_by_species` where there are 4 folders
for each model type: `gam`, `glm`, `maxent`, `rf`. There is also an
`ensemble` folder but that is filled in the next stage.

For each model run for each species we end up with 4 files

-   `mean_predictions_[SPECIES].grd/gri` is the mean predictions
-   `bootstrapped_sd_[SPECIES].grd/gri` is the standard deviation
    between each bootstrapped model prediction
-   `mean_AUC_[SPECIES].rds` is the mean AUC for that model/species
    combo stored as a single numeric value
-   `models_[SPECIES].rds` contains one of the models, the AUCs from
    each model, the mean AUC across all models (again) and the summaries
    for all models.

### Combining to seasonal and all-time DECIDE score model uncertainty component

Inputs:

-   `data/derived_data/model_outputs_by_species`

Outputs \* `data/derived_data/model_outputs_by_species/ensemble` \*
`data/derived_data/combined_model_outputs/`

### Transfer of data

## File structure

Generated with `fs::dir_tree()`

### R

    ## R
    ## +-- functions
    ## |   +-- cpa.R
    ## |   \-- fsdm.R
    ## \-- scripts
    ##     +-- 1_pseudoabsence_generation.Rmd
    ##     \-- 2_run_SDMs.Rmd

### Data

    ## data
    ## +-- derived_data
    ## |   +-- combined_model_outputs
    ## |   +-- environmental
    ## |   |   +-- elevation_UK.grd
    ## |   |   +-- elevation_UK.gri
    ## |   |   +-- elevation_UK.tif
    ## |   |   +-- envdata_fixedcoasts_nocorrs_100m_GB.grd
    ## |   |   +-- envdata_fixedcoasts_nocorrs_100m_GB.gri
    ## |   |   +-- lcm2015gb100perc.grd
    ## |   |   +-- lcm2015gb100perc.gri
    ## |   |   \-- lcm2015gb100perc.tif
    ## |   +-- model_outputs_by_species
    ## |   |   +-- ensemble
    ## |   |   +-- gam
    ## |   |   +-- glm
    ## |   |   |   +-- boostrapped_sd_pieris_brassicae.grd
    ## |   |   |   +-- boostrapped_sd_pieris_brassicae.gri
    ## |   |   |   +-- mean_AUC_pieris_brassicae.rds
    ## |   |   |   +-- mean_prediction_pieris_brassicae.grd
    ## |   |   |   +-- mean_prediction_pieris_brassicae.gri
    ## |   |   |   \-- models_pieris_brassicae.rds
    ## |   |   +-- maxent
    ## |   |   \-- rf
    ## |   \-- species
    ## |       +-- butterfly
    ## |       |   +-- pseudoabsences
    ## |       |   |   \-- butterfly_PA_thinned_10000nAbs.rdata
    ## |       |   \-- records
    ## |       |       \-- butterfly_EastNorths_no_duplicates_2021_12_06.csv
    ## |       +-- day_flying_moth
    ## |       |   +-- pseudoabsences
    ## |       |   |   \-- moth_PA_thinned_10000nAbs.rdata
    ## |       |   \-- records
    ## |       |       \-- DayFlyingMoths_EastNorths_no_duplicates.csv
    ## |       +-- pas.RDS
    ## |       +-- pas_meta_data.RDS
    ## |       \-- species_list.RDS
    ## \-- raw_data
    ##     +-- species
    ##     |   +-- butterfly
    ##     |   \-- day_flying_moth
    ##     \-- traits
    ##         \-- butterfly_moth_ecological_traits.csv
