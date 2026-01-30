# Define the rule with wildcards
rule modify_vcf:
    input:
        in_file = config["input_vcfs"]  # Use input VCF files
        
    output:
        output1=expand("results/{data_type}/{folder_name}/{sim_name}/vcf_mod/{sim_name}_{p}_{generations}_{sim_no}_mod.vcf.gz.tbi", 
                  folder_name=config["folder_name"], data_type=config["data_type"], generations=config["generations"], p=["p1", "p2"], sim_name=config["sim_name"], sim_no=config["sim_no"]),
        output2=expand("results/{data_type}/{folder_name}/{sim_name}/vcf_mod/{sim_name}_{p}_{generations}_{sim_no}_mod.vcf", 
                  folder_name=config["folder_name"], data_type=config["data_type"], generations=config["generations"], p=["p1", "p2"], sim_name=config["sim_name"], sim_no=config["sim_no"]),
        output3=expand("results/{data_type}/{folder_name}/{sim_name}/vcf_mod/{sim_name}_{p}_{generations}_{sim_no}_mod.vcf.gz", 
                  folder_name=config["folder_name"], data_type=config["data_type"], generations=config["generations"], p=["p1", "p2"], sim_name=config["sim_name"], sim_no=config["sim_no"]),
        output4=expand("results/{data_type}/{folder_name}/{sim_name}/vcf_mod/{sim_name}_combined_{generations}_{sim_no}_mod.vcf", 
                  folder_name=config["folder_name"], data_type=config["data_type"], generations=config["generations"], sim_name=config["sim_name"], sim_no=config["sim_no"])

    params:    
        folder_name = config["folder_name"],
        data_type=config["data_type"],
        generations=config["generations"],
        sim_name=config["sim_name"],
        sim_no=config["sim_no"],
        results_path_vcf="results/{data_type}/{folder_name}/{sim_name}/vcf_mod".format(
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

        # Extract only the VCF files
        file_vcf=$(echo {input.in_file} | tr ' ' '\n' | grep '\\.vcf$')  

        # Declare an empty string
        filenames=""
        
        # Loop through each VCF file
        for vcf_file in $file_vcf; do
            # Determine the suffix based on the file name
            if [[ $vcf_file == *p1* ]]; then
                suffix="_1"
            elif [[ $vcf_file == *p2* ]]; then
                suffix="_2"
            else
                suffix="none" 
                echo "No matching suffix for $vcf_file"
                continue
            fi

            # Define filename for the modified vcf file
            file_name=$( echo "$vcf_file"| tr ' ' '\n' | grep '\\.vcf$'| xargs -n 1 basename)
            file_name=$(echo "$file_name" |sed 's/\\.vcf$/_mod.vcf/')

            # Create the new sample IDs and reheader the VCF file
            bcftools reheader -s <(bcftools query -l "$vcf_file" | sed "s/\\$/$suffix/") -o "{params.results_path_vcf}/$file_name" "$vcf_file"

            # Compress vcf files with bgzip            
            bgzip -c "{params.results_path_vcf}/$file_name" > "{params.results_path_vcf}/$file_name.gz"

            # Index the compressed files with tabix
            tabix -p vcf "{params.results_path_vcf}/$file_name.gz"
        
            # Check if the existing filenames string is not empty
            if [ -n "$filenames" ]; then
                filenames="$filenames {params.results_path_vcf}/$file_name.gz"  # Add space before concatenating
            else
                filenames="{params.results_path_vcf}/$file_name.gz"  # Just assign the new filename if existing is empty
            fi
        done
        
        # Define filename for the output file
        filename=$(echo "$file_name" | sed 's/_p2_/_combined_/g')

        # Merge the VCF files
        bcftools merge $filenames -o "{params.results_path_vcf}/$filename"
        """