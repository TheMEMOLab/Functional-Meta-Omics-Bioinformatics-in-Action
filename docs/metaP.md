---
layout: default
title: Metaproteomics (metaP)
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

### Preparing Files: 

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
cd $LOCALSCRATCH
rsync -aPhLv /cluster/projects/nn9987k/UiO_BW_2025/metaP/ToyData/TimsTOFData .
rsync -aPhLv /cluster/projects/nn9987k/UiO_BW_2025/metaP/ToyData/Database .
```

We should end with something like: 

<div style="background:#f3f3f3; padding:12px 16px; border-left:6px solid #34db66ff; border-radius:6px;">
<b>💻 Console output:</b>

<pre><code>


tree -d -L 2
.
├── Database
└── TimsTOFData
    ├── 20220302_B10_Slot1-22_1_1607.d
    ├── 20220302_B2_Slot1-14_1_1599.d
    └── 20220302_B4_Slot1-16_1_1601.d

6 directories


</code></pre>
</div>

4) FragPipe require a ["Experimental Manifest"](https://fragpipe.nesvilab.org/docs/tutorial_fragpipe.html) where the .d files are correlated with a experimental type, replicates and so:


```bash
rsync -aPLhv /cluster/projects/nn9987k/UiO_BW_2025/metaP/ToyData/ManifestCtr.tsv .
```

It looks like this:

<div style="background:#f3f3f3; padding:12px 16px; border-left:6px solid #34db66ff; border-radius:6px;">
<b>💻 Console output:</b>

<pre><code>

20220302_B10_Slot1-22_1_1607.d  Ctr     1
20220302_B2_Slot1-14_1_1599.d   Ctr     2
20220302_B4_Slot1-16_1_1601.d   Ctr     3

</code></pre>
</div>


5) Activate the conda environment:

```bash
module load Anaconda3/2022.10
eval "$(conda shell.bash hook)"
conda activate /cluster/projects/nn9987k/.share/conda_environments/FragPipe/

```

### Running configuration of Database and manifests:

Before running FragPipe in Headlss mode the database and workflow should be modify:

Modify the database adding decoys with Philosopher:

```bash
cd $LOCALSCRATCH
echo "Preparing workspace ..."

time philosopher workspace \
--nocheck \
--clean


time philosopher workspace \
--nocheck \
--init
```


Then add decoys to the database:

```bash

time philosopher database \
--custom Database/MGA.v.1.0.S.salar.STX.total.prot.faa \
--contam

```

We can compare the number of sequences in the DB before and after adding decoys:

```bash
DB="Database/MGA.v.1.0.S.salar.STX.total.prot.faa"

# Count sequences in original DB
seqs=$(grep -c "^>" "$DB")
echo "Original DB: $seqs sequences"

# Your modified database (.fas)
datamod=$(ls *.fas)
seqsfas=$(grep -c "^>" "$datamod")
echo "Modified DB: $seqsfas sequences"

# Difference (new sequences added)
added=$(( seqsfas - seqs ))
echo "Number of sequences added: $added"

```

<div style="background:#f3f3f3; padding:12px 16px; border-left:6px solid #34db66ff; border-radius:6px;">
<b>💻 Console output:</b>

<pre><code>


Original DB: 430759 sequences
Modified DB: 861754 sequences
Number of sequences added: 430995

</code></pre>
</div>


Now we can clean the workspace:

```bash
Cleaning workspace

echo "Cleaning workspace..."

time philosopher workspace \
--nocheck \
--clean
```

### Modifying the Workflow:

Fragpipe needs that the information on where and what is the database is given in a workflow. This is usually done in the GUI, but as CLI should be done manually. The following script does that:

```bash
echo "copy workflow template"
time rsync -avhL /cluster/projects/nn9987K/shared/condaenvironments/FragPipe/git/fragpipe-23.1/workflows/LFQ-MBR.TimsTOF.workflow.edit.workflow .
time editmanifestAndWorkflow.pl \
TimsTOFData \
ManifestCtr.tsv \
LFQ-MBR.TimsTOF.workflow.edit.workflow \
$datamod
time fragpipe \
--headless \
--workflow LFQ-MBR.workflow \
--manifest ManifestCtr.tsv.manifest.FragPipe.fp-manifest \
--workdir $LOCALSCRATCH \
--ram 80 \
--threads $SLURM_CPUS_ON_NODE
```
