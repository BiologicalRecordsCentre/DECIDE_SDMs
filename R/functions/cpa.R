#spdat
#species
#nAbs
#matchPres = match the number of presences
#recThresh
#replace = sample with replacement?

cpa <- function (spdat, species,nAbs, matchPres = FALSE,recThresh = 0, replace = F,incPres=F) {
  print(paste0("Generating ",nAbs," pseudo absences for ",species))
  
  #filter data by year and species
  dat <- spdat
  pres <- dat[dat$species == species, c("lon", "lat")]
  print(paste0(nrow(pres)," presence records of target species at ",nrow(unique(pres))," unique locations"))
  #pres$target_sp <- T
  
  #check that the number of presence records reaches the required threshold specified by recThresh
  if (nrow(pres) < recThresh) {
    warning("Number of records does not exceed recThresh")
    out <- NULL
    return(out)
  }

  # select all records from other species
  pres_other_species <- dat[dat$species != species, c("lon", "lat")]
  #pres_other_species$target_sp <- F
  print(paste0(nrow(pres_other_species)," presence records of other species at ",nrow(unique(pres_other_species))," unique locations"))
  
  # get coordinates without target species presence
  pres_other_species <- setdiff(pres_other_species,pres)
  
  # old very slow code
  #pres_other_species <- pres_other_species[pres_other_species %!in% pres]
  print(paste0(nrow(pres_other_species)," possible locations for pseudoabsences"))

  # provide a warning
  if (nrow(pres_other_species) < nrow(pres)) {
    warning(paste0("For ",species,", more presences than possible locations for absences. Consider lowering the number of pseudo absences."))
  }
  
  #if there are more precences than defined nAbs (eg. 10k), and matchPres ==T
  # then set nAbs to the number of presences
  # however if the number of possible locations is smaller than the number of presences then 
  if (matchPres == TRUE){
    nAbs <- max(nAbs,nrow(pres))
    nAbs <- min(nAbs,nrow(pres_other_species))
  }
  
  #sample of the row numbers
  sampInd <- sample(1:nrow(pres_other_species), nAbs, replace = replace)

  #create the absences by selecting the rows numbers that we sampled
  abs <- pres_other_species[sampInd, ]

  abs$presence = F
  abs$scientific_name <- species

  out <- list(pres, abs)
  names(out) <- c("Presence", "pseudoAbsence")
  
  return(out)
}

