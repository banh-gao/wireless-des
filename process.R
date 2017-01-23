library(foreach)
library(iterators)
library(parallel)
library(data.table)
library(plyr)
library(doMC)
registerDoMC(cores=detectCores())

# possible packet states
PKT_RECEIVING = 0
PKT_RECEIVED = 1
PKT_CORRUPTED = 2
PKT_GENERATED = 3
PKT_QUEUE_DROPPED = 4

# command line argument, if present, indicates the results folder
args <- commandArgs(trailingOnly = T)
data.file <- args[1]
out.folder <- args[2]

PARAMS <- c('lambda', 'seed', 'slots')

printf <- function(...) invisible(print(sprintf(...)))

# determine whether a string contains a parsable number"
is.number <- function(string) {
    if (length(grep("^[[:digit:]]*$", string)) == 1)
        return (T)
    else
        return (F)
}

# splits the name of an output file by _ and extracts the values of simulation parameters
get.params <- function(filename) {
    p <- strsplit(gsub(".csv", "", basename(filename)), "_")[[1]]
    #to add a column, we need to have something in the dataframe, so we add a
    #fake column which we remove at the end
    d <- data.frame(todelete=1)
    for (f in 1:length(PARAMS)) {
        v <- p[f]
        if (is.number(v))
            d[[PARAMS[[f]]]] <- as.numeric(v)
        else
            d[[PARAMS[[f]]]] <- v
    }
    d$todelete <- NULL
    return (d)
}

load.data <- function(data.file) {
    printf("Loading simulation data %s...", data.file)
    fread(input = data.file, sep=",")
}

# computes collision rate: corrupted / (received + corrupted)
compute.collision.rate <- function(d) {
    all.packets <- subset(d, event == PKT_RECEIVED | event == PKT_CORRUPTED)
    lost.packets <- subset(all.packets, event == PKT_CORRUPTED)
    return(data.frame(cr=nrow(lost.packets)/nrow(all.packets)))
}

# computes the queue drop rate: dropped packets / generated packets
compute.drop.rate <- function(d) {
    printf("Computing drop rate...")
    all.packets <- subset(d, event == PKT_GENERATED)
    lost.packets <- subset(d, event == PKT_QUEUE_DROPPED)
    return(data.frame(dr=nrow(lost.packets)/nrow(all.packets)))
}

# compute throughput(bytes/sec): received bytes / simulation time
compute.throughput <- function(d) {
    printf("Computing throughput...")
    sim.time <- max(d$time)
    received.packets <- subset(d, event == PKT_RECEIVED)
    return(data.frame(th=sum(received.packets$size)/sim.time))
}

compute.packet.size <- function(d) {
    printf("Computing transmitted packets size...")
    all.packets <- subset(d, event == PKT_RECEIVED | event == PKT_CORRUPTED)
    return(data.frame(sz=mean(all.packets$size)))
}

calc.stats <- function(data, var) {
    if(var == 'dr') {
        return(compute.drop.rate(data))
    } else if (var == 'cr') {
        return(compute.collision.rate(data))
    } else if (var == 'th') {
        return(compute.throughput(data))
    } else if (var == 'sz') {
        return(compute.packet.size(data))
    }
}

save.results <- function(res, pars, out.folder) {
    filename <- paste(pars, collapse='_')
    filename <- sprintf("stats_%s.rds", filename)
    out.path <- paste(out.folder, filename , sep='/')
    printf("Saving stats in %s ...", out.path)

    # Save params as columns
    res <- cbind(pars, res)

    saveRDS(res, file=out.path)
}

## load simulation data
data <- load.data(data.file)

## Calculate statistics for each var separately
vars <- c('cr', 'dr', 'th', 'sz')
stat.by.var <- Map(calc.stats, list(data), vars)
print(stat.by.var)

## Merge vars is a single result file per simulation
res <- Reduce(merge, stat.by.var)

pars <- get.params(data.file)
save.results(res, pars, out.folder)
