process MINIMAP2_ALIGN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:1679e915ddb9d6b4abda91880c4b48857d471bd8-0' :
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:1679e915ddb9d6b4abda91880c4b48857d471bd8-0' }"

    input:
    tuple val(meta), path(reads), path(reference)
    val bam_format
    val cigar_paf_format
    val cigar_bam

    output:
    tuple val(meta), path(reads), path(reference), path("*.paf"), optional: true, emit: paf
    tuple val(meta), path(reads), path(reference), path("*.bam"), optional: true, emit: bam
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bam_output = bam_format ? "-a | samtools sort | samtools view -@ ${task.cpus} -b -h -o ${prefix}.bam" : "-o ${prefix}.paf"
    def cigar_paf = cigar_paf_format && !bam_format ? "-c" : ''
    def set_cigar_bam = cigar_bam && bam_format ? "-L" : ''
    def use_gpu = task.ext.use_parabricks_gpu ?: false

    if (use_gpu) {
        // GPU-accelerated version using NVIDIA Parabricks
        // Note: Parabricks minimap2 outputs BAM format by default
        def pb_args = task.ext.parabricks_args ?: ''
        """
        pbrun minimap2 \\
            --ref ${reference ?: reads} \\
            --in-fq $reads \\
            --out-bam ${prefix}.bam \\
            --num-gpus 1 \\
            --num-threads ${task.cpus} \\
            $pb_args \\
            $args

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            parabricks: \$(pbrun version | grep "Please" | sed 's/.*version //')
            minimap2: GPU-accelerated via Parabricks
        END_VERSIONS
        """
    } else {
        // Standard CPU version
        """
        minimap2 \\
            $args \\
            -t $task.cpus \\
            "${reference ?: reads}" \\
            "$reads" \\
            $cigar_paf \\
            $set_cigar_bam \\
            $bam_output

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            minimap2: \$(minimap2 --version 2>&1)
        END_VERSIONS
        """
    }
}
