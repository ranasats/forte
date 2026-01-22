process TARGET_DMP_QC {
    tag "target_dmp_qc"
    container "/research/huynhn3/projects/target_qc/forte/modules/local/target_dmp_qc/target-qc.sif"
    publishDir "${params.outdir}/target_dmp_qc", mode: 'copy'
    stageInMode 'copy'

    input:
      path target_dmp_qc_rmd
      path(sample_dirs)

    output:
      path "TARGET_QC_report.html", emit: html_report

    shell:
    def r_vec = sample_dirs.collect { "'${it}'" }.join(',')
    """
    Rscript -e 'rmarkdown::render(
      "${target_dmp_qc_rmd}",
      output_file="TARGET_QC_report.html",
      params=list(sample_dirs=c(${r_vec}))
    )'
    """
}
