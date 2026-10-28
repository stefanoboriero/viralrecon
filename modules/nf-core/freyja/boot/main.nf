process FREYJA_BOOT {
    tag "$meta.id"
    label 'process_high'


    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/f0/f0b023f9c9e25f338d72ed6710e4d2a54a4c3a9a3ac34f17e08683894dc40830/data' :
        'community.wave.seqera.io/library/freyja:2.0.6--be3cbd6f14f9d542' }"

    input:
    tuple val(meta), path(variants), path(depths)
    val repeats
    path barcodes
    path lineages_meta
    path lineages_topology

    output:
    tuple val(meta), path("*lineages.csv")  , emit: lineages
    tuple val(meta), path("*summarized.csv"), emit: summarized
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def lineage_cmd = lineages_topology ? "--lineageyml $lineages_topology" : ''
    """
    freyja \\
        boot \\
        $args \\
        --nt $task.cpus \\
        --nb $repeats \\
        --output_base $prefix \\
        --barcodes $barcodes \\
        --meta $lineages_meta \\
        $lineage_cmd \\
        $variants \\
        $depths

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freyja: \$(echo \$(freyja --version 2>&1) | sed 's/^.*version //' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_lineage.csv
    touch ${prefix}_summarized.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freyja: \$(echo \$(freyja --version 2>&1) | sed 's/^.*version //' )
    END_VERSIONS
    """
}
