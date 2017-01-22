library(foreach)
library(iterators)
library(parallel)
library(data.table)
library(plyr)

# command line argument, if present, indicates the results folder
args <- commandArgs(trailingOnly = T)
res.folder <- args[1]
out.folder <- args[2]

printf <- function(...) invisible(print(sprintf(...)))

# gets the list of files with a certain prefix and suffix in a folder
get.data.files <- function(folder, prefix, suffix='\\.rds') {
    return(list.files(folder, pattern=paste(prefix, '.*', suffix, sep=''), full.names=TRUE))
}

load.files <- function(file.list) {
    ldply(file.list, function(file) {
        readRDS(file)
    })
}

interpolate <- function(var) {
    data.files <- get.data.files(res.folder, var)
    printf("Loading %s data for %d simulations ...", var, length(data.files))
    data.f <- load.files(data.files)
    printf("Interpolating %s data ...", var)
    i <- aggregate(data.f, by=list(f1=data.f$lambda, f2=data.f$slots), mean)
    i$f1 <- NULL
    i$f2 <- NULL
    i
}

## Map simulations variables results to single values by interpolation
vars <- c('ol', 'cr', 'dr', 'tr')
res.by.var <- Map(interpolate, vars)

## Reduce results by merging different measures using common columns
res <- Reduce(merge, res.by.var)

out.file=paste(out.folder, "res.rds", sep='/')
printf("Saving aggregated file ...")
saveRDS(res, file=out.file)
printf("Results saved in %s", out.file)
