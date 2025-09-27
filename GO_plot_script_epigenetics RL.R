#========================
# GENE ONTOLOGY BARGRAPH SCRIPT
#========================
# Original supplied by Dr Maike Stentenbach

# 11/03/2025
# Will generate bar graphs displaying gene ontology results
# input files must be formatted correctly
# please check required packages are installed otherwise script will not work


#======== USER VARIABLES PLEASE FILL IN:

# put in the path for your working directory, an example is provided
directory <- "H:/Uni thingos/PhD/Epigenetics/RNA/RNA-seq R/GO analysis"

# set your graph gradient colours low and high
col.low <- "#efedf5" # low colour
col.high <- "#756bb1" # high colour

# set top number of hits you want displayed in graph - default is set to 20
num.hits <- 20


#======== PLOTTING SCRIPT - USER DOES NOT NEED TO CHANGE

# set working directory
setwd(directory)

# load required packages
library(ggplot2)
library(dplyr)
library(gtable)
library(ggpubr)
library(cowplot)

# import res files from input.txt
input <- read.table("input.txt", sep="\t", quote="", header=T)
for(i in 1:nrow(input)){
  id <- input[i,2]
  file <- input[i,1]
  
  df <- read.table(paste("input files/",file,sep=""), sep="\t", quote="", header=T)
  
  assign(paste(id), df)
}

# make bar plot ordered by FDR
for(i in 1:nrow(input)){
  id <- input[i,2]
  df <- get(id)
  
  # subset to significant only and GO size >1
  df <- df[df$FDR < 0.05,]
  df <- df[df$GO_size > 1,]
  df$Log2FC <- as.numeric(df$Log2FC)
  
  # log transform FDR and order
  df$nlog10FDR <- -log10(df$FDR)
  df <- df[order(df$nlog10FDR),] # ORDER BY FDR
  df$GO_term <- factor(df$GO_term, levels=unique(df$GO_term))
  df <- tail(df, n=num.hits) # KEEP TOP 20 HITS
  
  # make set size parameter
  df$setsize <- as.character(df$GO_size)
  df$setsize <- make.unique(df$setsize)
  df$setsize <- factor(df$setsize, levels=unique(df$setsize))
  
  # make bar plot
  bar.plot <- df %>% ggplot(aes(x=nlog10FDR, y=GO_term, fill=Log2FC)) +
    geom_col() +
    theme_classic() +
    theme(axis.title.y=element_blank(), legend.position="bottom") +
    labs(x="-log10(FDR)", fill="Enrichment", title=id) +
    scale_fill_gradient(low=col.low, high=col.high)
  
  # make set size axis
  setsize.axis <- df %>% ggplot(aes(y=setsize)) +
    geom_blank() +
    theme_classic() +
    theme(panel.background = element_blank(),
          axis.line.x = element_blank()) +
    scale_y_discrete(position="right") +
    ylab("Set size")
  
  # subset set size axis
  g <- ggplotGrob(setsize.axis)
  axis <- gtable_filter(g, 'axis-r|ylab')
  
  # print plots together and save
  res <- plot_grid(bar.plot, axis, nrow=1, rel_widths=c(9/10,1/10))
  
  pdf(file=paste("plots/",id,"IPF.TGFb1_vs_US.GOplot.pdf",sep=""), height=11, width=8.5, paper="letter")
  print(res)
  dev.off()
}

