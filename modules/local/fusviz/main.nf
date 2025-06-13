process FUSVIZ {
    tag "$meta.patient_id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://blancojmskcc/fusviz:1.2.2':
        'blancojmskcc/fusviz:1.2.2' }"

    input:
    path(gtf)
    path(cytobands)
    path(protein_domains)
    tuple val(meta),  path(tsv)
    tuple val(meta2), path(bam), path(bai)

    output:
    tuple val(meta), path("*.pdf"), emit: pdf
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.patient_id}"
    """
    preFusViz \\
        --input ${tsv}   \\
        --sample ${prefix} \\
        --annotations ${gtf} \\
        ${args}

    FusViz \\
        --alignments=${bam} \\
        --annotation=${gtf}   \\
        --cytobands=${cytobands} \\
        --output=${prefix}_FusViz.pdf \\
        --fusions=${prefix}_FusViz.tsv \\
        --transcriptSelection=canonical \\
        --minConfidenceForCircosPlot=High \\
        --proteinDomains=${protein_domains} \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fusviz: "1.2.2"
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.patient_id}"
    """
    touch ${prefix}_FusViz.pdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fusviz: "1.2.2"
    END_VERSIONS
    """
}
