library(ggplot2)
# command line argument, if present, indicates the results folder

args <- commandArgs(trailingOnly = T)
if (length(args) != 0) {
    res.folder <- args[1]
} else {
    res.folder <- './'
}

load("tr.Rdata")
load("cr.Rdata")
load("dr.Rdata")

# and plot the results
div <- 3
p <- ggplot(tr, aes(x=ol, y=tr, linetype=factor(slots))) +
    geom_line() +
        geom_point() +
     xlab('total offered load (Mbps)') +
     ylab('throughput at receiver (Mbps)') +
     labs(color="Number of slots")
ggsave(paste(res.folder, '/thr.pdf', sep=''), width=16/div, height=9/div)
print(p)

pcr <- ggplot(cr, aes(x=ol, y=cr, linetype=factor(slots))) +
    geom_line() +
        geom_point() +
       xlab('total offered load (Mbps)') +
       ylab('packet collision rate at receiver') +
       labs(color="Number of slots") +
       ylim(c(0, 1))
ggsave(paste(res.folder, '/pcr.pdf', sep=''), width=16/div, height=9/div)
print(pcr)

pdr <- ggplot(dr, aes(x=ol, y=dr, linetype=factor(slots))) +
    geom_line() +
    geom_point() +
       xlab('total offered load (Mbps)') +
       ylab('packet drop rate at sender') +
       labs(color="Number of slots") +
       ylim(c(0, 1))
ggsave(paste(res.folder, '/pdr.pdf', sep=''), width=16/div, height=9/div)
print(pdr)
