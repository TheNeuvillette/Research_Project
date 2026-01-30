# Snakemake rule calling the corresponding R script visualizing Fst patterns across the chromosome.
# Depending on the mode, either the regular or the interactive R script are called.

# The input and output of this script depends on the mode:
# The regular mode calculates a sliding window Fst using the user-defined window_size and window_step (input)
#     which is then visualized in the plot_Fst R script (output).
# The interactive mode calculates the per-site Fst (input) which is visualized in an interactive shiny app.
#     For the snakemake logic to run this script and in turn run the R shiny app, the script requires an output.
#     This output is a simple text file telling that the R shiny setup is complete (output).

if config["mode"] == "regular":
    in_file = rules.vcf_Fst.output.output2
    plot_outputs = {
        "png":f"results/{config['data_type']}/{config['folder_name']}/{config['sim_name']}/plots/{config['sim_name']}_combined_{config['generations']}_{config['sim_no']}_Fst_Wsize_{config['window_size']}_Wstep_{config['window_step']}.png",
        "pdf":f"results/{config['data_type']}/{config['folder_name']}/{config['sim_name']}/plots/{config['sim_name']}_combined_{config['generations']}_{config['sim_no']}_Fst_Wsize_{config['window_size']}_Wstep_{config['window_step']}.pdf"
    }
else:
    in_file = rules.vcf_Fst.output.output2
    plot_outputs = {
        "interactive_shiny": f"results/{config['data_type']}/{config['folder_name']}/{config['sim_name']}/plots/{config['sim_name']}_combined_{config['generations']}_{config['sim_no']}_interactive_shiny_launch.txt"
    }

rule plot_Fst:
    input:
        in_file=in_file

    output:
        list(plot_outputs.values())  # flat list required for DAG

    params:
        sim_name=config["sim_name"],
        sim_no=config["sim_no"],
        window_size=config["window_size"],
        window_step=config["window_step"],
        mode=config["mode"],
        outdir=f"results/{config['data_type']}/{config['folder_name']}/{config['sim_name']}/plots"

    shell:
        """
        # The called R script depends on the mode specified in the configfile:
        if [ "{params.mode}" = "regular" ]; then
            # Run the corresponding R script to plot the Fst. Pass the window size & step alongside other params for output file naming.
            Rscript --no-save scripts/plot_Fst_regular.R {input.in_file} {params.sim_name} {params.sim_no} {params.outdir} {params.window_size} {params.window_step}
        else
            # Create the output text file:
            echo "Starting Shiny app..." > {output}
            # Run the interactive R script to launch the R shiny app:
            Rscript --no-save scripts/plot_Fst_interactive.R {input.in_file}
        fi
        """