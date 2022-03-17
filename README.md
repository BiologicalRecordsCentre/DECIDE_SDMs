
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
of code:
<https://github.com/BiologicalRecordsCentre/DECIDE-dynamic-dataflow>

## Workflow

### Preparing data

Currently data processing is not done here, all using outputs from
previous repository `DECIDE_WP1`.

### 1. Generating psudeo absences

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

-   `data/derived_data/species/pas.RDS` - the pseudoabsences
-   `data/derived_data/species/species_list.RDS` - a list of species and
    their ‘group’ (butterfly, day-flying or night flying moth)
-   `data/derived_data/species/pas_meta_data.RDS` - some meta data about
    the psuedoabsences, how many are generated for each species etc.

### 2. Fitting SDMs and making SDM predictions

This script is the workhorse of the workflow. Here we take the
pseudoabsences and presences dervied from the previous script, alongside
the environmental data in the environmental raster and fit a variety of
models. We then predict across the entire GB raster to get each model’s
predictions of species’ probability of presence. We don’t do any
combining across models - that’s in the next script. The script is set
up in an R markdown document which can be run interactively for testing
model types. For running the models for real on the JASMIN LOTUS slurm
cluster, the jobs are set off using the slurm job submission script,
which basically just calls the render function to the R markdown.

Interactive workflow: `R/scripts/2_run_SDMs.Rmd`

Slurm job submission: `R/scripts/2_submit.R`

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

The script also generates a HTML document of the render R Markdown with
all the diagnositic plots etc. There are rendered in github friendly
markdown format so they can be viewed easily in a web browser through
the GitHub website. These documents are saved in the `docs/models`
folder.

#### Submitting the `submit.R` jobs

Log in using

    ssh -A simrol@login1.jasmin.ac.uk
    ssh -A simrol@sci<number>.jasmin.ac.uk

Load the jaspy environment (or a particular version eg. in the second
line below). Don’t need to do this if running the sbatch script
generated by `rslurm` because loading jaspy is in the .sh template.

    module add jaspy
    module add jaspy/3.7/r20200606

If `submit=F` in `2_submit.R` then you can submit it manually by
navigating into the slurm documentary with `cd` command (probably
something like `_rslurm_28dc622537d`) then this command to kick it off
with:

    sbatch submit.sh

sbatch useful commands:

    squeue -u simrol
    top -u simrol

### 3. Combining models for each species to produce ensemble model

This is a realatively simple script which takes all the SDMs for each
model type for each species and combines to make a single SDM ensemble
prediction for each species (not combining across species yet). The
different model types are weighted by AUC.

`R/scripts/3_combine_SDMs.Rmd`

Inputs:

-   `data/derived_data/model_outputs_by_species`

Outputs

-   `data/derived_data/model_outputs_by_species/ensemble`

### 4. Combining to seasonal and all-time DECIDE score model uncertainty component

This script combines the ensemble SDMs for each species. This can be run
on datalabs, at least for butterflies. It has not been tested for the
many nocturnal moth species - that may take a while. This script is
written using the `terra` R package so make use of the efficiency
upgrates it has over `raster`.

Inputs

-   `data/derived_data/model_outputs_by_species/ensemble`

Outputs

-   `data/derived_data/combined_model_outputs`

### Transfer of data

This is where our journey in this repository as the data is handed over
to other file locations for use in other services.

#### Transfer to object store

Outputs from script 3, all individual models and ensemble models by
species, are stored on the JASMIN Object Store
(<https://help.jasmin.ac.uk/article/4847-using-the-jasmin-object-store>).
These are stored here for permanency alongside a variety of other SDMs
produced by UKCEH/BRC. The Object Store can be accessed via DataLabs
which make it easy to explore. See the note at the bottom of
<https://github.com/TMondain/DECIDE_WP1> about transfer to Object Store.

#### Transfer to appdev SAN folder

The seasonal species richness and SDM model uncertainty are transferred
to the SAN app drive. This is for use in the app and to provide the
model uncertainty component for the DECIDE recording priority layer.
These files are then processed by scripts running on RStudio connect
which are being developped here:
<https://github.com/BiologicalRecordsCentre/DECIDE-dynamic-dataflow>

### Exploring data

A basic shiny app for exploring the SDM outputs (located on the Object
Store) is available on DataLabs:
<https://datalab.datalabs.ceh.ac.uk/resource/dwptwo/sdmexplorer/>

## File structure

Generated with `fs::dir_tree()`

### R

    ## R
    ## +-- functions
    ## |   +-- cpa.R
    ## |   \-- fsdm.R
    ## \-- scripts
    ##     +-- 1_pseudoabsence_generation.Rmd
    ##     +-- 2_run_SDMs.Rmd
    ##     +-- 2_submit.R
    ##     +-- 3_combine_SDMs.Rmd
    ##     +-- 4_produce_outputs.Rmd
    ##     \-- sh_template.sh

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
    ## |   |   |   +-- bootstrapped_sd_pieris_brassicae.grd
    ## |   |   |   +-- bootstrapped_sd_pieris_brassicae.gri
    ## |   |   |   +-- mean_prediction_pieris_brassicae.grd
    ## |   |   |   \-- mean_prediction_pieris_brassicae.gri
    ## |   |   +-- gam
    ## |   |   +-- glm
    ## |   |   |   +-- bootstrapped_sd_pieris_brassicae.grd
    ## |   |   |   +-- bootstrapped_sd_pieris_brassicae.gri
    ## |   |   |   +-- mean_AUC_pieris_brassicae.rds
    ## |   |   |   +-- mean_prediction_pieris_brassicae.grd
    ## |   |   |   +-- mean_prediction_pieris_brassicae.gri
    ## |   |   |   \-- models_pieris_brassicae.rds
    ## |   |   +-- maxent
    ## |   |   \-- rf
    ## |   \-- species
    ## |       +-- butterfly
    ## |       |   \-- records
    ## |       |       \-- butterfly_EastNorths_no_duplicates_2021_12_06.csv
    ## |       +-- day_flying_moth
    ## |       |   \-- records
    ## |       |       \-- DayFlyingMoths_EastNorths_no_duplicates.csv
    ## |       +-- pas.RDS
    ## |       +-- pas_meta_data.RDS
    ## |       +-- phenology.RDS
    ## |       \-- species_list.RDS
    ## \-- raw_data
    ##     +-- species
    ##     |   +-- butterfly
    ##     |   \-- day_flying_moth
    ##     \-- traits
    ##         \-- butterfly_moth_ecological_traits.csv
