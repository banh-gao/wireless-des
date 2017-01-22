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

DATA_RATE <- 8e6

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
    printf("Computing collision rate...")
    fields <- c('dst', 'lambda', 'slots')
    collision.rate <- ddply(d, fields, function(x) {
        all.packets <- subset(x, event == PKT_RECEIVED | event == PKT_CORRUPTED)
        lost.packets <- subset(all.packets, event == PKT_CORRUPTED)
        return(data.frame(cr=nrow(lost.packets)/nrow(all.packets)))
    }, .parallel=T)
    collision.rate$dst <- NULL
    return(collision.rate)
}

# computes the queue drop rate: dropped packets / generated packets
compute.drop.rate <- function(d) {
    printf("Computing drop rate...")
    fields <- c('src','lambda', 'slots')
    drop.rate <- ddply(d, fields, function(x) {
        all.packets <- subset(x, event == PKT_GENERATED)
        lost.packets <- subset(x, event == PKT_QUEUE_DROPPED)
        return(data.frame(dr=nrow(lost.packets)/nrow(all.packets)))
    }, .parallel=T)
    drop.rate$src <- NULL
    return(drop.rate)
}

# compute throughput: total bits received / simulation time
compute.throughput <- function(d) {
    printf("Computing throughput...")
    fields <- c('dst', 'lambda', 'slots')
    sim.time <- max(d$time)
    throughput <- ddply(d, fields, function(x) {
        received.packets <- subset(x, event == PKT_RECEIVED)
        return(data.frame(tr=sum(received.packets$size*8)/sim.time/(1024**2)))
    }, .parallel=T)
    throughput$dst <- NULL
    return(throughput)
}

# total offered load in bits per second
compute.offered.load <- function(d, packet.size=(1460+32)/2) {
    printf("Computing offered load...")
    lambda <- unique(d$lambda)
    nodes <- length(unique(data$src))
    return(data.frame(lambda=d$lambda , slots=d$slots, ol=lambda*nodes*packet.size*8/1024/1024))
}

save.results <- function(res, type, pars, out.folder) {
    filename <- paste(pars, collapse='_')
    filename <- sprintf("%s_%s.rds", type, filename)
    out.path <- paste(out.folder, filename , sep='/')
    printf("Saving results in %s ...", out.path)
    saveRDS(res, file=out.path)
}

## load simulation data with params
data <- load.data(data.file)
pars <- get.params(data.file)
data <- cbind(data, pars)

# compute the statistics
ol <- compute.offered.load(data)
save.results(ol, 'ol', pars, out.folder)
rm(ol)

cr <- compute.collision.rate(data)
save.results(cr, 'cr', pars, out.folder)
rm(cr)

dr <- compute.drop.rate(data)
save.results(dr, 'dr', pars, out.folder)
rm(dr)

tr <- compute.throughput(data)
save.results(tr, 'tr', pars, out.folder)
rm(tr)
