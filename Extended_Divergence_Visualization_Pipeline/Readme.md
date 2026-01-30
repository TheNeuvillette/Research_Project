# Usage of the Extended Divergence Visualization Pipeline:

The extended divergence visualization pipeline is an extention of the standard pipeline, which takes results from the invLAA population simulations, post-processes them into a single file, calculates the windowed Fst and finally plots the windowed Fst along the chromosome.

In contrast to the standard pipeline, the extended pipeline supports two modes: Regular and Interactive.
These modes can be specified in the config.yaml file. The regular mode is indentical to the standard pipeline: It takes 2 vcf files from the simulations, post-processes them into a single file, calculates the windowed Fst and plots a single graph of Fst along chromosome, given the specified window size & step. On the other hand, the interactive pipeline creates an interactive R shiny app, where an Fst graph as funciton of the position in the chromosome is shown, which can be updated during runtime with window size and step. The interactive pipeline also takes 2 vcf files from the simulations, post-processes them into a single file, yet then calculates the per-site Fst, which is then used for calculating windows.

## 1. Usage of the pipeline:
### 1.1. Regular mode:

Step 1: Config File:
Set the mode to "regular".
Choose the wanted window size for the plot to have. The standard is window_size: 200, window_step: 100.

Step 2: Running the pipeline:
cd to "Interactive_Windows_Pipeline", then sbatch the snakemake.sh under scripts/snakemake.sh.

Step 3: Retrieve the Fst plots (and other results) under results/.../plots

### 1.2. Interactive mode:

Step 1: Config File:
Set the mode to "interactive".

Step 2: Running the pipeline:
cd to "Interactive_Windows_Pipeline", then sbatch the snakemake.sh under scripts/snakemake.sh.

Step 3: Launching the R shiny:
Go to the .err file under /logs. As soon as the pipeline is ready for launching your R shiny app, a port will be written in the last line of the .err. Example: Listening on http://127.0.0.1:3077
Once this message is obtained, do the following steps to open the R shiny app:
1. Open an interactive R session in your terminal using: "R --no-save". In case you haven't yet installed the R module, do it using "module load R/4.2.1-foss-2021a".
2. Once in the interactive R session, set the source to the R script using: source("scripts/plot_Fst_interactive.R")
3. Then call the "runFstShiny(path/to/Fst_per_site.weir.fst)" function. Example: runFstShiny("results/snp/experiment1/invLAA/Fst_vcf/invLAA_combined_15000_1_mod_Fst_per_site.weir.fst")
4. This will lead to a port being available for launching, clicking on it will open the R shiny app. Example: Listening on http://127.0.0.1:3077
