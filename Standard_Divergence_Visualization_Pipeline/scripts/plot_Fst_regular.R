#!/usr/bin/env Rscript

# Load required libraries only
library(ggplot2)

if (length(commandArgs(trailingOnly = TRUE)) < 4) {
    stop("Usage: Rscript process_data.R <input_files> <output_directory>")
}
args = commandArgs(trailingOnly=TRUE)
cat("Getting data from snakemake\n")

# Assign command line arguments to a variable
input_file <- args[1]
sim_name <- args[2]
sim_no <- args[3]
window_size <- as.numeric(args[5])
window_step <- as.numeric(args[6])

# Colorblind-friendly palette
cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", 
                "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

# Load the Fst results into R
fst_data <- read.table(input_file, header = TRUE)

# Calculate the 99th percentile threshold for Fst
fst_threshold <- quantile(fst_data$WEIGHTED_FST, 0.99, na.rm = TRUE)

# Define title of the plot 
plot_title <- paste(sim_name,"ST vs INV",paste0("(sim no.=",sim_no,")"))

# Identify positions where Fst exceeds the threshold and create bins of the size of window size
fst_outliers <- fst_data[fst_data$WEIGHTED_FST > fst_threshold, "BIN_START"]
fst_shading <- data.frame(
  xmin = fst_outliers - (window_size / 2),
  xmax = fst_outliers + (window_size / 2),
  ymin = -Inf,
  ymax = Inf
)

# Plot with vertical shading
fst_plot <- ggplot(fst_data, aes(x = BIN_START, y = WEIGHTED_FST)) +
  # Add vertical shading for outliers in bins of window size
  geom_rect(
    data = fst_shading,
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
    fill = cbbPalette[7], alpha = 0.2, inherit.aes = FALSE
  ) +
  ggtitle(plot_title) +
  # Original line plots
  geom_line(colour = cbbPalette[7]) +
  # Add vertical lines for specific genomic regions
  geom_vline(xintercept = 10000, color = "blue", linetype = "solid") +
  geom_vline(xintercept = 110000, color = "blue", linetype = "solid") +
  geom_vline(xintercept = 30000, color = "red", linetype = "dashed") +
  geom_vline(xintercept = 90000, color = "red", linetype = "dashed") +
  # Labels and formatting
  labs(x = "Position (bp)", y = "Fst") +
  scale_x_continuous(limits = c(0, 120000), expand = c(0, 0)) +
  scale_y_continuous(limits = c(min(fst_data$WEIGHTED_FST) - 0.1,
                                max(fst_data$WEIGHTED_FST) + 0.1),
                     expand = c(0, 0.0)) +
  theme_minimal() +
  theme(
    panel.background = element_rect(fill = "white", color = "black"),
    plot.background = element_rect(fill = "white", color = NA),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "black", fill = NA, size = 1),
    axis.line = element_line(color = "black"),
    axis.title = element_text(color = "black"),
    axis.text = element_text(color = "black"),
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),  # Centered title with size 10
    legend.position = "none",
    plot.margin = margin(t = 20, r = 20, b = 10, l = 10)
  )

# Specify the output directory
output_directory <- args[4]
output_filename <- paste0(sim_name,"_combined_15000_",sim_no,"_Fst_Wsize_",window_size,"_Wstep_",window_step)

# Save the plot as PNG
ggsave(filename = file.path(output_directory, paste0(output_filename,".png")), plot = fst_plot, width = 10, height = 6, dpi = 300)

# Save the plot as PDF
ggsave(filename = file.path(output_directory, paste0(output_filename,".pdf")), plot = fst_plot, width = 10, height = 6)