library(ggplot2)
# command line argument, if present, indicates the results folder

args <- commandArgs(trailingOnly = T)
res.folder <- args[1]
results <- readRDS(paste(res.folder, "res.rds", sep='/'))

## Calculate total offered load in bits per second
results$ol <- results$lambda * results$sz * results$nodes

# Convert offered load from Bps to Mbps
results$ol <- results$ol * 8 / 1024^2
#Convert throughput from Bps to Mbps
results$th <- results$th * 8 / 1024^2 / results$nodes
results$slots <- factor(results$slots)

plot.by.nodes <- function(data, n) {
    res.by.node <- subset(data, nodes == n)
    div <- 3
    
    ggplot(res.by.node, aes(x=ol, y=th, linetype=slots, color=slots)) +
        geom_line(size=0.3) +
        geom_point(size=0.5) +
        scale_linetype_manual(name="Number of Slots", values = c(1,5,3,6)) +
        scale_color_brewer(name="Number of Slots", type="div") +
        xlab('total offered load (Mbps)') +
        ylab('throughput at receiver (Mbps)') +
    ggsave(paste(res.folder, sprintf('/thr_%i.pdf', n), sep=''), width=16/div, height=9/div)

    ggplot(results, aes(x=ol, y=cr, linetype=slots, color=slots)) +
        geom_line(size=0.3) +
        geom_point(size=0.5) +
        scale_linetype_manual(name="Number of Slots", values = c(1,5,3,6)) +
        scale_color_brewer(name="Number of Slots", type="div") +
        xlab('total offered load (Mbps)') +
        ylab('packet collision rate at receiver')
    ggsave(paste(res.folder, sprintf('/pcr_%i.pdf', n[1]), sep=''), width=16/div, height=9/div)
}

Map(plot.by.nodes, list(results), as.list(unique(results$nodes)))
