process FREYJA_VARIANTS {
    tag "$meta.id"
    label 'process_medium'


    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/f0/f0b023f9c9e25f338d72ed6710e4d2a54a4c3a9a3ac34f17e08683894dc40830/data' :
        'community.wave.seqera.io/library/freyja:2.0.6--be3cbd6f14f9d542' }"

    input:
    tuple val(meta), path(bam)
    path fasta
    path fai

    output:
    tuple val(meta), path("*.variants.tsv"), path("*.depth.tsv"), emit: variants
    path "versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    freyja \\
        variants \\
        $args \\
        --ref $fasta \\
        --variants ${prefix}.variants.tsv \\
        --depths ${prefix}.depth.tsv \\
        $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freyja: \$(echo \$(freyja --version 2>&1) | sed 's/^.*version //' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.variants.tsv
    touch ${prefix}.depth.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freyja: \$(echo \$(freyja --version 2>&1) | sed 's/^.*version //' )
    END_VERSIONS
    """
}
