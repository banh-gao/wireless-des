library(plyr)
library(doMC)
registerDoMC(cores=detectCores())

# command line argument, if present, indicates the results folder
args <- commandArgs(trailingOnly = T)
if (length(args) != 0) {
    res.folder <- args[1]
} else {
    res.folder <- './'
}

# possible packet states
PKT_RECEIVING = 0
PKT_RECEIVED = 1
PKT_CORRUPTED = 2
PKT_GENERATED = 3
PKT_QUEUE_DROPPED = 4

# computes the offered load
compute.offered.load <- function(d, data.rate, sim.time) {
    # keep generation events only
    d <- subset(d, event == PKT_GENERATED)
    offered.load <- ddply(d, c("src", "lambda", "slots"), function(x) {
        return(data.frame(ol=(sum(x$size * 8) / sim.time) / (1024**2)))
    }, .parallel=T)
    return(offered.load)
}

# computes the queue drop rate: dropped packets / generated packets
compute.drop.rate <- function(d, group=F) {
    fields <- c('lambda', 'slots')
    if (!group)
        fields <- c('src', fields)
    drop.rate <- ddply(d, fields, function(x) {
        all.packets <- subset(x, event == PKT_GENERATED)
        lost.packets <- subset(x, event == PKT_QUEUE_DROPPED)
        return(data.frame(dr=nrow(lost.packets)/nrow(all.packets)))
    }, .parallel=T)
    return(drop.rate)
}

# computes collision rate: corrupter / (received + corrupted)
compute.collision.rate <- function(d, group=F) {
    fields <- c('lambda', 'slots')
    if (!group)
        fields <- c('dst', fields)
    collision.rate <- ddply(d, fields, function(x) {
        all.packets <- subset(x, event == PKT_RECEIVED | event == PKT_CORRUPTED)
        lost.packets <- subset(all.packets, event == PKT_CORRUPTED)
        return(data.frame(cr=nrow(lost.packets)/nrow(all.packets)))
    }, .parallel=T)
    return(collision.rate)
}

# compute throughput: total bits received / simulation time
compute.throughput <- function(d, data.rate, sim.time, group=F) {
    fields <- c('lambda', 'slots')
    if (!group)
        fields <- c('dst', fields)
    throughput <- ddply(d, fields, function(x) {
        received.packets <- subset(x, event == PKT_RECEIVED)
        return(data.frame(tr=sum(received.packets$size*8)/sim.time/(1024**2)))
    }, .parallel=T)
    return(throughput)
}

# total offered load in bits per second
offered.load <- function(lambda, n.nodes, packet.size=(1460+32)/2) {
    lambda*n.nodes*packet.size*8/1024/1024
}

aggregated.file <- paste(res.folder, 'alld.Rdata', sep='/')

load(aggregated.file)

# get simulation time and number of nodes from the simulation data
sim.time <- max(alld$time)
n.nodes <- length(unique(alld$src))

# compute the statistics
cr <- compute.collision.rate(alld, group=T)
cr$ol <- offered.load(cr$lambda, n.nodes=n.nodes)
save(cr, file="cr.Rdata")

dr <- compute.drop.rate(alld, group=T)
dr$ol <- offered.load(dr$lambda, n.nodes=n.nodes)
save(dr, file="dr.Rdata")

tr <- compute.throughput(alld, 8e6, sim.time, group=T)
tr$ol <- offered.load(tr$lambda, n.nodes=n.nodes)
save(tr, file="tr.Rdata")
