include { TARGET_DMP_QC as TARGET_DMP_QC_PROCESS } from '../../modules/local/target_dmp_qc/main'

workflow TARGET_DMP_QC {

    take:
    target_dmp_qc_rmd
    sample_dirs

    main:

    ch_versions = Channel.empty()

    sample_dirs_list = sample_dirs.collect()

    TARGET_DMP_QC_PROCESS(
        target_dmp_qc_rmd,
        sample_dirs_list
    )

    ch_versions = ch_versions.mix(TARGET_DMP_QC_PROCESS.out.versions)

    emit:
    html_report = TARGET_DMP_QC_PROCESS.out.html_report
    ch_versions = ch_versions
}
