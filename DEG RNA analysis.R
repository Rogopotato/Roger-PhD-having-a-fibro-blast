#README
#Original script was provided by INSiGENe by Dr Denise Anderson and Dr Anya Jones for analysis of differential gene expression
#Intends to do some quality control, data visualisation and outputs CSVs of DEGs that show fold change and adjusted p value
#This script was used for analysis of TGF-b1 and nintedanib treatment of lung fibroblasts
#Modifications made by Roger Li for his PhD
#Last updated: 27/09/2025


library(tidyverse)
library(biomaRt)
library(org.Hs.eg.db)
library(ggplot2)
library(gplots)
library(ggtree)
library(edgeR)
library(DESeq2)
library(limma)
library(EnhancedVolcano)
library(vsn)
library(EDASeq)
library(RColorBrewer)
library(pheatmap)
library(ggrepel)
library(bookdown)
library(clusterProfiler)
library(enrichplot)
library(ReactomePA)
library(msigdbr)
library(ggsci)
library(dplyr)
library(RUVSeq)
library(tidyr)
library(qs)
library(openxlsx)
library(ggrepel)
library(lubridate)
library(kableExtra)
library(knitr)
library(curl)

counts = read.table("C:/Users/21955968/OneDrive - The University of Western Australia/Epigenetics/RNA/RNA-seq R/manuscript comparisons/RNAseq_gene_level_counts_TGFb1+Pir.txt",
                    header = TRUE, stringsAsFactors = FALSE, check.names = FALSE, row.names=1)
head(counts)

counts$Ensembl_ID = str_replace(string = rownames(counts), pattern = ".[0-9]+$", replacement = "")
rownames(counts) = counts$Ensembl_ID

mart = useMart(biomart = "ensembl", dataset = "hsapiens_gene_ensembl") 

gene_annotation = getBM(attributes = c("ensembl_gene_id", "hgnc_symbol","entrezgene_id", "description"), filters = "ensembl_gene_id", values = counts$Ensembl_ID, mart = mart)

counts$hgnc_symbol = gene_annotation$hgnc_symbol[match(counts$Ensembl_ID,gene_annotation$ensembl_gene_id)]
counts$entrezgene_id = gene_annotation$entrezgene_id[match(counts$Ensembl_ID,gene_annotation$ensembl_gene_id)]
counts$description = gene_annotation$description[match(counts$Ensembl_ID, gene_annotation$ensembl_gene_id)]

colnames(counts) = gsub("HS888_TGF.b1_UT", "HS888_TGFb1_UT", colnames(counts))

#Demographic data such as gender, age, ethnicity etc.
demo = read.csv("C:/Users/21955968/OneDrive - The University of Western Australia/Epigenetics/RNA/RNA-seq R/demographics.csv")
  
#sample data. This is where disease status and stimulation/treatment is split for later analysis
pheno = read.csv("C:/Users/21955968/OneDrive - The University of Western Australia/Epigenetics/RNA/RNA-seq R/manuscript comparisons/metadata_TGFb1+Nin.csv", row.names = 1)

head(pheno)

# split stimulation and treatment in separate columns
pheno <- pheno %>% separate(Treatment_condition, into = c("stimulation", "antifibrotic_treatment"), sep = "/")

head(pheno)

#Generation and modification of data frame for later analysis. The columns made here will allow for comparisons
pheno = pheno %>% mutate(status = case_when(
  Cell_line == "ALF10E" ~ "NDC",
  Cell_line == "ALF12H" ~ "NDC",
  Cell_line == "ALF15B" ~ "IPF", 
  Cell_line == "ALF18B" ~ "IPF", 
  Cell_line == "ALF28D" ~ "IPF", 
  Cell_line == "ALF34B" ~ "NDC", 
  Cell_line == "LL29" ~ "IPF", 
  Cell_line == "LL86" ~ "NDC", 
  Cell_line == "LL97A" ~ "IPF",
  Cell_line == "CCD13lu" ~ "NDC",
  Cell_line == "CC7231" ~ "IPF",
  Cell_line == "HS888" ~ "NDC",
  TRUE ~ NA_character_  
))

pheno = pheno %>% # add gender
  mutate(gender = case_when(
    Cell_line == "ALF10E" ~ "M",
    Cell_line == "ALF12H" ~ "F",
    Cell_line == "ALF15B" ~ "M", 
    Cell_line == "ALF18B" ~ "M", 
    Cell_line == "ALF28D" ~ "F", 
    Cell_line == "ALF34B" ~ "F", 
    Cell_line == "LL29" ~ "F", 
    Cell_line == "LL86" ~ "M", 
    Cell_line == "LL97A" ~ "M",
    Cell_line == "CCD13lu" ~ "M",
    Cell_line == "CC7231" ~ "M",
    Cell_line == "HS888" ~ "M",
    TRUE ~ NA_character_  
  ))

pheno = pheno %>% # add age
  mutate(age_in_years = case_when(
    Cell_line == "ALF10E" ~ "69",
    Cell_line == "ALF12H" ~ "60",
    Cell_line == "ALF15B" ~ "59", 
    Cell_line == "ALF18B" ~ "63", 
    Cell_line == "ALF28D" ~ "59", 
    Cell_line == "ALF34B" ~ "67", 
    Cell_line == "LL29" ~ "26", 
    Cell_line == "LL86" ~ "18", 
    Cell_line == "LL97A" ~ "48",
    Cell_line == "CCD13lu" ~ "71",
    Cell_line == "CC7231" ~ "52",
    Cell_line == "HS888" ~ "20",
    TRUE ~ NA_character_  
  ))

pheno = pheno %>% # add ethnicity (NA = not provided)
  mutate(ethnicity = case_when(
    Cell_line == "ALF10E" ~ "NA",
    Cell_line == "ALF12H" ~ "NA",
    Cell_line == "ALF15B" ~ "NA", 
    Cell_line == "ALF18B" ~ "NA", 
    Cell_line == "ALF28D" ~ "NA", 
    Cell_line == "ALF34B" ~ "NA", 
    Cell_line == "LL29" ~ "Caucasian", 
    Cell_line == "LL86" ~ "Caucasian", 
    Cell_line == "LL97A" ~ "Caucasian",
    Cell_line == "CCD13lu" ~ "African_American",
    Cell_line == "CC7231" ~ "Caucasian",
    Cell_line == "HS888" ~ "Caucasian",
    TRUE ~ NA_character_  
  ))

pheno = pheno %>% # add smoking status (NA = not provided)
  mutate(smoking_status = case_when(
    Cell_line == "ALF10E" ~ "Ex",
    Cell_line == "ALF12H" ~ "Current",
    Cell_line == "ALF15B" ~ "Ex", 
    Cell_line == "ALF18B" ~ "Ex", 
    Cell_line == "ALF28D" ~ "Ex", 
    Cell_line == "ALF34B" ~ "Never", 
    Cell_line == "LL29" ~ "NA", 
    Cell_line == "LL86" ~ "NA", 
    Cell_line == "LL97A" ~ "NA",
    Cell_line == "CCD13lu" ~ "NA",
    Cell_line == "CC7231" ~ "Never",
    Cell_line == "HS888" ~ "NA",
    TRUE ~ NA_character_  
  ))

pheno = pheno %>% # add other condition (NA = not provided)
  mutate(other_condition = case_when(
    Cell_line == "ALF10E" ~ "NA",
    Cell_line == "ALF12H" ~ "NA",
    Cell_line == "ALF15B" ~ "NA", 
    Cell_line == "ALF18B" ~ "NA", 
    Cell_line == "ALF28D" ~ "NA", 
    Cell_line == "ALF34B" ~ "NA", 
    Cell_line == "LL29" ~ "NA", 
    Cell_line == "LL86" ~ "Sarcoma", 
    Cell_line == "LL97A" ~ "NA",
    Cell_line == "CCD13lu" ~ "Carcinoma",
    Cell_line == "CC7231" ~ "NA",
    Cell_line == "HS888" ~ "Osteosarcoma",
    TRUE ~ NA_character_  
  ))

pheno = pheno %>% # add info re Primary cells vs commercial cells 
  mutate(type = case_when(
    Cell_line == "ALF10E" ~ "primary",
    Cell_line == "ALF12H" ~ "primary",
    Cell_line == "ALF15B" ~ "primary", 
    Cell_line == "ALF18B" ~ "primary", 
    Cell_line == "ALF28D" ~ "primary", 
    Cell_line == "ALF34B" ~ "primary", 
    Cell_line == "LL29" ~ "commercial", 
    Cell_line == "LL86" ~ "commercial", 
    Cell_line == "LL97A" ~ "commercial",
    Cell_line == "CCD13lu" ~ "commercial",
    Cell_line == "CC7231" ~ "commercial",
    Cell_line == "HS888" ~ "commercial",
    TRUE ~ NA_character_  
  ))

head(pheno)

pheno$Stimulation = paste(pheno$status, pheno$stimulation, pheno$antifibrotic_treatment, sep = "_")

pheno$Stimulation = paste(pheno$stimulation, pheno$antifibrotic_treatment, sep = "_")

rownames(pheno) = paste(pheno$Cell_line, pheno$stimulation, pheno$antifibrotic_treatment, sep = "_") # to match the colnames of the table of counts


#identical(colnames(counts[, !colnames(counts) %in% c("Ensembl_ID", "hgnc_symbol", "entrezgene_id", "description")]), rownames(pheno)) # check that in the same order
pheno = pheno[colnames(counts[, !colnames(counts) %in% c("Ensembl_ID", "hgnc_symbol", "entrezgene_id", "description")]),]

#identical(colnames(counts[, !colnames(counts) %in% c("Ensembl_ID", "hgnc_symbol", "entrezgene_id", "description")]), rownames(pheno)) # check that in the same order
pheno$Exp_date_ord = as.Date(pheno$Date.of.experiment, format = "%d/%m/%Y")

# Order the factor levels based on the chronological order of dates
pheno$Exp_date_ord = factor(pheno$Exp_date_ord,levels = sort(unique(pheno$Exp_date_ord)))
pheno$Exp_date_ord = factor(pheno$Exp_date_ord,levels = 
  c("2022-12-21", "2023-01-30", "2023-02-14", "2023-07-11", "2023-08-08", "2023-08-29", "2023-09-26", "2023-10-10", "2023-10-17", "2023-10-25", "2023-10-31", "2023-11-07", "2023-12-05", "2023-12-12", "2024-01-29", "2024-02-16"))

#creates table of clinical data
kable(demo, caption = "The clinical data. {#tbl-clinical-data}")

kable(table(pheno$Exp_date_ord, pheno$Cell_line), caption = "Experimental dates and cell line identity. {#tbl-Exp-date-cell-line-identity}")

long_counts = counts %>% dplyr::select(-c("Ensembl_ID", "hgnc_symbol", "entrezgene_id", "description")) %>% mutate(across(everything(), ~ .^0.2)) %>% pivot_longer(cols = everything(), names_to = "Sample", values_to = "Value")

#draw plot of the counts for each sample
ggplot(long_counts, aes(x = Sample, y = Value)) + geom_boxplot() + theme_minimal() +theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 6), 
panel.border = element_rect(color = "black", fill = NA, linewidth = 1)) 
+ labs(title = "Boxplot of raw counts to the power of 0.2", x = "Sample identifier", y = "Raw Counts ^ 0.2") + ylim(0, 25)  

#gives table of gene expression counts
table(rowSums(counts[, !colnames(counts) %in% c("Ensembl_ID", "hgnc_symbol", "entrezgene_id", "description")] > 0) >=108) %>% kbl(caption = "Number of genes with evidence of expression (at least 1 read) in all 108 samples. {#tbl-expr-all}", 
 col.names = c("Result", "Freq")) %>% kable_styling() %>% kable_paper("hover", full_width = F) %>% column_spec(2, width = "2cm")

#gives table of genes with expression in at least 6 samples
table(rowSums(counts[, !colnames(counts) %in% c("Ensembl_ID", "hgnc_symbol", "entrezgene_id", "description")] > 0) >=6) %>% kbl(caption = "Number of genes with evidence of expression (at least 1 read) in at least 6 samples (the smallest group size). {#tbl-expr-group}", 
 col.names = c("Result", "Freq")) %>% kable_styling() %>% kable_paper("hover", full_width = F) %>% column_spec(2, width = "2cm") 

#create DGE list
DGE = DGEList(counts = counts[, !colnames(counts) %in% c("Ensembl_ID", "hgnc_symbol", "entrezgene_id", "description")], 
genes = counts[, colnames(counts) %in% c("Ensembl_ID", "hgnc_symbol", "entrezgene_id", "description")], samples = pheno, remove.zeros = TRUE)

#create a plot of libraries
ggplot(data = DGE$samples, aes(x = rownames(DGE$samples), y = lib.size)) +
  geom_bar(stat = "identity", colour = "white") +
  xlab("Sample identifier") + ylab("Library size") + 
  theme_bw() + theme(axis.text.x = element_text(size = 5, angle = 90)) +
  geom_hline(yintercept = c(20000000, 30000000), color = "red", linetype = c("solid", "dashed")) + 
  scale_y_continuous(breaks = seq(0, 120000000, 10000000), labels = function(x) format(x, big.mark = ",", scientific = FALSE))

#remove genes that are lowly expressed. 
DGE = DGE[filterByExpr(DGE, group = DGE$samples$group, min.count = 5), , keep.lib.sizes = FALSE]
#Normalise library sizes
DGE = calcNormFactors(DGE, method = "TMM")
lcpm = cpm(DGE, log = TRUE)

#set up PCA
mds = data.frame(PC1 = plotMDS(lcpm, plot = FALSE)$x, PC2 = plotMDS(lcpm, plot = FALSE)$y, 
                 PC3 = plotMDS(lcpm, dim.plot = c(3, 4), plot = FALSE)$x, PC4 = plotMDS(lcpm, dim.plot = c(3, 4), plot = FALSE)$y, 
                 PC5 = plotMDS(lcpm, dim.plot = c(5, 6), plot = FALSE)$x, 
                 Var_explained = plotMDS(lcpm, plot = FALSE)$var.explained, DGE$samples)

variance_explained = round(mds$Var_explained * 100, 2)

#Draw the PCA. Fiddle with the variables and ellipses to visualise the comparisons you want.
ggplot(mds, aes(x = PC1, y = PC2, colour = DGE$samples$stimulation))+
  #stat_ellipse(data = mds, aes(x = PC1, y = PC2, group = DGE$samples$type, color = DGE$samples$type), 
              #type = "t", linetype = "solid", size = 1) +
  geom_point(size = 3) +
  geom_text_repel(aes(label = DGE$samples$Cell_line), max.overlaps = 60) + 
  theme_bw() + 
  labs(title = "", 
       x = paste0("Leading logFC dimension 1 (", variance_explained[1], "% variance)"), 
       y = paste0("Leading logFC dimension 2 (", variance_explained[2], "% variance)"),
       colour = "Stimulation") +
  scale_color_manual(values = c("orchid","darkturquoise","olivedrab3","orange","#E37676","aquamarine2","chartreuse2", "lightgoldenrod")) +
  scale_shape_manual(values = c(16, 21, 17, 24)) + guides(shape = guide_legend(title = "Condition")) +
  theme(
    legend.title = element_text(size = 18),  # Legend title font size
    legend.text = element_text(size = 14)    # Legend item font size
  )

variance_explained = round(mds$Var_explained * 100, 2)
ensembl = useMart(biomart = "ENSEMBL_MART_ENSEMBL", dataset = "hsapiens_gene_ensembl")
df = data.frame(counts$Ensembl_ID, counts$hgnc_symbol, counts$entrezgene_id, counts$description); rownames(df) = df$counts.Ensembl_ID
names(df) = c("Ensembl_ID","hgnc_symbol","entrezgene_id","description")  
chrs = getBM(attributes = c("ensembl_gene_id", "chromosome_name"),filters = "ensembl_gene_id", values = rownames(DGE$genes), mart = ensembl)
chrs = chrs[chrs$chromosome_name %in% c("X", "Y"), ]
sex.genes = rownames(DGE$genes) %in% chrs$ensembl_gene_id
DGE.sex.check = DGE[sex.genes, , keep.lib.sizes = FALSE]
mds1.2 = plotMDS(DGE.sex.check, plot = FALSE, dim.plot = c(1,2))
mds3.4 = plotMDS(DGE.sex.check, plot = FALSE, dim.plot = c(3,4))
mdsS = data.frame(mds1.2$x, mds1.2$y, mds3.4$x, mds3.4$y, row.names = rownames(DGE.sex.check$samples))
colnames(mdsS) = c("V1","V2","V3","V4")
mdsS$Sex = DGE.sex.check$samples$gender
mdsS$Gender = DGE.sex.check$samples$gender

#Set up DGE list analysis. 
DGE$samples$Treat = factor(paste(DGE$samples$status, DGE$samples$stimulation, DGE$samples$antifibrotic_treatment,sep="."), levels = c("IPF.US.UT","IPF.US.Nin","IPF.US.Pir","IPF.PDGF.UT","IPF.PDGF.Nin","IPF.PDGF.Pir","IPF.TGFb1.UT", "IPF.TGFb1.Nin","IPF.TGFb1.Pir","NDC.US.UT", "NDC.US.Nin", "NDC.US.Pir", "NDC.PDGF.UT", "NDC.TGFb1.UT", "NDC.PDGF.Nin","NDC.PDGF.Pir", "NDC.TGFb1.Nin","NDC.TGFb1.Pir"))
design = model.matrix(~0 + DGE$samples$Treat + DGE$samples$type)
colnames(design) = gsub("DGE\\$samples\\$Treat", "", colnames(design))
colnames(design) = gsub("DGE\\$samples\\$type", "", colnames(design))

v = voom(DGE, design)
corfit = duplicateCorrelation(v, design, block = factor(DGE$samples$Cell_line)) 
fit = lmFit(v, design, block = factor(DGE$samples$Cell_line), correlation = corfit$consensus.correlation)

#compare gene expression between groups. Set up the comparisons to generate the DEGs you want on the output csv
cm = makeContrasts(IPF.TGFb1_vs_US = IPF.TGFb1.UT - IPF.US.UT,
                   NDC.TGFb1_vs_US = NDC.TGFb1.UT - NDC.US.UT,
                   IPF_vs_NDC.US.UT = IPF.US.UT - NDC.US.UT,
                   IPF_vs_NDC.TGFb1.Nin = IPF.TGFb1.Nin - NDC.TGFb1.Nin,
                   levels = design)

fit2 = contrasts.fit(fit, contrasts = cm)
fit2 = eBayes(fit2, robust = TRUE)

summary(decideTests(fit2, lfc = log2(1.5)))

dge = list()

#name your csv
dge$IPF.TGFb1_vs_US = topTable(fit2, coef = "IPF.TGFb1_vs_US",number = Inf)
dge$NDC.TGFb1_vs_US = topTable(fit2, coef = "NDC.TGFb1_vs_US",number = Inf)
dge$IPF_vs_NDC.US.UT = topTable(fit2, coef = "IPF_vs_NDC.US.UT",number = Inf)
dge$IPF_vs_NDC.TGFb1.Nin = topTable(fit2, coef = "IPF_vs_NDC.TGFb1.Nin",number = Inf)

for (i in 1:length(names(dge))) {
  dge[[names(dge)[i]]] = merge(dge[[i]], DGE$genes[, c("Ensembl_ID", "hgnc_symbol", "entrezgene_id", "description")], by.x = 0, by.y = 0, all = TRUE, sort = FALSE)
}

wb = createWorkbook(); addWorksheet(wb, "IPF_vs_NDC.TGFb1.Nin_2")
writeData(wb, sheet = "IPF_vs_NDC.TGFb1.Nin_2", dge$IPF.TGFb1_vs_US)

lapply(names(dge)[2:length(names(dge))], FUN = function(x) {
  addWorksheet(wb, x)
  writeData(wb, sheet = x, dge[[x]])
})

#save the csv of DEGs
saveWorkbook(wb, file = "H:/Uni thingos/PhD/Epigenetics/RNA/RNA-seq results", overwrite = TRUE) 

EnhancedVolcano(dge$US.UT_IPF_vs_NDC, lab = dge$US.UT_IPF_vs_NDC$hgnc_symbol, x = "logFC", y = "adj.P.Val",  
                title = "US.UT_IPF_vs_NDC", pCutoff = 0.05, FCcutoff = log(1.5), subtitle = expression("4,663 genes" %down% "3,355 genes" %up% ""), 
                caption = "Total = 26,119 genes",legendLabels = c("NS", "|FC| >= 1.5", bquote(italic(.("p")) ~ "< 0.05"), bquote("|FC| >= 1.5 &" ~ italic(.("p")) ~ "< 0.05")),
                xlab = bquote(log[2] ~ ("Fold change")), ylab = bquote(~-log[10] ~ ("Adjusted" ~ italic(.("p")) * "-value")), 
                legendLabSize = 12, legendIconSize = 3.5, axisLabSize = 14, subtitleLabSize = 16, captionLabSize = 12, labSize = 3, drawConnectors = TRUE, widthConnectors = 0.5, colConnectors = "grey70", arrowheads = FALSE, max.overlaps = 11)
                + coord_cartesian(xlim=c(-12, 12), ylim = c(0, 50)) + scale_x_continuous(breaks=seq(-12, 12, 2))
