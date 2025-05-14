process STARFUSION_PROCESS_BAM {
    tag "$meta.id"
    label 'process_medium'

		publishDir "${params.outdir}/analysis/${meta.id}/starfusion/", mode: 'copy'

		conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bedtools:2.31.1--hf5e1c6e_0' :
        'biocontainers/bedtools:2.31.1--hf5e1c6e_0' }"

    input:
    tuple val(meta), path(tsv)
    tuple val(meta), path(bam)
		path reference

    output:
    tuple val(meta), path("*starfusion.bam"), emit: starfusion_bam
    //path  "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
		"""
		awk -F'\\t' '
				NR==1 {next}
				{
						split(\$8 , a, ":");
						split(\$10, b, ":");
						printf "%s\\t%d\\t%d\\n", a[1], a[2], a[2]+1
						printf "%s\\t%d\\t%d\\n", b[1], b[2], b[2]+1
				}' $tsv > ${meta.id}.starfusion.bed
		# Sort the bed file
		bedtools sort -i ${meta.id}.starfusion.bed > ${meta.id}.starfusion.sorted.bed
		# add slop to the bed file
		bedtools slop -i ${meta.id}.starfusion.sorted.bed -g $reference/ref_genome.fa.fai -b 1000 > ${meta.id}.starfusion.sorted.slop.bed
		# intersect the sorted bed file with the bam file
		bedtools intersect -a $bam -b ${meta.id}.starfusion.sorted.slop.bed > ${meta.id}.starfusion.bam
		# get versions
		cat <<-END_VERSIONS > versions.yml
		"${task.process}":
				bedtools: \$(echo \$(bedtools --version 2>&1) | sed 's/^.*bedtools //; s/Using.*\$//')
		END_VERSIONS
		"""
}