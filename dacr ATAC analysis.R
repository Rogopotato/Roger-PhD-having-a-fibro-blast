#README
#Original script was provided by INSiGENe by Dr Denise Anderson and Dr Anya Jones for analysis of differential chromatin accessibility
#Intends to do some quality control, data visualisation and outputs CSVs of DACRs that show fold change and adjusted p value
#This script was used for analysis of TGF-b1 and nintedanib treatment of lung fibroblasts
#Modifications made by Roger Li for his PhD
#Last updated: 27/09/2025

library(lubridate)
library(kableExtra)
library(DiffBind)
library(ggplot2)
library(gplots)
library(TxDb.Hsapiens.UCSC.hg38.knownGene)
library(ChIPseeker)
library(ggrepel)
library(edgeR)

#ATAC sample names, stimulation, treatment, lanes etc. information
sample_prep <- read.csv("C:/Users/21955968/OneDrive - The University of Western Australia/Epigenetics/ATAC-seq/ATAC R stuff/Manuscript data/IPF epigenetics by sample ATAC_TGFb1+Nin.csv")

sample_prep$Date_of_experiment <- dmy(sample_prep$Date.of.experiment)
sample_prep$Group <- paste(sample_prep$Cell.line, sample_prep$Treatment.condition, sep = "_")

#ATAC pooling information
sample_pooling <- read.csv("C:/Users/21955968/OneDrive - The University of Western Australia/Epigenetics/ATAC-seq/ATAC R stuff/Manuscript data/NGS_Library_Pool_ATAC-seq_TGFb1+Nin.csv")
sample_pooling$Sample <- sample_pooling$Sample.Name
#correct erroneous sample names
sample_pooling$Sample[sample_pooling$Sample == "ALF28D_UT_Nin_2_83"] <- "ALF28D_US_Nin_2_83"
sample_pooling$ID <- gsub("^(.*?)_.*", "\\1", sample_pooling$Sample)
sample_pooling$Treatment <- gsub("^[^_]*_([^_]*_[^_]*)_.*$", "\\1", sample_pooling$Sample)
sample_pooling$Number <- gsub(".*_(.*)", "\\1", sample_pooling$Sample)

#read in demographic information
demographics <- read.csv("C:/Users/21955968/OneDrive - The University of Western Australia/Epigenetics/ATAC-seq/ATAC R stuff/Manuscript data/demographics.csv")
demographics$Cell_line_type <- c(rep("Primary", 6), rep("Commercial", 6))

kable(demographics)

kable(table(sample_prep$Date.of.experiment, sample_prep$Cell.line))

sample_prep <- sample_prep[!is.na(sample_prep$Lane),]

kable(table(sample_prep$Lane, sample_prep$Cell.line), row.names = TRUE)

#build a new sample table
sample_sheet <- sample_prep[, c("Cell.line", "Treatment.condition")]
#rename some of the samples to be more accurate
sample_sheet$Cell.line[sample_sheet$Cell.line == "C7231"] <- "CC7231"
sample_sheet$Cell.line[sample_sheet$Cell.line == "CCD13"] <- "CCD13lu"
sample_sheet$Cell.line[sample_sheet$Cell.line == "LL97"] <- "LL97A"

sample_sheet$Treatment.condition <- gsub(pattern = "/", replacement = "_", x = sample_sheet$Treatment.condition)
sample_sheet$SampleID <- paste(sample_sheet$Cell.line, sample_sheet$Treatment.condition, sep = "_")

#create a sample ID by combining cell line with treatment condition
sample_sheet <- unique(sample_sheet, by = "SampleID")
sample_sheet$Condition <- demographics$Disease[match(sample_sheet$Cell.line, demographics$Name)]

#Create columns for primary vs commercial, age and gender for each sample
colnames(sample_sheet)[colnames(sample_sheet) == "Treatment_condition"] <- "Treatment"
sample_sheet$Cell_line_type <- demographics$Cell_line_type[match(sample_sheet$Cell.line, demographics$Name)]
sample_sheet$Age <- demographics$Age[match(sample_sheet$Cell.line, demographics$Name)]
sample_sheet$Gender <- demographics$Gender[match(sample_sheet$Cell.line, demographics$Name)]

#read in the .bam files
bams <- data.frame(bamReads = list.files(path = "G:/ATAC-seq 2024/Deduplicated merged", pattern = ".clean.bam$", full.names = TRUE))
bams$Sample <- gsub(pattern = "G:/ATAC-seq 2024/Deduplicated merged/|.clean.bam", replacement = "", x = bams$bamReads)
bams$Sample <- gsub(pattern = "C7231", replacement = "CC7231", x = bams$Sample)
bams$Sample <- gsub(pattern = "CCD13", replacement = "CCD13lu", x = bams$Sample)
bams$Sample <- gsub(pattern = "LL97", replacement = "LL97A", x = bams$Sample)

#create a new column for .bam file information
sample_sheet$bamReads <- bams$bamReads[match(sample_sheet$SampleID, bams$Sample)]

peaks <- data.frame(Peaks = list.files(path = "G:/ATAC-seq 2024/Peaks (merged)", pattern = ".xls$", full.names = TRUE))
peaks$Sample <- gsub(pattern = "G:/ATAC-seq 2024/Peaks \\(merged\\)/|_peaks.xls", replacement = "", x = peaks$Peaks)
peaks$Sample <- gsub(pattern = "C7231", replacement = "CC7231", x = peaks$Sample)
peaks$Sample <- gsub(pattern = "CCD13", replacement = "CCD13lu", x = peaks$Sample)
peaks$Sample <- gsub(pattern = "LL97", replacement = "LL97A", x = peaks$Sample)

#read in the peak files
sample_sheet$Peaks <- peaks$Peaks[match(sample_sheet$SampleID, peaks$Sample)]
sample_sheet <- sample_sheet[!is.na(sample_sheet$bamReads),]
sample_sheet$PeakCaller <- "macs"
sample_sheet$PeakFormat <- "macs"
rm(bams, peaks)

peaks <- dba(sampleSheet = sample_sheet)
#mark areas with high probability of false positives (black) and areas with possible false positives (grey)
peaks <- dba.blacklist(peaks, blacklist = TRUE, greylist = FALSE)
#count peaks and overlap them if they are close to each other
peaks <- dba.count(peaks, summits = 100, score = DBA_SCORE_READS)

#plot the amount of reads for each sample
ggplot(dba.show(peaks), 
       aes(x = ID, y = Reads)) + geom_bar(stat = "identity") + xlab("") + ylab("Number of reads") + theme_bw() + 
  theme(axis.text.x = element_text(angle = 90)) + geom_hline(yintercept = 50000000, color = "red", linetype = c("solid")) + 
  scale_y_continuous(breaks = seq(0, 140000000, 10000000), labels = function(x) format(x, big.mark = ",", scientific = FALSE))

#plot the amount of reads but with the minimum recommended fraction of reads shown as a dotted red line
ggplot(dba.show(peaks), 
       aes(x = ID, y = FRiP)) + geom_bar(stat = "identity") + xlab("") + ylab("Fraction of Reads in called Peak regions (FRiP) score") + theme_bw() + 
  theme(axis.text.x = element_text(angle = 90)) + geom_hline(yintercept = c(0.2, 0.3), color = "red", linetype = c("dashed", "solid"))

#peak annotation
peak_granges <- dba.peakset(peaks, bRetrieve = TRUE, DataType = DBA_DATA_GRANGES)
txdb <- TxDb.Hsapiens.UCSC.hg38.knownGene
peak_granges <- annotatePeak(peak_granges, TxDb = txdb, annoDb = "org.Hs.eg.db")
peak_counts <- as.data.frame(peak_granges)

#annotations by gene regions
plotAnnoPie(peak_granges, col = c("aquamarine", "paleturquoise2", "dodgerblue", "red", "chartreuse3", "lightgoldenrod", "darkorange", "deeppink", "pink", "black", "mediumpurple"))

#Ignore sex chromosome reads
peak_counts <- peak_counts[!peak_counts$seqnames %in% c("chrX", "chrY"),]
#Ignore regions with zero counts
peaks_dgelist <- DGEList(counts = peak_counts[, !colnames(peak_counts) %in% c("seqnames", "start", "end", "width", "strand", "annotation", "geneChr", "geneStart", "geneEnd", "geneLength", "geneStrand", "geneId", "transcriptId", "distanceToTSS", "ENSEMBL", "SYMBOL", "GENENAME")], genes = peak_counts[, c("seqnames", "start", "end", "width", "strand", "annotation", "geneChr", "geneStart", "geneEnd", "geneLength", "geneStrand", "geneId", "transcriptId", "distanceToTSS", "ENSEMBL", "SYMBOL", "GENENAME")], samples = sample_sheet[, 1:7], remove.zeros = TRUE)
peaks_dgelist$samples$Condition_Treatment <- paste(peaks$samples$Condition, peaks$samples$Treatment, sep = "_")
peaks_dgelist$samples$Condition <- paste(peaks$samples$Condition)

#Ignore regions with few counts
peaks_dgelist <- peaks_dgelist[filterByExpr(peaks_dgelist, group = peaks_dgelist$samples$Condition_Treatment), , keep.lib.sizes = FALSE]

#normalise library sizes from the raw size
peaks_dgelist <- calcNormFactors(peaks_dgelist, method = "TMM")
lcpm <- cpm(peaks_dgelist, log = TRUE)

#set up MDS (PCA) analysis
mds <- data.frame(PC1 = plotMDS(lcpm, plot = FALSE)$x, PC2 = plotMDS(lcpm, plot = FALSE)$y, 
                  PC3 = plotMDS(lcpm, dim.plot = c(3, 4), plot = FALSE)$x, 
                  PC4 = plotMDS(lcpm, dim.plot = c(3, 4), plot = FALSE)$y, 
                  PC5 = plotMDS(lcpm, dim.plot = c(4, 5), plot = FALSE)$y, 
                  Var_explained = plotMDS(lcpm, plot = FALSE)$var.explained, peaks_dgelist$samples)

variance_explained = round(mds$Var_explained * 100, 2)

#create groupings for M<DS
mds$Treatment <- factor(mds$Treatment, levels = c("US_UT",  "US_Nin", "TGFb1_UT", "TGFb1_Nin"))
mds$Condition_Type <- factor(paste(mds$Condition, mds$Cell_line_type), levels = c("IPF Primary", "IPF Commercial", "NDC Primary", "NDC Commercial"))

#Plot MDS
ggplot(mds, aes(x = PC1, y = PC2, colour = Treatment)) + 
  stat_ellipse(data = mds, aes(x = PC1, y = PC2, group = Cell_line_type, color = Cell_line_type), 
              type = "t", linetype = "solid", size = 1) +
  geom_point(size = 3) + 
  geom_text_repel(aes(label = Cell.line), max.overlaps = 60) + 
  theme_bw() + 
  labs(title = "", 
       x = paste0("Leading logFC dimension 1 (", variance_explained[1], "% variance)"), 
       y = paste0("Leading logFC dimension 2 (", variance_explained[2], "% variance)"),
       colour = "Stimulation") +
  #xlab("Leading logFC dimension 1") + 
  #ylab("Leading logFC dimension 2") + 
  scale_color_manual(values = c("darkturquoise","olivedrab3","orchid","orange","chartreuse2","lightgoldenrod","#E37676","aquamarine2")) + 
  scale_shape_manual(values = c(16, 21, 17, 24)) + guides(shape = guide_legend(title = "Condition"))+
  scale_x_continuous(limits = c(-4, 4)) +  # Set x-axis limit to -3 to 3
  scale_y_continuous(limits = c(-2.25, 2.25)) +  # Set y-axis limit to -3 to 3
   theme(
    legend.title = element_text(size = 20),  # Legend title font size
    legend.text = element_text(size = 16),    # Legend item font size
    axis.title.x = element_text(size = 18),  # Increase font size of x-axis title
    axis.title.y = element_text(size = 18),   # Increase font size of y-axis title
    axis.text.x = element_text(size = 14),   # Increase font size of x-axis tick labels
    axis.text.y = element_text(size = 14)    # Increase font size of y-axis tick label
  )

#Analyse the DACRs for each sample and form them into groups
design <- model.matrix(~ 0 + Condition_Treatment + Cell_line_type, data = peaks_dgelist$samples)
colnames(design) <- gsub(pattern = "Condition_Treatment|Cell_line_type", replacement = "", x = colnames(design))
v <- voom(peaks_dgelist, design = design, plot = TRUE)
corfit <- duplicateCorrelation(v, design = design, block = factor(peaks_dgelist$samples$Cell.line))
v <- voom(peaks_dgelist, design = design, plot = TRUE, block = factor(peaks_dgelist$samples$Cell.line), correlation = corfit$consensus.correlation)
corfit <- duplicateCorrelation(v, design = design, block = factor(peaks_dgelist$samples$Cell.line))
fit <- lmFit(v, design = design, block = factor(peaks_dgelist$samples$Cell.line), correlation = corfit$consensus.correlation)

#make comparisons between the sample groups based on IPF/NDC, treatments or stimulation
cm <- makeContrasts(IPF.TGFb1_vs_US = IPF_TGFb1_UT - IPF_US_UT,
                    NDC.TGFb1_vs_US = NDC_TGFb1_UT - NDC_US_UT,
                    IPF.vs.NDC_TGFb1_vs_US = IPF_TGFb1_UT - NDC_TGFb1_UT, 
                    IPF.vs.NDC_US.Nin_vs_UT = IPF_US_Nin - NDC_US_Nin, 
                    IPF.vs.NDC_TGFb1.Nin_vs_UT = IPF_TGFb1_Nin - NDC_TGFb1_Nin,
                    IPF.vs.NDC_US_UT = IPF_US_UT - NDC_US_UT, 
                    levels = design)

fit2 <- contrasts.fit(fit, contrasts = cm)
fit2 <- eBayes(fit2)
        
summary(decideTests(fit2, lfc = log2(1.5)))            

for (i in colnames(cm)) {
  dacr <- topTable(fit2, coef = i, number = Inf)
  write.csv(dacr, file = paste0("C:/Users/21955968/OneDrive - The University of Western Australia/Epigenetics/ATAC-seq/ATAC results/DACRs (merged and deduplicated)/top 3000 DACRs/", i, ".csv"), row.names = FALSE)
}

for (i in c("IPF.vs.NDC_US_UT", "IPF.TGFb1_vs_US", "NDC.TGFb1_vs_US")) {
  dacr <- topTable(fit2, coef = i, number = 3000)[, c("seqnames", "start", "end")]
  write.table(dacr, file = paste0("C:/Users/21955968/OneDrive - The University of Western Australia/Epigenetics/ATAC-seq/ATAC results/DACRs (merged and deduplicated)/top 3000 DACRs/", i, ".bed"), row.names = FALSE, col.names = FALSE, quote = FALSE)
}
