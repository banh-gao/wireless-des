library(ggplot2)
# command line argument, if present, indicates the results folder

args <- commandArgs(trailingOnly = T)
res.folder <- args[1]
results <- readRDS(paste(res.folder, "res.rds", sep='/'))

## Calculate total offered load in bits per second
results$ol <- results$lambda * results$sz * results$nodes

## Calculate throughput per single receiver node
results$th <- results$th / results$nodes

# Convert offered load from Bps to Mbps
results$ol <- results$ol * 8 / 1024^2
#Convert throughput from Bps to Mbps
results$th <- results$th * 8 / 1024^2
results$slots <- factor(results$slots)

plot.by.nodes <- function(data, n) {
    res.by.node <- subset(data, nodes == n)
    div <- 3
    
    ggplot(res.by.node, aes(x=ol, y=th, linetype=slots, color=slots)) +
        geom_line(size=0.5) +
        geom_point(size=0.7) +
        scale_linetype_manual(name="Window Size", values = c(1,5,3)) +
        scale_color_brewer(name="Window Size", palette = "Set1") +
        xlab('total offered load (Mbps)') +
        ylab('throughput at receiver (Mbps)') +
        xlim(0, 50)
    ggsave(paste(res.folder, 'thr.pdf', sep='/'), width=16/div, height=9/div)

    ggplot(results, aes(x=ol, y=cr, linetype=slots, color=slots)) +
        geom_line(size=0.5) +
        geom_point(size=0.7) +
        scale_linetype_manual(name="Window Size", values = c(1,5,3)) +
        scale_color_brewer(name="Window Size", palette = "Set1") +
        xlab('total offered load (Mbps)') +
        ylab('packet collision rate')
    ggsave(paste(res.folder, 'pcr.pdf', sep='/'), width=16/div, height=9/div)

    ggplot(results, aes(x=ol, y=dr, linetype=slots, color=slots)) +
        geom_line(size=0.5) +
        geom_point(size=0.7) +
        scale_linetype_manual(name="Window Size", values = c(1,5,3)) +
        scale_color_brewer(name="Window Size", palette = "Set1") +
        xlab('total offered load (Mbps)') +
        ylab('packet delivery rate') +
        xlim(0, 50)
    ggsave(paste(res.folder, 'pdr.pdf', sep='/'), width=16/div, height=9/div)
}

Map(plot.by.nodes, list(results), as.list(unique(results$nodes)))
