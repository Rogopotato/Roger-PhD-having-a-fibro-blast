#README
#Script was originally supplied by Dr Maike Stentenbach and was aimed at generating volcano plots of RNA analysis
#More detailed instructions for workflow are accompanying
#Modifications made by Roger Li for his PhD
#Last updated: 27/09/2025

# load libraries
library(ggplot2)
library(dplyr)
library(ggpubr)
library(ggrepel)

# setwd
setwd("H:/Uni thingos/PhD/Epigenetics/RNA/RNA-seq R/Volcano plots")

# Read in df and format
files <- list.files(pattern = "IPF_vs_NDC.US.Nin.txt")
files <- gsub("IPF_vs_NDC.US.Nin.txt", "", files)

for (i in 1:length(files)) {
  name <- files[[i]]
  df <- read.table(paste(name, "IPF_vs_NDC.US.Nin.txt", sep = ""),
                   sep = "\t", header = TRUE, quote = "", na.strings = "")
  
  # Make log10 adjustment and change gene names
  df$log10P <- -log(df$adj.P.Val, 10)
  df$GeneSymbol <- toupper(df$hgnc_symbol)
  
  # Make shapes (triangles for extreme log2FC values, circles for others)
  df$shape <- ifelse(abs(df$log2_FC) >= 15, "triangle", "circle")
  df$log2_FC[df$log2_FC > 15] <- 15
  df$log2_FC[df$log2_FC < -15] <- -15
  
  # Split into left and right based on Log2FC
  df.left <- df[df$log2_FC < 0, ]  # Negative Log2FC (left side)
  df.right <- df[df$log2_FC > 0, ]  # Positive Log2FC (right side)
  
  # Label top 20 on the left
  df.left$absLFC <- abs(df.left$log2_FC)
  df.left <- df.left[!is.na(df.left$hgnc_symbol) & df.left$adj.P.Val < 0.05, ]
  df.left <- df.left[order(-df.left$absLFC), ]
  df.left$label <- NA
  df.left$label[1:10] <- "True"
  
  # Label top 20 on the right
  df.right$absLFC <- abs(df.right$log2_FC)
  df.right <- df.right[!is.na(df.right$hgnc_symbol) & df.right$adj.P.Val < 0.05, ]
  df.right <- df.right[order(-df.right$absLFC), ]
  df.right$label <- NA
  df.right$label[1:10] <- "True"
  
  # Combine left and right data
  df <- rbind(df.left, df.right)
  
  # Make the plot
  p <- ggplot() +
    geom_point(data = df, aes(x = log2_FC, y = log10P, shape = shape), colour = "light grey") +
    geom_point(data = subset(df, df$adj.P.Val < 0.05 & df$log2_FC > 1.5),
               aes(x = log2_FC, y = log10P, shape = shape), colour = "#ed9a9a") +
    geom_point(data = subset(df, df$adj.P.Val < 0.05 & df$log2_FC < -1.5),
               aes(x = log2_FC, y = log10P, shape = shape), colour = "#a1aded") +
    geom_text_repel(data = subset(df, df$label == "True"), 
                    aes(x = log2_FC, y = log10P, label = GeneSymbol), 
                    box.padding = 0.25, max.overlaps = Inf) +
    theme_classic() +
    geom_hline(yintercept = 1.301, colour = "dark grey") +
    geom_vline(xintercept = c(1.5, -1.5), colour = "dark grey") +
    guides(shape = "none") +
    xlim(-6, 6) +
    xlab("Log2(FC)") + ylab("-log10(Adjusted p-value)") + ggtitle(name)
  
  # Assign the plot
  assign(paste(name, ".p", sep = ""), p)
  
}

# Create a list of all the plot objects dynamically using get
plots_list <- lapply(files, function(name) get(paste(name, ".p", sep="")))

# Now arrange the plots
p.all <- ggarrange(plotlist = plots_list, ncol = 2, nrow = 3)
ggsave("IPF_vs_NDC.US.Nin.pdf", plot = p.all, device = "pdf", height = 8, width = 6, scale = 2)

rm(p)
rm(p.all)
rm(plots_list)
rm(df)
rm(df.left)
rm(df.right)
