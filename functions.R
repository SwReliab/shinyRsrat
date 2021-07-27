library(Rsrat)
library(Rphsrm)
library(gof4srm)

estimate.ordinary <- function(data, models) {
  result <- fit.srm.nhpp(time=data$time, fault=data$fault, type=data$type, srm.names=models, selection=NULL)
  if (length(models) == 1) {
    result <- list(result)
    names(result) <- result[[1]]$srm$name
  }
  result
}

estimate.cph <- function(data, phases) {
  result <- fit.srm.cph(time=data$time, fault=data$fault, type=data$type, phase=phases, selection=NULL)
  if (length(phases) == 1) {
    result <- list(result)
    names(result) <- result[[1]]$srm$name
  }
  result
}

gof <- function(result, eic) {
  ksres <- lapply(result, ks.srm.test)
  if (eic == TRUE) {
    gofres <- lapply(result, eic.srm)
    data.frame(
      name=sapply(result, function(x) x$srm$name),
      llf=sapply(result, function(x) x$llf),
      df=sapply(result, function(x) x$df),
      ks=sapply(ksres, function(x) x$p.value),
      aic=sapply(result, function(x) x$aic),
      eic=sapply(gofres, function(x) x$eic),
      eic.lower=sapply(gofres, function(x) x$eic.lower),
      eic.upper=sapply(gofres, function(x) x$eic.upper)
    )
  } else {
    data.frame(
      name=sapply(result, function(x) x$srm$name),
      llf=sapply(result, function(x) x$llf),
      df=sapply(result, function(x) x$df),
      ks=sapply(ksres, function(x) x$p.value),
      aic=sapply(result, function(x) x$aic)
    )
  }
}

reliab <- function(result) {
  ct <- sum(result[[1]]$srm$data$time)
  data.frame(
    name=sapply(result, function(x) x$srm$name),
    Total=sapply(result, function(x) x$srm$omega()),
    Residual=sapply(result, function(x) x$srm$residual(ct)),
    FFP=sapply(result, function(x) x$srm$ffp(ct)),
    iMTBF=sapply(result, function(x) x$srm$imtbf(ct)),
    cMTBF=sapply(result, function(x) x$srm$cmtbf(ct))
  )
}


