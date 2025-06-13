process FUSIONCATCHER_PROCESS_SAM {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    input:
    tuple val(meta), path(supporting_reads_zip)
    path reference

    output:
    tuple val(meta), path("*_merged.bam"), path("*_merged.bam.bai"),    emit: fc_bams
    path "versions.yml",                                                emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    # Get aligner (suffix)
    basename=\$(basename "${supporting_reads_zip}")
    suffix=\$(echo "\$basename" | sed 's/.*_\\(.*\\)\\.zip/\\1/')
    # Extract supporting reads
    supporting_reads_dir="extract_${meta.id}_\${suffix}"
    mkdir -p "\$supporting_reads_dir"
    unzip -o "${supporting_reads_zip}" -d "\$supporting_reads_dir"
    mkdir -p temp_bams
    # Process each SAM into sorted BAMs
    sam_files=\$(find "\$supporting_reads_dir" -name "*.sam" -type f)
    for sam_file in \$sam_files; do
        base_name=\$(basename "\$sam_file" .sam)
        samtools sort -O bam "\$sam_file" > "temp_bams/\${base_name}.bam"
    done
    # Merge BAMs
    output_bam="${meta.id}_\${suffix}_merged.bam"
    if find "temp_bams/" -maxdepth 1 -type f -name '*.bam' | read -r _; then
        samtools merge -f "\$output_bam" temp_bams/*.bam
    else
    # If no BAMs found (no called fusions), create an empty BAM with the reference genome
        cp ${reference}/genes.fa genes.fa
        samtools faidx genes.fa
        echo -e "@HD\tVN:1.6\tSO:coordinate" > empty.sam
        samtools view -b -h -T genes.fa empty.sam -o "\$output_bam"
    fi
    # Index the merged BAM
    samtools index "\$output_bam"

    rm -rf "\$supporting_reads_dir"
    rm -rf temp_bams

    # Create a versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}