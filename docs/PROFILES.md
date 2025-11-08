# LOMA Execution Profiles

This document describes the various execution profiles available for the LOMA workflow, including optimized configurations for different hardware setups and HPC environments.

## Available Profiles

### Standard Profiles

#### `standard` (default)
- **Container Engine**: Singularity
- **Use Case**: General-purpose execution
- **Resource Limits**:
  - CPUs: 46
  - Memory: 75 GB
  - Time: 240 hours

#### `singularity`
- **Container Engine**: Singularity
- **Use Case**: Explicit Singularity container usage

#### `conda`
- **Container Engine**: Conda environments
- **Use Case**: Systems without container support

#### `mamba`
- **Container Engine**: Conda with Mamba solver
- **Use Case**: Faster environment resolution than standard Conda

#### `apptainer`
- **Container Engine**: Apptainer (Singularity replacement)
- **Use Case**: Systems using Apptainer instead of Singularity

---

## HPC and Optimized Profiles

### `slurm` - Slurm HPC Cluster Profile

**Optimized for**: HPC clusters using Slurm workload manager

**Configuration**:
- **Executor**: Slurm
- **Queue**: normal (customize with `process.queue`)
- **Container Engine**: Singularity
- **Max Resources**:
  - CPUs: 128
  - Memory: 500 GB
  - Time: 168 hours (7 days)
- **Error Handling**: Automatic retry for cluster-specific exit codes
- **Max Retries**: 2

**Usage**:
```bash
nextflow run main.nf -profile slurm --input samples.csv
```

**Customization**:
You can customize the Slurm queue and options:
```bash
nextflow run main.nf -profile slurm \
  --input samples.csv \
  --max-cpus 64 \
  --max-memory 256.GB
```

**Cluster Options**:
To specify additional Slurm options, modify the profile or use process-specific directives.

---

### `slurm_gpu` - Slurm with GPU Support

**Optimized for**: HPC clusters with GPU nodes

**Configuration**:
- **Executor**: Slurm
- **Queue**: gpu (customize with `process.queue`)
- **GPU Allocation**: 1 GPU per job (`--gres=gpu:1`)
- **Container Engine**: Singularity with NVIDIA support (`--nv`)
- **Max Resources**:
  - CPUs: 128
  - Memory: 500 GB
  - Time: 168 hours
- **GPU Support**: Enabled for compatible processes (e.g., Medaka)

**Usage**:
```bash
nextflow run main.nf -profile slurm_gpu --input samples.csv
```

**GPU-Accelerated Processes**:
- Medaka consensus polishing (use `-d` flag to specify GPU device)

**Custom GPU Options**:
To request specific GPU types:
```bash
# Modify process.clusterOptions in your configuration
process {
  clusterOptions = '--gres=gpu:a100:1'
}
```

---

### `rtx4070` - RTX 4070 Ultra Workstation Profile

**Optimized for**: NVIDIA RTX 4070 Ultra workstation with Core i9

**Hardware Specifications**:
- **CPU**: 22 cores (Intel Core i9)
- **Memory**: 64 GB RAM
- **GPU**: 1x NVIDIA RTX 4070

**Configuration**:
- **Container Engine**: Singularity with NVIDIA support (`--nv`)
- **Max Resources**:
  - CPUs: 20 (leaves 2 for system)
  - Memory: 60 GB (leaves 4 GB for system)
  - Time: 240 hours
- **GPU Support**: Enabled for compatible processes

**Usage**:
```bash
nextflow run main.nf -profile rtx4070 --input samples.csv
```

**GPU Acceleration**:
To enable GPU acceleration for Medaka:
```bash
nextflow run main.nf -profile rtx4070 \
  --input samples.csv \
  --MEDAKA.args "-d 0"  # Use GPU device 0
```

**Performance Notes**:
- Medaka GPU acceleration can provide 2-5x speedup
- Optimal for small to medium-sized datasets
- Best suited for 1-4 samples processed in parallel

---

### `dgx_a100` - NVIDIA DGX Station A100 Profile

**Optimized for**: NVIDIA DGX Station A100 high-performance workstation

**Hardware Specifications**:
- **CPU**: 128 cores
- **Memory**: 512 GB RAM
- **GPU**: 4x NVIDIA A100 GPUs (40GB or 80GB each)

**Configuration**:
- **Container Engine**: Singularity with NVIDIA support (`--nv`)
- **Max Resources**:
  - CPUs: 120 (leaves 8 for system)
  - Memory: 480 GB (leaves 32 GB for system)
  - Time: 240 hours
- **GPU Support**: Enabled for compatible processes

**Optimized Process Resources**:
| Label | CPUs | Memory | Time |
|-------|------|--------|------|
| process_single | 2 | 12 GB | 4 h |
| process_low | 4 | 24 GB | 4 h |
| process_medium | 24 | 64 GB | 8 h |
| process_high | 60 | 200 GB | 16 h |
| process_long | - | - | 48 h |
| process_gpu | 8 | 48 GB | 8 h |

**Usage**:
```bash
nextflow run main.nf -profile dgx_a100 --input samples.csv
```

**GPU Acceleration**:
```bash
nextflow run main.nf -profile dgx_a100 \
  --input samples.csv \
  --MEDAKA.args "-d 0"  # Use GPU device 0
```

**Performance Notes**:
- Designed for maximum throughput on large datasets
- Can process multiple samples in parallel efficiently
- Best suited for batch processing 10+ samples
- GPU acceleration on A100 can provide 5-10x speedup for Medaka

**Parallel Execution**:
The DGX A100 profile is optimized for parallel sample processing:
```bash
# Process 4 samples in parallel, each using different resources
nextflow run main.nf -profile dgx_a100 \
  --input samples.csv \
  -qs 4  # Queue size for parallel execution
```

---

## GPU Acceleration

### Supported Tools

Currently, GPU acceleration is supported for:

1. **Medaka** - Consensus sequence polishing
   - Supports NVIDIA GPUs via CUDA
   - Requires GPU-enabled profile (`rtx4070`, `dgx_a100`, `slurm_gpu`)
   - Enable with: `--MEDAKA.args "-d 0"` (where 0 is the GPU device ID)

### GPU-Enabled Profiles

The following profiles have GPU support enabled:
- `rtx4070`
- `dgx_a100`
- `slurm_gpu`

### Future GPU Acceleration

The following tools have potential for GPU acceleration but require additional container/tool modifications:

- **Kraken2** - Via Kraken2-GPU (separate implementation)
- **minimap2** - Via GPU-accelerated forks
- **BLAST** - Via GPU-BLAST

Contact the development team if you need GPU support for additional tools.

---

## Resource Optimization Tips

### For RTX 4070 Systems

1. **Limit Parallel Samples**: Process 1-2 samples at a time to avoid memory contention
2. **Enable GPU for Medaka**: Always use `--MEDAKA.args "-d 0"` for faster polishing
3. **Monitor Resources**: Use `htop` and `nvidia-smi` to monitor CPU/GPU usage

### For DGX A100 Systems

1. **Maximize Parallelism**: Process 4-8 samples simultaneously
2. **GPU Distribution**: Assign different GPU devices to parallel processes
3. **Memory-Intensive Steps**: Leverage the large memory pool for assembly and binning
4. **Consider Process Grouping**: Group similar processes to optimize resource utilization

### For Slurm HPC Clusters

1. **Job Scheduling**: Let Nextflow handle job submission; don't manually submit
2. **Walltime**: Adjust `--max_time` based on cluster policies
3. **Queue Selection**: Modify `process.queue` in your custom config for specific partitions
4. **Resource Requests**: Tune `--max_cpus` and `--max_memory` to match node specifications

---

## Custom Profile Configuration

You can create custom profiles by combining existing profiles or adding your own configuration:

### Example: Custom Slurm Configuration

Create a file `custom.config`:

```groovy
profiles {
    my_cluster {
        includeConfig 'conf/profiles.config'

        process {
            executor = 'slurm'
            queue = 'my_partition'
            clusterOptions = '--account=my_account --qos=normal'
        }

        params {
            max_memory = '256.GB'
            max_cpus = 64
            max_time = '72.h'
        }
    }
}
```

Usage:
```bash
nextflow run main.nf -profile my_cluster -c custom.config --input samples.csv
```

---

## Profile Selection Guide

| System Type | Recommended Profile | Notes |
|-------------|-------------------|-------|
| RTX 4070 Workstation | `rtx4070` | Enable GPU for Medaka |
| DGX A100 Station | `dgx_a100` | Optimize for parallel processing |
| Slurm HPC (CPU only) | `slurm` | Standard HPC execution |
| Slurm HPC (with GPU) | `slurm_gpu` | Request GPU nodes |
| Generic Linux Workstation | `standard` | Default profile |
| macOS / No containers | `conda` or `mamba` | Conda-based execution |

---

## Troubleshooting

### GPU Not Detected

If GPU is not detected when using GPU-enabled profiles:

1. Verify NVIDIA drivers are installed:
   ```bash
   nvidia-smi
   ```

2. Check Singularity NVIDIA support:
   ```bash
   singularity exec --nv docker://nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
   ```

3. Ensure `--nv` flag is enabled in profile configuration

### Out of Memory Errors

If encountering OOM errors:

1. Reduce parallel sample processing (decrease `-qs`)
2. Increase `--max_memory` if system has more RAM
3. For specific processes, adjust resources in custom config

### Slurm Job Failures

If jobs fail on Slurm:

1. Check cluster-specific exit codes
2. Adjust `process.clusterOptions` for your cluster
3. Verify queue/partition names are correct
4. Check resource requests don't exceed node limits

---

## Performance Benchmarks

### Medaka GPU vs CPU Performance

Approximate speedup with GPU acceleration:

| GPU | Speedup vs CPU | Notes |
|-----|----------------|-------|
| RTX 4070 | 2-4x | Good for small genomes |
| A100 (40GB) | 5-8x | Excellent for large genomes |
| A100 (80GB) | 5-10x | Best for very large assemblies |

### DGX A100 Throughput

Estimated samples processed per day (E. coli-sized genome, full pipeline):

- **1 sample**: ~4-6 hours (with GPU)
- **4 samples parallel**: ~6-8 hours total
- **8 samples parallel**: ~10-14 hours total

---

## Additional Resources

- [Nextflow Configuration Documentation](https://www.nextflow.io/docs/latest/config.html)
- [Nextflow Executor Configuration](https://www.nextflow.io/docs/latest/executor.html)
- [Singularity GPU Support](https://sylabs.io/guides/latest/user-guide/gpu.html)

---

## Contact

For profile-specific issues or optimization requests, please open an issue on the GitHub repository.
