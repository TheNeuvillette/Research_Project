# The Fst calculation is performed slightly diffrently depending on the mode.
# The regular mode performs a sliding window Weir and Cockerham Fst calculation using the user-defined window and step,
#     which is then visualized in the plot_Fst R script.
# The interactive mode cannot run VCFtools in the interactive R shiny app for an interactive and real-time 
#     sliding window Weir and Cockerham Fst calculation which is then visualized. Instead, a two-step approach is required,
#     where the per-site Fst is calculated using VCFtools in this rule, while the interactive windowed Fst is calculated
#     in the R script by calculating the the arithmetic mean of the per-site Fst.

# The output of this script depends on the mode:
# The regular mode calculates a sliding window Fst using the user-defined window_size and window_step.
# The interactive mode calculates the per-site Fst.

if config["mode"] == "regular":
    output_files = {
        "output1": [
            f"results/{config['data_type']}/{config['folder_name']}/{config['sim_name']}/Fst_vcf/{config['sim_name']}_p1_{config['generations']}_{config['sim_no']}_mod.txt",
            f"results/{config['data_type']}/{config['folder_name']}/{config['sim_name']}/Fst_vcf/{config['sim_name']}_p2_{config['generations']}_{config['sim_no']}_mod.txt"
        ],
        "output2": f"results/{config['data_type']}/{config['folder_name']}/{config['sim_name']}/Fst_vcf/{config['sim_name']}_combined_{config['generations']}_{config['sim_no']}_mod_Fst_Wsize_{config['window_size']}_Wstep_{config['window_step']}.windowed.weir.fst"
    }
else:
    output_files = {
        "output1": [
            f"results/{config['data_type']}/{config['folder_name']}/{config['sim_name']}/Fst_vcf/{config['sim_name']}_p1_{config['generations']}_{config['sim_no']}_mod.txt",
            f"results/{config['data_type']}/{config['folder_name']}/{config['sim_name']}/Fst_vcf/{config['sim_name']}_p2_{config['generations']}_{config['sim_no']}_mod.txt"
        ],
        "output2": f"results/{config['data_type']}/{config['folder_name']}/{config['sim_name']}/Fst_vcf/{config['sim_name']}_combined_{config['generations']}_{config['sim_no']}_mod_Fst_per_site.weir.fst"
    }

rule vcf_Fst:
    input:
        # Note that when the rule you refer to defines multiple output files but you want to require only a subset of those as input for another rule, 
        # you should name the output files and refer to them specifically:
        in_file = rules.modify_vcf.output.output4
    output:
        output1 = list(output_files["output1"]),
        output2 = output_files["output2"]

    params:
        folder_name = config["folder_name"],
        data_type = config["data_type"],
        generations = config["generations"],
        sim_name = config["sim_name"],
        sim_no = config["sim_no"],
        window_size=config["window_size"],
        window_step=config["window_step"],
        mode=config["mode"],
        results_path_fst = "results/{data_type}/{folder_name}/{sim_name}/Fst_vcf".format(
            data_type=config["data_type"], folder_name=config["folder_name"], sim_name=config["sim_name"])

    resources:
        mem_mb=32000,   # Memory requirement in megabytes
        threads=5,      # Number of threads to use
        disk_mb=100000, # Disk space requirement in megabytes
        runtime=180     # Maximum runtime in minutes (3 hours)

    shell:
        """
        # Load required modules
        module load BCFtools/1.12-GCC-10.3.0    
        module load VCFtools/0.1.16-GCC-10.3.0

        # Extract the input file 
        input_file={input.in_file} 

        # Create population files 
        # Define filenames for the poputalion files
        filename1=$(echo "$input_file" |sed 's/\\.vcf$/.txt/'|sed 's/_combined_/_p1_/g' | xargs -n 1 basename)
        filename2=$(echo "$input_file" |sed 's/\\.vcf$/.txt/'|sed 's/_combined_/_p2_/g' | xargs -n 1 basename)

        # Create population files for Fst calculation
        bcftools query -l "$input_file" | grep "_1" > "{params.results_path_fst}/$filename1"
        bcftools query -l "$input_file" | grep "_2" > "{params.results_path_fst}/$filename2"
               
        # In case we have the regular mode:
        # Calculate sliding window Fst with vcftools, using user-defined window size and step via the configfile.
        if [ "{params.mode}" = "regular" ]; then

            # Define filename for the output
            # We add the window size and step to the filename to easily do multiple pipeline runs with diffrent window size and step.
            filename3=$(echo "$input_file" |sed 's/\\.vcf$//'| xargs -n 1 basename)_Fst_Wsize_{params.window_size}_Wstep_{params.window_step}

            vcftools --vcf "$input_file" \
            --weir-fst-pop "{params.results_path_fst}/$filename1" \
            --weir-fst-pop "{params.results_path_fst}/$filename2" \
            --fst-window-size {params.window_size} --fst-window-step {params.window_step} --out "{params.results_path_fst}/$filename3" 

        # In case we have the interactive mode:
        # Calculate per-site Fst with vcftools.
        else
            # Define filename for the output
            filename3=$(echo "$input_file" |sed 's/\\.vcf$/_Fst/'| xargs -n 1 basename)_per_site

            vcftools --vcf "$input_file" \
                --weir-fst-pop "{params.results_path_fst}/$filename1" \
                --weir-fst-pop "{params.results_path_fst}/$filename2" \
                --out "{params.results_path_fst}/$filename3"
        fi
        """