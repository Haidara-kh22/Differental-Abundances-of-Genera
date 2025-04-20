#!/bin/bash

# Fix first column name in feature_table.csv
awk -F',' 'NR==1{$1="OTU_id"}1' OFS=',' feature_table.csv > tmp_feature_table.csv

# Fix first column name in sample_metadata.csv
awk -F',' 'NR==1{$1="id"}1' OFS=',' sample_metadata.csv > tmp_sample_metadata.csv

# Convert CSV to TSV
tr ',' '\t' < tmp_sample_metadata.csv > sample_metadata.tsv
tr ',' '\t' < tmp_feature_table.csv > feature_table.tsv

# Remove double quotes
sed 's/"//g' feature_table.tsv > feature_table1.tsv

# Convert to BIOM format
biom convert -i feature_table1.tsv -o feature_table.biom --table-type "OTU table" --to-hdf5

# Import to QIIME2
qiime tools import \
  --input-path feature_table.biom \
  --type 'FeatureTable[Frequency]' \
  --input-format BIOMV210Format \
  --output-path feature_table.qza

# Run ANCOM-BC with different metadata formulas
qiime composition ancombc \
  --i-table feature_table.qza \
  --m-metadata-file sample_metadata.tsv \
  --p-formula study_condition..MBIOTEMP_study_condition. \
  --p-prv-cut 0.01 \
  --p-reference-levels "study_condition..MBIOTEMP_study_condition.::control" \
  --o-differentials ancombc_results.qza

# Export results
qiime tools export \
  --input-path ancombc_results.qza \
  --output-path ancom_results
