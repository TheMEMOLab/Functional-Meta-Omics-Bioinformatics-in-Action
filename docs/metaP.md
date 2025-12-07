---
layout: default
title: Metagenomics-pipeline
prev: MetaG.html
---
{% include navbar.html %}

<link rel="stylesheet" href="assets/css/callouts.css">

# Functional omics (Metaproteomics)

## Clasic environmental metaproteomics protocols.

![METAPPRO](images/metaPPipeline.jpg)

## FragPipe: Proteomics quantification.

What is [FragPipe](https://github.com/Nesvilab/FragPipe): *"FragPipe is a comprehensive computational platform designed for the analysis of mass spectrometry-based proteomics data. It includes a Graphical User Interface and pipeline wrapper code (FragPipe-GUI), distributed alongside various independent software tools and workflow files. FragPipe can be run using GUI or in the command line mode, on Windows, Linux, or in the cloud environment. It is powered by MSFragger - an ultrafast proteomic search engine suitable for both conventional and "open" (wide precursor mass tolerance) peptide identification."*  

### Using FragPipe in SAGA:

To use the FragPipe GUI for configuration we should login SAGA activating the X11 (graphics) by the following command:

```bash
ssh -YX auve@saga.sigma2.no
```

<div class="callout callout-important">
  <div class="callout-title">⚠️ Important</div>
  FragPipe GUI can only run in the login-node
</div>

Then activate the conda environment:

```bash
module load Anaconda3/2022.10
eval "$(conda shell.bash hook)"
conda activate /cluster/projects/nn9987k/.share/conda_environments/FragPipe/
```
Then run the fragPipe

```
fragpipe
```

The following will be displayed:

![FRAGPIPE](images/fragpipe.png)


## Running FragPipe in Headless mode (idealy for HPC)

Let's run FragPipe in CLI to check and understand what is happening in each step.

1) As this process will take some time, the best is to run everything in a interactive virtual terminal to keep our job alive. So let's ask for a [TMUX](https://github.com/tmux/tmux/wiki) session:

```bash
tmux new -s FRAGPIPE
```

<div class="callout callout-important">
  <div class="callout-title">⚠️ Important</div>
  The TMUX virtual terminal will be running in the login node you are connected not in others.
</div>

2) Ask for an interactive Job

```bash
bash /cluster/projects/nn9987k/UiO_BW_2025/HPC101/SLURM/srun.prarameters.Nonode.Account.sh 14 88G normal,bigmem,hugemem 120G nn9987k 08:00:00
```

<div class="callout callout-warning">
  <div class="callout-title">🚨 Warning</div>
  Running FragPipe requires a lot of resources (RAM and CPUs) plan accordingly
</div>


3) Copy the TimsTOF files (.d) and the database to the $LOCALSCRATCH

```bash

```





