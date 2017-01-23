library(ggplot2)
# command line argument, if present, indicates the results folder

args <- commandArgs(trailingOnly = T)
res.folder <- args[1]
num.nodes <- as.numeric(args[2])

results <- readRDS(paste(res.folder, "res.rds", sep='/'))

## Calculate total offered load in bits per second
results$ol <- results$lambda * results$sz * num.nodes

# Convert offered load from Bps to Mbps
results$ol <- results$ol * 8 / 1024^2
#Convert throughput from Bps to Mbps
results$th <- results$th * 8 / 1024^2

print(results)

# and plot the results
div <- 3
ggplot(results, aes(x=ol, y=th, linetype=factor(slots))) +
    geom_line() +
    geom_point() +
    xlab('total offered load (Mbps)') +
    ylab('throughput at receiver (Mbps)') +
    labs(color="Number of slots")
ggsave(paste(res.folder, '/thr.pdf', sep=''), width=16/div, height=9/div)

ggplot(results, aes(x=ol, y=cr, linetype=factor(slots))) +
    geom_line() +
    geom_point() +
    xlab('total offered load (Mbps)') +
    ylab('packet collision rate at receiver') +
    scale_y_sqrt() +
    labs(color="Number of slots")
ggsave(paste(res.folder, '/pcr.pdf', sep=''), width=16/div, height=9/div)

ggplot(results, aes(x=ol, y=dr, linetype=factor(slots))) +
    geom_line() +
    geom_point() +
    xlab('total offered load (Mbps)') +
    ylab('packet drop rate at sender') +
    labs(color="Number of slots")
ggsave(paste(res.folder, '/pdr.pdf', sep=''), width=16/div, height=9/div)
