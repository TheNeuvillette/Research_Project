rule build_feature_vector_table:
    input:
        fst_file = rules.vcf_Fst.output.output2
    output:
        csv=expand("results/{data_type}/{folder_name}/{sim_name}/feature_vector_table/{sim_name}_combined_{generations}_{sim_no}_feature_vector_table_{subwindow_size}bp_subwindows.csv", 
                  folder_name=config["folder_name"], data_type=config["data_type"], generations=config["generations"], sim_name=config["sim_name"], sim_no=config["sim_no"], subwindow_size=config["subwindow_size"])
    params:
        subwindow_size = config["subwindow_size"],
        selected_sites = str(config["selected_sites"]),
        outdir="results/{data_type}/{folder_name}/{sim_name}/feature_vector_table".format(
            data_type=config["data_type"], folder_name=config["folder_name"], sim_name=config["sim_name"])
    shell:
        """
        mkdir -p {params.outdir}

        python scripts/build_feature_vector_table.py \
            --fst {input.fst_file} \
            --output {output.csv} \
            --subwindow {params.subwindow_size} \
            --selected "{params.selected_sites}"
        """