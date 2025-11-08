# LOMA Profiles - Quick Reference Guide

## Profile Selection Cheat Sheet

```bash
# RTX 4070 Workstation (22 cores, 64GB RAM, RTX 4070 GPU)
nextflow run main.nf -profile rtx4070 --input samples.csv --MEDAKA.args "-d 0"

# DGX A100 Station (128 cores, 512GB RAM, 4x A100 GPUs)
nextflow run main.nf -profile dgx_a100 --input samples.csv --MEDAKA.args "-d 0"

# Slurm HPC (CPU only)
nextflow run main.nf -profile slurm --input samples.csv

# Slurm HPC with GPU
nextflow run main.nf -profile slurm_gpu --input samples.csv --MEDAKA.args "-d 0"

# Standard execution (default)
nextflow run main.nf -profile standard --input samples.csv
```

## Profile Comparison

| Profile | Executor | Max CPUs | Max Memory | GPU Support | Best For |
|---------|----------|----------|------------|-------------|----------|
| `rtx4070` | local | 20 | 60 GB | Yes (1x RTX 4070) | Workstation, 1-4 samples |
| `dgx_a100` | local | 120 | 480 GB | Yes (4x A100) | High-throughput, 10+ samples |
| `slurm` | slurm | 128 | 500 GB | No | HPC cluster, CPU-only |
| `slurm_gpu` | slurm | 128 | 500 GB | Yes (configurable) | HPC cluster with GPUs |
| `standard` | local | 46 | 75 GB | No | General-purpose |

## GPU Acceleration Quick Tips

### GPU-Accelerated Tools

**Medaka** (Consensus Polishing):
```bash
# Enable GPU for Medaka
--MEDAKA.args "-d 0"

# Check GPU availability
nvidia-smi
```

**minimap2** (Read Alignment via Parabricks):
```bash
# Enabled by default on GPU profiles (rtx4070, dgx_a100, slurm_gpu)
# To disable if Parabricks not available:
--use_parabricks false

# Use custom Parabricks container:
--parabricks_container "your/parabricks:version"
```

### Expected Performance Gains

| Tool | RTX 4070 | A100 |
|------|----------|------|
| Medaka | 2-4x | 5-10x |
| minimap2 (Parabricks) | 3-5x | 5-8x |

### Parabricks Quick Setup

**Note**: Parabricks requires NVIDIA licensing.

```bash
# 1. Pull Parabricks container
singularity pull docker://nvcr.io/nvidia/clara/clara-parabricks:4.3.2-1

# 2. Test it works
singularity exec --nv parabricks.sif pbrun version

# 3. Run with Parabricks enabled (default)
nextflow run main.nf -profile rtx4070 --input samples.csv

# 4. Run without Parabricks
nextflow run main.nf -profile rtx4070 --input samples.csv --use_parabricks false
```

## Resource Tuning

### Adjust Max Resources
```bash
# Customize CPU limit
--max_cpus 64

# Customize memory limit
--max_memory 256.GB

# Customize time limit
--max_time 72.h
```

### Process-Specific Tuning
Create a custom config file `my_config.config`:

```groovy
process {
    withLabel:process_high {
        cpus = 32
        memory = 128.GB
    }
}
```

Use it:
```bash
nextflow run main.nf -profile dgx_a100 -c my_config.config --input samples.csv
```

## Common Issues & Solutions

### Issue: GPU not detected
**Solution**: Verify NVIDIA drivers and Singularity GPU support
```bash
nvidia-smi
singularity exec --nv docker://nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### Issue: Out of memory
**Solution**: Reduce parallel samples or increase max_memory
```bash
nextflow run main.nf -profile dgx_a100 --max_memory 480.GB --input samples.csv
```

### Issue: Slurm jobs not submitting
**Solution**: Check queue name and cluster options
```bash
# Verify queue exists
sinfo

# Modify queue in custom config
process.queue = 'your_partition_name'
```

## Performance Optimization

### RTX 4070 System
- Process 1-2 samples in parallel
- Always enable GPU for Medaka: `--MEDAKA.args "-d 0"`
- Monitor with: `htop` and `nvidia-smi`

### DGX A100 System
- Process 4-8 samples in parallel
- Enable GPU: `--MEDAKA.args "-d 0"`
- Use multiple GPUs for multiple samples (manual job distribution)
- Monitor with: `htop` and `nvidia-smi -l 1`

### Slurm HPC
- Let Nextflow manage job submission
- Adjust `--max_time` based on cluster walltime limits
- Use `slurm_gpu` profile if GPU nodes available
- Check job status: `squeue -u $USER`

## Workflow Efficiency Tips

1. **Skip unnecessary steps**:
   ```bash
   --skip_assembly          # Skip assembly steps
   --skip_taxonomic_profiling  # Skip taxonomy
   --skip_bacterial_typing  # Skip typing
   ```

2. **Use cached results**:
   ```bash
   -resume  # Resume from last checkpoint
   ```

3. **Optimize I/O**:
   - Use fast local storage for work directory
   - Keep input data on fast storage (SSD/NVMe)

4. **Monitor resources**:
   ```bash
   # Monitor CPU/Memory
   htop

   # Monitor GPU
   nvidia-smi -l 1

   # Monitor Nextflow progress
   nextflow log
   ```

## Example Workflows

### Single Sample on RTX 4070
```bash
nextflow run main.nf \
  -profile rtx4070 \
  --input single_sample.csv \
  --MEDAKA.args "-d 0" \
  -resume
```

### Batch Processing on DGX A100
```bash
nextflow run main.nf \
  -profile dgx_a100 \
  --input batch_samples.csv \
  --MEDAKA.args "-d 0" \
  -resume \
  -qs 4  # Process 4 samples in parallel
```

### HPC Cluster Execution
```bash
nextflow run main.nf \
  -profile slurm \
  --input large_batch.csv \
  --max_cpus 64 \
  --max_memory 256.GB \
  --max_time 72.h \
  -resume
```

### HPC with GPU Nodes
```bash
nextflow run main.nf \
  -profile slurm_gpu \
  --input samples.csv \
  --MEDAKA.args "-d 0" \
  -resume
```

## Getting Help

For detailed documentation, see: `docs/PROFILES.md`

For issues, visit: https://github.com/your-repo/LOMA-mod/issues
