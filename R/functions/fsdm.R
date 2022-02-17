fsdm <- function(species, model, climDat, spData, k, write, outPath, #inters = F, prediction = TRUE,
                 knots_gam = -1){ 
  
  print(species)

    
  #### extract data ####
  pres <- data.frame(val = 1, raster::extract(x = climDat, y = spDat$Presence, na.rm = T), spDat$Presence)
  
  if (any(is.na(pres))) {
    warning("!!!   NAs in presences   !!!")
    # pres <- na.omit(pres)
  }
  
  nRec <- nrow(pres)
  
  print(paste("Occurrence records:", nRec))
  
  ab <- data.frame(val = 0, raster::extract(x = climDat, y = spDat$pseudoAbsence, na.rm = T), spDat$pseudoAbsence)
  
  if (any(is.na(ab))) {
    warning("!!!   NAs in pseudoabsences   !!!")
    # ab <- na.omit(ab)
  }
  
  # get a data frame with the lat-lon coordinates
  allDat <- rbind(pres[!names(pres) %in% c("lon", "lat")], ab[!names(ab) %in% c("lon", "lat")])
  allDat_loc <- rbind(pres, ab)
  
  
  ## determine the weights argument for all models
  if ((model != "lrReg" & model != 'lr' & model != "gam" & model != "rf") & nRec != nrow(ab)) { 
    warning("Prevalence is not 0.5 and no weights are applied to account for this. Currently weights are only applied where model = lrReg, lr, gam or rf")
    if(model == 'me'){
      options(java.parameters = "-Xmx3g")
      warning("Maxent ('me') models work best with equal number of presences and absences, matching the number of presences and absences")
      if(nrow(pres) > nrow(ab)){
        warning("Number of presences > number of absences, reducing number of presences to match absences")
        pres <- pres[sample(x = 1:nrow(pres), size = nrow(ab)),]
        # match the number of absences to presences in the spDat 
        spDat$Presence <- spDat$Presence[sample(x = 1:nrow(spDat$Presence),
                                                size = nrow(spDat$pseudoAbsence)),]
      } else if(nrow(pres) < nrow(ab)){
        warning("Number of abesences > number of presences, reducing number of presences to match absences")
        ab <- ab[sample(x = 1:nrow(ab), size = nrow(pres)),]
        # match the number of absences to presences in the spDat 
        spDat$pseudoAbsence <- spDat$pseudoAbsence[sample(x = 1:nrow(spDat$pseudoAbsence),
                                                          size = nrow(spDat$Presence)),]
      }
      
      # get a data frame with the lat-lon coordinates
      allDat <- rbind(pres[!names(pres) %in% c("lon", "lat")], ab[!names(ab) %in% c("lon", "lat")])
      allDat_loc <- rbind(pres, ab)
      
      
      # match the number of absences to presences in the spDat 
      spDat$pseudoAbsence <- spDat$pseudoAbsence[sample(x = 1:nrow(spDat$pseudoAbsence),
                                                        size = nrow(spDat$Presence)),]
      
      
      
    } else if(model != "lrReg" | model != 'lr' | model != "gam" | model != "rf"){
      stop("Model is not one of lr, lrReg, me, gam or rf. Stopping model run")
    }
  }
  
  if ((model == "lrReg"|model == 'lr'|model == "gam"|model == "rf") & nRec != nrow(ab)) {
    print("Prevalence is not 0.5. Weighting absences to simulate a prevalence of 0.5")
    nAb <- nrow(ab)
    prop <- nRec / nAb
    print(paste("Absence weighting:", prop))
  } else if(model == 'me') {
    prop <- NULL 
  } else { 
    stop('Model specified not accepted by fitSDM (problem with prop calculation)')
  }
  
  
  ###### Move straight to 'bootstrapping' ######
  
  print('######     Bootstrapping    ######')
  
  folds <- c(kfold(pres, k), kfold(ab, k))
  folds_me_pres <- kfold(spDat$Presence, k)
  folds_me_ab <- kfold(spDat$pseudoAbsence, k)
  
  e <- vector('list', length = k)
  mods_out <- vector('list', length = k)
  
  for (i in 1:k) {
    
    # model 
    if (model == 'me') {
      
      train_me_pres <- spDat$Presence[folds_me_pres != i, ]
      train_me_abs <- spDat$pseudoAbsence[folds_me_ab != i, ]
      
      test_me_pres <- spDat$Presence[folds_me_ab == i, ]
      test_me_abs <- spDat$pseudoAbsence[folds_me_ab == i, ]
      
      mod <- maxent(x = climDat, p = data.frame(train_me_pres)[,1:2], 
                    a = data.frame(train_me_abs)[,1:2])
      
      e[[i]] <- dismo::evaluate(p = test_me_pres, 
                                a = test_me_abs, 
                                x = climDat,
                                mod, tr = seq(0, 1, length.out = 200))
      
    }
    
    if(model == 'lr' | model == 'rf' | model == 'gam'){
      
      train <- allDat[folds != i, ]
      
      ## set the weights argument for models
      if ((model == "lrReg"|model == 'lr'|
           model == "gam"|model == "rf") & nRec != nrow(ab)){
        
        weights <- c(rep(1, length(train$val[train$val == 1])), rep(prop, length(train$val[train$val == 0])))
        
      } else if(nRec == nrow(ab)){ weights <- NULL } 
      
      test <- allDat[folds == i, ]
      
      if (model == "lr") {
        mod <- glm(val ~ ., data = train, 
                   family = binomial(link = "logit"),
                   weights = weights)
        
        ## weight the minority class by the ratio of majority/minority.
        ## minority is always the smaller class in my datasets, so give the 
        ## presence values a larger weight that the minorities
        ## round the weights argument to make sure those that are close to equilibrium
        ## aren't affected...?
      }
      else if (model == "rf") {
        
        # if records and absences are matched, run without weights (weights = NULL doesn't work)
        # if they aren't then implement weights argument
        if(nRec == nrow(ab)){
          
          mod <- randomForest(x = train[, 2:ncol(train)], 
                              y = as.factor(train[, 1]), 
                              importance = T, 
                              norm.votes = TRUE)
          
        } else if(nRec != nrow(ab)){
          
          mod <- randomForest(x = train[, 2:ncol(train)], 
                              y = as.factor(train[, 1]), 
                              importance = T, 
                              norm.votes = TRUE,
                              classwt = list(unique(weights)[1],
                                             unique(weights)[2])) ## must be list(presences, absences)
        }
        
      }
      else if (model == "gam"){
        
        ## create formula for gam
        l <- sapply(allDat, unique)
        ks <- rownames_to_column(data.frame(k = round(sapply(l, length))[-1]),
                                 var = "variable")
        
        
        # drop variables according to number of knots asked for
        # -1 is basically 9 knots
        if(knots_gam == -1) {
          v_keep <- ks[ks$k > 11,]
          
          print(paste("variable dropped =", ks$variable[!ks$variable %in% v_keep$variable]))
        }
        
        # any others just keep the variables with over the number of knots
        if(knots_gam > 0) {
          v_keep <- ks[ks$k > (knots_gam+3),]
          print(paste("variable dropped =", ks$variable[!ks$variable %in% v_keep$variable]))
        }
        # v_keep
        
        form <- as.formula(paste0("val ~ s(", paste(v_keep$variable,
                                                    ", k = ", knots_gam) %>% #,
                                    # v_keep$knts) %>%
                                    paste0(collapse = ") + s("), ")"))
        # form
        
        
        mod <- gam(formula = form, data = train, 
                   family = binomial(link = 'logit'), 
                   select = TRUE, method = 'REML', gamma = 1.4,
                   weights = weights)
      }
      
      # model evaluation - for random forest models, need to predict first
      if(model == "rf"){
        rf.pred <- predict(mod, type = "prob", newdata = test)[,2]
        e[[i]] <- dismo::evaluate(p = rf.pred[test$val == 1], 
                                  a = rf.pred[test$val == 0], 
                                  tr = seq(0, 1, length.out = 200))
        
      } else {
        e[[i]] <- dismo::evaluate(p = test[test$val == 1, ], 
                                  a = test[test$val == 0, ], 
                                  mod, tr = seq(0, 1, length.out = 200))
      }
      
      
    }
    
    ## now implement lasso regression
    if(model == "lrReg"){
      
      train <- allDat[folds != i, ]
      
      ## set the weights argument for models
      if (model == "lrReg" & nRec != nrow(ab)) weights <- c(rep(1, length(train$val[train$val == 1])), rep(prop, length(train$val[train$val == 0])))
      
      test <- allDat[folds == i, ]
      
      ## test weights for the testing data 
      if (model == "lrReg" & nRec != nrow(ab)) testweights <- c(rep(1, length(test$val[test$val == 1])), rep(prop, length(test$val[test$val == 0])))
      
      
      mod <- glmnet::cv.glmnet(x = as.matrix(train[, 2:ncol(train)]),
                               y = train[, 1],
                               family = "binomial",
                               nfolds = 3,
                               weights = weights)
      
      # evaluate model on the testing data
      eval <- assess.glmnet(mod, newx = as.matrix(test[,2:ncol(test)]), newy = test[,1], weights = testweights)
      roc <- roc.glmnet(mod, newx = as.matrix(test[,2:ncol(test)]), newy = test[,1], weights = testweights)
      
      e[[i]] <- list(eval, roc)
      
      names(e[[i]]) <- c('evaluation', 'roc')
      
    }
    
    # store all the bootstrapped models
    mods_out[[i]] <- mod
    
  }
  
  ## get the auc from each run of the bootstrapping
  if(model != 'lrReg'){
    
    auc_val <- sapply(e, function(x) {
      slot(x, "auc")
    })
    
  } else if(model == 'lrReg'){
    
    auc_val <- sapply(c(1:k), function(x) e[[x]]$evaluation$auc)
    
  }
  
  
  ## get the mean AUC across all models
  meanAUC <- mean(auc_val)
  

  
  out <- NULL
  out <- list(species, nRec,
              auc_val, meanAUC, k, 
              allDat_loc, ## taken out to see if it reduces file sizes
              e, mods_out)
  names(out) <- c("Species", "Number of records", 
                  "AUC", "meanAUC", "Number of folds for validation",
                  "Data",
                  "Model_evaluation", "Bootstrapped_models")
  
  if (write == TRUE) {
    print(species)
    save(out, file = paste0(outPath, species, "_", model, 
                            ".rdata"))
  }
  return(out)
}