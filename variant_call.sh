#!/bin/bash

: '
 You will need:
1. bwa
2. samtools
3. bcftools
4. seqtk
5. Trimmomatic
'

# Number of reads for rarefaction
reads=1500000

# Reference genome
genome_file="MyGenome.fa"
genome_handle="MyGenome"

echo
echo "Indexing the reference genome ..."
echo
bwa index -p $genome_handle $genome_file
echo

# Let's say you have 10 NGS in separate Forward & Reverse read files,
# each contained in a separate folder, numbered from 1 to 10: ngs1, ngs2,  etc.
for i in {1..10}
do
	# Input forward & reverse reads
	in1="ngs${i}/R1.fastq"
	in2="ngs${i}/R2.fastq"

	## Let's save intermediate files in a temp folder
	# Outputs of rarefaction
	out1="temp/ngs${i}_S_R1.fastq"
	out2="temp/ngs${i}_S_R2.fastq"

	# Outputs after trimming; if necessary.
	out3="temp/ngs${i}_Str_R1.fastq"
	out4="temp/ngs${i}_Str_R2.fastq"

	# Outputs of Trimmomatic quality control
	out5="temp/ngs${i}_Strm_R1.fastq"
	out6="temp/ngs${i}_Strm_R2.fastq"

	# Output of aligning reads to reference genome
	aln1="temp/ngs${i}_aln.sam"

	# Output of variant calling results in bcf & vcf formats saved in Results folder
	var1="Results/ngs${i}_variants.bcf"
	var2="Results/ngs${i}_variants.vcf"

	echo "$in1 ..."

	## Rarefaction: randomly subsample 150000 read pairs from two paired FASTQ files
	# Random seed
	sn=$RANDOM
	seqtk sample -s $sn $in1 $reads > $out1
	seqtk sample -s $sn $in2 $reads > $out2
	
	# Trim low-quality bases from both ends: 15 & 0, espectively, in this example
	# Depending on fastqc results, you may need this or not
	seqtk trimfq -b 15 -e 0 $out1 > $out3
	seqtk trimfq -b 15 -e 0 $out2 > $out4

	# Run Trimmoatic with default setting on Nextera paired-end ngs for quality control
	# You can use different parameters & adapters depending on your ngs tech & quality
	java -jar Trimmomatic/trimmomatic-0.36.jar PE -phred33 $out3 $out4 $out5 se1.fq $out6 se2.fq ILLUMINACLIP:Trimmomatic/adapters/NexteraPE-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

	# Mapping the reads to reference, covert alignment, sort it, buid pileup, call variants,
	# & finally convert to vcf format
	echo "===   ${i} : Mapping the reads to reference genome"
	echo
	bwa mem -M -t 4 $genome_handle $out5 $out6 > $aln1
	echo
	echo "===   ${i} : Calling the variants"
	echo
	samtools view -Shu $aln1 | \
	samtools sort - | \
	samtools mpileup -uf $genome_file - | \
	bcftools call -vc - > $var1
	bcftools view $var1 > $var2
	echo
	echo "===   ${i} : Variants written to $var1 & $var2"
	echo

	# Remove everything from the temp file. Or not, you can obviously keep them if
	# you like. But, be aware, these are huge files.
	rm temp/*

done

