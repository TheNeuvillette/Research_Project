# Snakemake rule calling the corresponding R script visualizing Fst patterns across the chromosome.

rule plot_Fst:
    input:
        in_file = rules.vcf_Fst.output.output2
        
    output:
        png=expand("results/{data_type}/{folder_name}/{sim_name}/plots/{sim_name}_combined_{generations}_{sim_no}_Fst_Wsize_{window_size}_Wstep_{window_step}.png",
            folder_name=config["folder_name"], data_type=config["data_type"], generations=config["generations"], sim_name=config["sim_name"], sim_no=config["sim_no"], window_size=config["window_size"], window_step=config["window_step"]),
        pdf=expand("results/{data_type}/{folder_name}/{sim_name}/plots/{sim_name}_combined_{generations}_{sim_no}_Fst_Wsize_{window_size}_Wstep_{window_step}.pdf",
            folder_name=config["folder_name"], data_type=config["data_type"], generations=config["generations"], sim_name=config["sim_name"], sim_no=config["sim_no"], window_size=config["window_size"], window_step=config["window_step"])

    params:
        sim_name=config["sim_name"],
        sim_no=config["sim_no"],
        window_size=config["window_size"],
        window_step=config["window_step"],
        outdir="results/{data_type}/{folder_name}/{sim_name}/plots".format(
            data_type=config["data_type"], folder_name=config["folder_name"], sim_name=config["sim_name"])

    shell:
        # Run the corresponding R script to plot the Fst. Pass the window size & step alongside other params for output file naming.
        """
        Rscript --no-save scripts/plot_Fst_regular.R {input.in_file} {params.sim_name} {params.sim_no} {params.outdir} {params.window_size} {params.window_step}
        """