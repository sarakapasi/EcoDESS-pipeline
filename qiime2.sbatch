#!/bin/bash
#SBATCH -J qiime2-EcoDESS
#SBATCH -A INSERT-HERE #change to your own charge account
#SBATCH -n 8
#SBATCH --mem=100G
#SBATCH -t24:00:00
#SBATCH -q inferno
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /storage/home/hcoda1/0/skapasi3/r-ktk3-0/EcoDESS/log/QIIME2-EcoDESS_out.16
#SBATCH -e /storage/home/hcoda1/0/skapasi3/r-ktk3-0/EcoDESS/log/QIIME2-EcoDESS_err.16

source /storage/home/hcoda1/0/skapasi3/miniconda3/etc/profile.d/conda.sh
cd /storage/home/hcoda1/0/skapasi3/r-ktk3-0/EcoDESS/1_rawdata/
conda activate qiime-2-env

qiime tools import \
  --type "SampleData[PairedEndSequencesWithQuality]" \
  --input-path EcoDESS-paired-manifest.csv \
  --output-path paired-end-demux.qza \
  --input-format PairedEndFastqManifestPhred33

qiime demux summarize \
  --i-data paired-end-demux.qza \
  --o-visualization paired-end-demux.qzv

qiime dada2 denoise-paired --i-demultiplexed-seqs paired-end-demux.qza --p-trim-left-f 11 --p-trim-left-r 11 --p-trunc-len-f 220 --p-trunc-len-r 220 --o-table table.qza --o-representative-sequences rep-seqs.qza --o-denoising-stats denoising-stats.qza --verbose

qiime feature-table summarize --i-table table.qza --o-visualization table.qzv --m-sample-metadata-file metadata-2021.tsv

qiime metadata tabulate --m-input-file denoising-stats.qza --o-visualization denoising-stats.qzv

qiime alignment mafft --i-sequences rep-seqs.qza --o-alignment aligned-rep-seqs.qza

qiime feature-table tabulate-seqs --i-data rep-seqs.qza --o-visualization rep-seqs.qzv

# 4. remove positions that are highly variable
 
qiime alignment mask --i-alignment aligned-rep-seqs.qza --o-masked-alignment masked-aligned-rep-seqs.qza
 
# 5. FastTree to generate a phylogenetic tree from the masked alignment

qiime phylogeny fasttree --i-alignment masked-aligned-rep-seqs.qza --o-tree unrooted-tree.qza

# 6. Tree midpoint rooting

qiime phylogeny midpoint-root --i-tree unrooted-tree.qza --o-rooted-tree rooted-tree.qza

# 7. Alpha and beta diversity analysis

qiime diversity core-metrics-phylogenetic --i-phylogeny rooted-tree.qza --i-table table.qza --p-sampling-depth 6900 --m-metadata-file metadata-2021.tsv --output-dir core-metrics-results

# 8. Faith Phylogenetic Diversity (community richness) and evenness metrics

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file metadata-2021.tsv \
  --o-visualization core-metrics-results/faith-pd-group-significance.qzv

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file metadata-2021.tsv \
  --o-visualization core-metrics-results/evenness-group-significance.qzv

qiime diversity alpha \
  --i-table table.qza \
  --p-metric chao1 \
  --o-alpha-diversity chao1.qza

# Export results:
# qiime tools export and import that TSV file into R: ([AlphaDiversity].qza)

qiime tools export --input-path core-metrics-results/shannon_vector.qza --output-path Shannon/
qiime tools export --input-path core-metrics-results/evenness_vector.qza --output-path Evenness/
qiime tools export --input-path core-metrics-results/faith_pd_vector.qza --output-path FaithPD/
qiime tools export --input-path core-metrics-results/observed_features_vector.qza --output-path ObservedOTUs/
qiime tools export --input-path chao1.qza --output-path Chao1/
qiime tools export --input-path core-metrics-results/bray_curtis_distance_matrix.qza --output-path BrayCurtis/
qiime tools export --input-path core-metrics-results/weighted_unifrac_distance_matrix.qza --output-path WeightedUnifrac/
qiime tools export --input-path core-metrics-results/unweighted_unifrac_distance_matrix.qza --output-path UnweightedUnifrac/
qiime tools export --input-path core-metrics-results/jaccard_distance_matrix.qza --output-path Jaccard/

qiime feature-classifier classify-sklearn --i-classifier gg-13-8-99-515-806-nb-classifier.qza --i-reads rep-seqs.qza --o-classification taxonomy.qza

qiime feature-classifier classify-sklearn --i-classifier silva-138-99-515-806-nb-classifier.qza --i-reads rep-seqs.qza --o-classification silva_taxonomy_515_806.qza

qiime taxa barplot --i-table table.qza --i-taxonomy taxonomy.qza --m-metadata-file metadata-2021.tsv \
  --o-visualization taxa-bar-plots.qzv

qiime metadata tabulate \
  --m-input-file silva_taxonomy_515_806.qza \
  --o-visualization silva_taxonomy_515_806.qzv

## GOES UP TO TAXONOMY
