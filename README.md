# Research Project - From VCF to Feature Vectors: Building a Machine-Learning-Ready Pipeline for Identifying Local Adaptation in Chromosomal Inversions

This repository contains the Snakemake pipelines and scripts coded and used during the research project. The project consisted of two main parts: In the first part, I recreated the divergence graph along the inversion using the FST summary statistic. Furthermore, I assessed the effect of varying the window size on the signal-to-noise ratio and, consequently, the detectability of adaptive alleles. In the second part, I developed a pipeline turning the simulated output into a normalized feature vector table suitable for model training and evaluated its ability to distinguish selected from neutral regions using exploratory data analysis.

The project consists of 4 pipelines:
- [Standard Divergence Visualization Pipeline:](https://github.com/TheNeuvillette/Research_Project/tree/main/Standard_Divergence_Visualization_Pipeline) Takes the simulated VCF files and produces a single chromosome-wide FST visualization per run. Allows for a user-defined window size and overlap specified via the configfile.
- [Extended Divergence Visualization Pipeline:](https://github.com/TheNeuvillette/Research_Project/tree/main/Extended_Divergence_Visualization_Pipeline) To be able to interactively test the effect of window size and overlap on the signal-to-noise ratio and the adaptive allele detectability, a new, extended Snakemake pipeline was constructed. The new pipeline supports two modes, regular and interactive, specifiable in the configfile. The regular mode produces a single FST visualization with user-defined windows and is thus identical to the standard pipeline. The interactive pipeline, on the other hand, launches an interactive R shiny application, enabling the interactive and real-time FST visualization. A detailed readme describing how the run the extended pipeline is located in the folder alongside the rules and scripts.
- [Non-Sliding-Window Feature Vector Table Pipeline:](https://github.com/TheNeuvillette/Research_Project/tree/main/Non_Sliding_Window_Feature_Vector_Table_Pipeline) Pipeline transforming the simulation data into a machine-learning-ready feature vector table enabling outlier detection of locally adapted alleles. Creates a feature vector table of non-overlapping windows.
- [Sliding-Window Feature Vector Table Pipeline:](https://github.com/TheNeuvillette/Research_Project/tree/main/Sliding_Window_Feature_Vector_Table_Pipeline) Similar to the previous pipeline, creates a feature vector table from the simulated VCF files. This pipeline instead creates a table of sliding windows, where we simply advance by a certain number of subwindows before generating a new window.

To verify correct implementation and to assess whether the feature vectors can distinguish between selected and neutral windows prior to model training, a [Jupiter Notebook script](https://github.com/TheNeuvillette/Research_Project/blob/main/Feature_Vector_Table_Testing_and_Visualization.ipynb) for several standard exploratory data visualizations was created.

## Software, Tools and Dependencies
- Snakemake: Version 6.6.1
- Anaconda3: Version 2022.05
- Python: Version 3.9.12 on HPC cluster - Used to run all python scripts in pipelines 
- Python: Version 3.11.7 locally - Used to run “Feature_Vector_Table_Testing_and_Visualization”
- R: Version 4.2.1
- BCFtools: Version 1.12
- VCFtools: Version 0.1.16

### R Libraries:
- Ggplot2: Version 3.3.6 
- Shiny: Version 1.7.1 
- Data.table: Version 1.14.2

### Python Libraries:
- Argparse: Version 1.1 
- Ast: Version 3.9.12 
- NumPy: Version 1.20.3 on HPC cluster 
- NumPy: Version 1.26.4 locally 
- Pandas: Version 1.2.4 on HPC cluster 
- Pandas: Version 2.1.4 locally 
- Matplotlib: Version 3.10.1 
- Seaborn: Version 0.12.2 
- Scikit-learn: Version 1.2.2 
