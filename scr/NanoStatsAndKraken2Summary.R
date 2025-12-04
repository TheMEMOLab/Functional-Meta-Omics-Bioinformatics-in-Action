#Nanostats

library(tidyverse)

# Define the directory containing your files
data_dir <- "."  # Change if needed

# Get the list of NanoStat output files
files <- list.files(data_dir, pattern = "\\.NanoStats\\.txt$", full.names = TRUE)

# Function to read and process each NanoStat file
read_nanostat <- function(file) {
  lines <- read_lines(file)  # Read file line by line
  lines <- lines[lines != ""]  # Remove empty lines
  
  # Extract key-value pairs using regex
  stats <- lines %>%
    str_trim() %>%  # Trim whitespace
    str_replace_all(",", "") %>%  # Remove thousands separator
    str_match("^(.*?):\\s+([0-9\\.]+)$") %>%  # Match key-value pairs
    as_tibble() %>%
    filter(!is.na(V2)) %>%
    select(Metric = V2, Value = V3) %>%
    mutate(Value = as.numeric(Value))
  
  sample_name <- gsub("\\.NanoStats\\.txt$", "", basename(file))  # Extract sample name
  stats <- stats %>% mutate(Sample = sample_name)
  
  return(stats)
}

# Read all files and combine into one dataframe
stats_data <- map_df(files, read_nanostat)

# Pivot for easy ploting

stats_wide <- stats_data %>%
  pivot_wider(names_from = Metric, values_from = Value)
head(stats_wide,2)


# Convert Sample column to factor to maintain order

stats_wide <- stats_wide %>% 
  mutate(Sample = factor(Sample, levels = unique(Sample)))

# Let's create a function to plot all the metrics:
library(RColorBrewer)
# Define metrics of interest (must match labels in the files!)
metrics <- c(
  "Number of reads",
  "Total bases",
  "Median read length",
  "Mean read length",
  "STDEV read length",
  "Read length N50",
  "Mean read quality",
  "Median read quality"
)
# Define 8 colors from the "Dark2" palette into a factor
metric_colors <- setNames(brewer.pal(8, "Dark2"), metrics)

# Create sorted horizontal bar plots with metric-based colors
plot_list <- map(metrics, function(metric) {
  ggplot(stats_wide, aes(y = fct_reorder(Sample, !!sym(metric)), x = !!sym(metric))) +
    geom_bar(stat = "identity", fill = metric_colors[metric]) +  # Assign color per metric
    theme_minimal() +
    labs(title = metric, x = metric, y = "Sample") +
    theme(axis.text.y = element_text(size = 10))   # Adjust text size if needed
}) %>%
  set_names(gsub(" ","", metrics))

# Check the results, by displaying the Mean read length and the N50


plot_list$Numberofreads
plot_list$ReadlengthN50


# We can use Patchwork to plot in the same canvas:

library(patchwork)
plot_list$Numberofreads + plot_list$ReadlengthN50
ReadLengthVP <- stats_wide %>% 
  select(Sample,`Mean read length`)%>%
  mutate(Method = case_when(
    str_detect(Sample, "FastPrep") ~ "FastPrep",
    str_detect(Sample, "Vortex_SRE") ~ "Vortex_SRE",
    str_detect(Sample, "Vortex") ~ "Vortex"
  )) %>% 
  ggplot(aes(x = Method, y = `Mean read length`, fill = Method)) +
  geom_violin(trim = FALSE, alpha = 0.6) +
  geom_jitter(width = 0.1, size = 2, alpha = 0.8)+ 
  ggtitle('Mean Read Length')

N50VP <- stats_wide %>% 
  select(Sample,`Read length N50`)%>%
  mutate(Method = case_when(
    str_detect(Sample, "FastPrep") ~ "FastPrep",
    str_detect(Sample, "Vortex_SRE") ~ "Vortex_SRE",
    str_detect(Sample, "Vortex") ~ "Vortex"
  )) %>% 
  ggplot(aes(x = Method, y = `Read length N50`, fill = Method)) +
  geom_violin(trim = FALSE, alpha = 0.6) +
  geom_jitter(width = 0.1, size = 2, alpha = 0.8)+ 
  ggtitle('Read length N50')

ReadLengthVP + N50VP
library(ggpubr)

ReadLengthVP <- ReadLengthVP +  # Global test
  stat_compare_means(
    comparisons = list(
      c("FastPrep", "Vortex"),
      c("FastPrep", "Vortex_SRE"),
      c("Vortex", "Vortex_SRE")
    ),
    method = "t.test",  # Technically not perfect post-ANOVA but okay for vis
    label = "p.signif"
  ) 
N50VP <- N50VP +
  stat_compare_means(
    comparisons = list(
      c("FastPrep", "Vortex"),
      c("FastPrep", "Vortex_SRE"),
      c("Vortex", "Vortex_SRE")
    ),
    method = "t.test",  # Technically not perfect post-ANOVA but okay for vis
    label = "p.signif"
  ) 

ReadLengthVP + N50VP

ReadLengthVP <- ReadLengthVP +
  theme_minimal() +
  scale_fill_brewer(palette =  "Dark2") +
  theme(legend.position = "none")

N50VP <- N50VP +
  theme_minimal() +
  scale_fill_brewer(palette =  "Dark2") +
  theme(legend.position = "none")

ReadLengthVP + N50VP

MergedQCPlot <- ReadLengthVP + N50VP

##KRaken2

# List files
files <- dir(pattern = "*.kraken2.species.tsv")
# Extract sample IDs from filenames
Names <- tibble(FileName = files) %>%
  mutate(sampleID = str_remove_all(FileName, ".kraken2..*"))

# Read in all tables
Tables <- map(files, ~ read_tsv(.,
                                col_names = c("Percentage", "TaxID", "SpeciesName"),
                                col_types = cols(.default = "c"))) %>%
  set_names(Names$sampleID)

Tables <- map(files, ~ read_tsv(.,
                                col_names = c("Percentage", "TaxID", "SpeciesName"),
                                col_types = cols(.default = "c"))) %>%
  set_names(Names$sampleID)
Tables2Abundance <- map(Tables, ~ select(., SpeciesName, Percentage) %>%
                          mutate(Percentage = as.numeric(Percentage)))


AbundanceTable <- reduce(Tables2Abundance, full_join, by = "SpeciesName") %>%
  rename_with(~ Names$sampleID, -SpeciesName) %>%
  mutate(across(-SpeciesName, ~ replace_na(.x, 0)))

library(pheatmap)
AbundanceTable %>% 
  column_to_rownames("SpeciesName") %>%
  pheatmap()


MtrixForPH <- AbundanceTable %>%
  mutate(across(where(is.numeric), ~ log2(.x + 1))) %>%
  column_to_rownames("SpeciesName") %>%
  as.matrix()

pheatmap(MtrixForPH)

pheatmap(MtrixForPH, cluster_row=F, cellwidth = 16)

library(viridis)
Color <- rev(inferno(200))
pheatmap(MtrixForPH, 
         cluster_row=F,
         cellwidth = 16,
         color=Color)


ColAnnot <- AbundanceTable %>%
  select(-SpeciesName) %>%
  colnames() %>%
  enframe(value = "Sample") %>%
  mutate(Method=str_remove(Sample,"_\\d+.*")) %>%
  select(-name) %>% 
  column_to_rownames("Sample")


pheatmap(MtrixForPH, 
         cluster_row=F,
         cellwidth = 16,
         color=Color,
         annotation_col = ColAnnot)

AnnotColor <- list(Method=AbundanceTable %>%
                     select(-SpeciesName) %>%
                     colnames() %>%
                     enframe(value = "Sample") %>%
                     mutate(Method=str_remove(Sample,"_\\d+.*")) %>%
                     select(-name) %>% 
                     column_to_rownames("Sample") %>%
                     distinct() %>%
                     mutate(Color=brewer.pal(3,"Dark2")) %>%
                     deframe())

KrakenPH <- pheatmap(MtrixForPH, 
                     cluster_row=F,
                     cellwidth = 16,
                     color=Color,
                     annotation_col = ColAnnot,
                     annotation_colors = AnnotColor,
                     border_color = F)

library(ggplotify)
KrakenPH <- as.ggplot(KrakenPH)

library(gridExtra)
QCK2HM <- grid.arrange(arrangeGrob(ReadLengthVP,N50VP),KrakenPH,ncol=2)