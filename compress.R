# command line argument, if present, indicates the results folder
args <- commandArgs(trailingOnly = T)
if (length(args) != 0) {
    res.folder <- args[1]
} else {
    res.folder <- './'
}

# determine whether a string contains a parsable number"
is.number <- function(string) {
    if (length(grep("^[[:digit:]]*$", string)) == 1)
        return (T)
    else
        return (F)
}

# gets the list of files with a certain prefix and suffix in a folder
get.data.files <- function(folder, suffix=".csv") {
    if (strsplit(suffix, '')[[1]][1] == '.')
        suffix <- paste('\\', suffix, sep='')
    return(list.files(folder, pattern=paste('.*', suffix, sep='')))
}

# splits the name of an output file by _ and extracts the values of simulation parameters
get.params <- function(filename, fields) {
    p <- strsplit(gsub(".csv", "", basename(filename)), "_")[[1]]
    #to add a column, we need to have something in the dataframe, so we add a
    #fake column which we remove at the end
    d <- data.frame(todelete=1)
    for (f in 1:length(fields)) {
        v <- p[f]
        if (is.number(v))
            d[[fields[[f]]]] <- as.numeric(v)
        else
            d[[fields[[f]]]] <- v
    }
    d$todelete <- NULL
    return (d)
}

## load all csv files into a single one
aggregated.file <- paste(res.folder, 'alld.Rdata', sep='/')

alld <- data.frame()

## find all csv in current folder
data.files <- get.data.files(res.folder, '.csv')
for (f in data.files) {
    full.path <- paste(res.folder, f, sep='/')
    print(full.path)
    pars <- get.params(full.path, c('prefix', 'lambda', 'seed'))
    d <- read.csv(full.path)
    d <- cbind(d, pars)
    alld <- rbind(d, alld)
}
save(alld, file=aggregated.file)
