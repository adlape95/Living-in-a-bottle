##Import demultipliex sequences 
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path Manifest \
  --output-path ./demux-paired-end.qza \
  --input-format PairedEndFastqManifestPhred33


## Check parameters of the reads
qiime demux summarize \
  --i-data ./demux-paired-end.qza \
  --o-visualization ./demux-paired-end.qzv

## Sequence quality control and feature table construction
 qiime dada2 denoise-paired \
  --i-demultiplexed-seqs ./demux-paired-end.qza \
  --verbose \
  --p-trim-left-f 17 \
  --p-trim-left-r 22 \
  --p-trunc-len-f 285 \
  --p-trunc-len-r 255 \
  --p-n-threads 12 \
  --o-table ./table.qza \
  --o-representative-sequences ./rep-seqs.qza \
  --o-denoising-stats ./denoising-stats.qza 



qiime metadata tabulate \
  --m-input-file ./denoising-stats.qza \
  --o-visualization ./stats-dada2.qzv


##Taxonomic classification. Database SILVA 132.
## Done in Darwin's computer
qiime feature-classifier classify-sklearn \
  --i-classifier /path/to/Silva-132-classifier \
  --i-reads ./rep-seqs.qza \
  --verbose \
  --p-n-jobs 8 \
  --o-classification ./taxonomy.qza 



##Export the qiime2 BiomTables (table.qza, taxonomy.qza, rooted-tree.qza) in such a way that it can be loaded into the R package phyloseq.

#Export table.qza and taxonomy.qza
qiime tools export \
 --input-path ./table.qza \
  --output-path  ./table

#Export taxonomy.qza and taxonomy.qza
qiime tools export \
 --input-path ./taxonomy.qza \
  --output-path  ./taxonomy


#Modify the biom-taxonomy tsv headers: change header "Feature ID" to "#OTUID"; "Taxon" to "taxonomy"; and "Confidence" to "confidence"
sed -i -e 's/Feature ID/#OTUID/g' ./taxonomy/taxonomy.tsv
sed -i -e 's/Taxon/taxonomy/g' ./taxonomy/taxonomy.tsv
sed -i -e 's/Confidence/confidence/g' ./taxonomy/taxonomy.tsv

#Add taxonomy data to .biom file
biom add-metadata -i ./table/feature-table.biom -o ./table-with-taxonomy.biom --observation-metadata-fp ./taxonomy/taxonomy.tsv --sc-separated taxonomy

#convert to json format
biom convert -i ./table-with-taxonomy.biom -o ./table-with-taxonomy-json2.biom --table-type="OTU table" --to-json
