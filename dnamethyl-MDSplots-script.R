
library(readr)   # for write_csv
library(dplyr)
library(ggplot2)
library(ggrepel)

mds_data <- read_csv("./tables/mds_coordinates.csv")
var_explained <- read_csv("./tables/mds_variance.csv")


###Plot1 #######


# Filter to only the two treatments of interest
mds_data_sub <- mds_data %>%
  filter(Treatment %in% c("US_UT", "TGFb1_UT"))


# Plot only those samples
Pmds <- ggplot(mds_data_sub, aes(x = x, y = y, colour = Treatment, shape = Disease)) + 
  geom_point(size = 5) + 
  ggrepel::geom_text_repel(aes(label = Cell_line), max.overlaps = 60) + 
  theme_bw(base_size = 16) + 
  xlab(paste0("Leading dimension 1 (% Variance Explained: ", round(var_explained$var_explained_dim1, 2), ")")) + 
  ylab(paste0("Leading dimension 2 (% Variance Explained: ", round(var_explained$var_explained_dim2, 2), ")")) +
  scale_color_manual(values = c("US_UT" = "darkturqouise", "TGFb1_UT" = "orchid")) +
  scale_shape_manual(values = c(16, 21, 17, 24)) + 
  guides(shape = guide_legend(title = "Condition"),
         colour = guide_legend(title = "Treatment"))


Pmds <- ggplot(mds_data_sub, aes(
  x = x, 
  y = y, 
  colour = Treatment,   # Treatment = colour
  shape  = Disease      # Disease = shape
)) + 
  geom_point(size = 5) + 
  ggrepel::geom_text_repel(aes(label = Cell_line), max.overlaps = 60) + 
  theme_bw(base_size = 16) + 
  xlab(paste0("Leading dimension 1 (", round(var_explained$var_explained_dim1, 2), "%)")) + 
  ylab(paste0("Leading dimension 2 (", round(var_explained$var_explained_dim2, 2), "%)")) +
  
  # Treatment colours
  scale_color_manual(
    values = c("US_UT" = "darkturquoise", 
               "TGFb1_UT" = "orchid"),
    name = "Treatment"
  ) +
  
  # Disease shapes
  scale_shape_manual(
    values = c("IPF" = 17,   # triangle
               "NDC" = 16),  # circle
    name = "Disease"
  ) +
  
  guides(
    colour = guide_legend(title = "Treatment"),
    shape  = guide_legend(title = "Disease status")
  )


print(Pmds)

# Save to file (PNG)
ggsave("./figures/MDS_UT.png", Pmds, width = 12, height = 8, dpi = 300) 



###Plot2 #######


# Filter to only the treatments of interest
mds_data_sub2 <- mds_data %>%
  filter(Treatment %in% c("US_UT", "US_Nin", "US_Pir","TGFb1_UT", "TGFb1_Nin", "TGFb1_Pir" ))

# Plot only those samples
Pmds2 <- ggplot(mds_data_sub2, aes(x = x, y = y, colour = Treatment, shape = Disease)) + 
  geom_point(size = 5) + 
  ggrepel::geom_text_repel(aes(label = Cell_line), max.overlaps = 60) + 
  theme_bw(base_size = 16) + 
  xlab(paste0("Leading dimension 1 (% Variance Explained: ", round(var_explained$var_explained_dim1, 2), ")")) + 
  ylab(paste0("Leading dimension 2 (% Variance Explained: ", round(var_explained$var_explained_dim2, 2), ")")) +
  scale_color_manual(values = c("US_UT" = "darkturquoise", "TGFb1_UT" = "orchid", "US_Pir" = "red", "TGFb1_Nin" = "orange", "TGFb1_Pir" = "#009E73", "US_Nin" =  "olivedrab3")) +
  # Disease shapes
  scale_shape_manual(
    values = c("IPF" = 17,   # triangle
               "NDC" = 16),  # circle
    name = "Disease"
  ) + 
  guides(shape = guide_legend(title = "Disease status"),
         colour = guide_legend(title = "Treatment"))

print(Pmds2)

# Save to file (PNG)
ggsave("./figures/MDS_without PDGF.png", Pmds2, width = 12, height = 10, dpi = 300) 




#####The plots done by INSigen #######

# Create MDS plot with method-specific variance explained values
ggplot(mds_data, aes(x = x, y = y, colour = Treatment, shape = Condition_Type)) + 
  geom_point(size = 5) + 
  ggrepel::geom_text_repel(aes(label = Cell_line), max.overlaps = 60) + 
  theme_bw(base_size = 16) + 
  xlab(paste0("Leading dimension 1 (% Variance Explained: ", round(var_explained[1], 2), ")")) + 
  ylab(paste0("Leading dimension 2 (% Variance Explained: ", round(var_explained[2], 2), ")")) +
  scale_color_manual(values = c("lightblue", "darkturquoise", "blue", "lightpink", 
                                "violet", "magenta4", "olivedrab2", "limegreen", "darkgreen", "yellow", "orange", "tomato")) +
  scale_shape_manual(values = c(16, 21, 17, 24)) + 
  guides(shape = guide_legend(title = "Condition"))



ggplot(mds_data, aes(x = x, y = y, colour = Sample_Plate, shape = Condition_Type)) + 
  geom_point(size = 5) + 
  ggrepel::geom_text_repel(aes(label = Cell_line), max.overlaps = 60) + 
  theme_bw(base_size = 16) + 
  xlab(paste0("Leading dimension 1 (% Variance Explained: ", round(var_explained[1], 2), ")")) + 
  ylab(paste0("Leading dimension 2 (% Variance Explained: ", round(var_explained[2], 2), ")")) + 
  scale_color_manual(values = c("#E69F00", "#56B4E9", "#009E73", "#F0E442", 
                                "blue", "red", "#CC79A7", "darkgrey", 
                                "#44AA99", "#882255", "#332288")) +
  scale_shape_manual(values = c(16, 21, 17, 24)) + 
  guides(shape = guide_legend(title = "Condition"))
