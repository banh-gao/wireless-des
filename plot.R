library(ggplot2)
# command line argument, if present, indicates the results folder

args <- commandArgs(trailingOnly = T)
res.folder <- args[1]
num.nodes <- as.numeric(args[2])

# total offered load in bits per second
compute.offered.load <- function(d, num.nodes) {
    ## Convert packet size from bytes to Mbits
    packet.size <- d$sz * 8 / 1024^2
    return(data.frame(lambda=d$lambda , slots=d$slots, ol=d$lambda * num.nodes * packet.size))
}

results <- readRDS(paste(res.folder, "res.rds", sep='/'))
ol <- compute.offered.load(results, num.nodes)
results <- merge(results, ol)

#Convert throughput from bps to Mbps
results$tr <- results$tr * 8 / 1024^2

# and plot the results
div <- 3
ggplot(results, aes(x=ol, y=tr, linetype=factor(slots))) +
    geom_line() +
    xlab('total offered load (Mbps)') +
    ylab('throughput at receiver (Mbps)') +
    labs(color="Number of slots")
ggsave(paste(res.folder, '/thr.pdf', sep=''), width=16/div, height=9/div)

ggplot(results, aes(x=ol, y=cr, linetype=factor(slots))) +
    geom_line() +
    xlab('total offered load (Mbps)') +
    ylab('packet collision rate at receiver') +
    scale_y_sqrt() +
    labs(color="Number of slots")
ggsave(paste(res.folder, '/pcr.pdf', sep=''), width=16/div, height=9/div)

ggplot(results, aes(x=ol, y=dr, linetype=factor(slots))) +
    geom_line() +
    xlab('total offered load (Mbps)') +
    ylab('packet drop rate at sender') +
    labs(color="Number of slots")
ggsave(paste(res.folder, '/pdr.pdf', sep=''), width=16/div, height=9/div)
