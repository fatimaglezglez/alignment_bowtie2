

#!/bin/bash

echo The program has started.

# Copying diles and decompressing them 
echo All data files will be copied to your current directory and decompressed.
echo The data is going through a quality control. Everything is a PASS unless it is shown otherwise below:

for file in $( ls /localdisk/data/BPSM/Assignment1/fastq );
do 
cp /localdisk/data/BPSM/Assignment1/fastq/$file . 
if [[ "$file" == *".gz" ]]; then 
gunzip ./$file
fastqc -q ./${file%.gz}
unzip -q ./${file%.fq.gz}_fastqc.zip
## Quality check: print whenever the output is WARN or FAIL
grep "WARN\|FAIL" ${file%.fq.gz}_fastqc/summary.txt
fi
done

#Unziping reference genome and building index for future alignment
cp /localdisk/data/BPSM/Assignment1/Tbb_genome/Tb927_genome.fasta.gz .
gunzip Tb927_genome.fasta.gz
bowtie2-build -q Tb927_genome.fasta Tbb_genome_indexes

cp /localdisk/data/BPSM/Assignment1/Tbbgenes.bed .

#doing the alignment for every pair of data and converting the output into the required format for later on
for file in $(ls *_1.fq);
do 
bowtie2 --quiet -x Tbb_genome_indexes -1 $file -2 ${file%1.fq}2.fq -S ${file%_1.fq}_align.sam  
samtools view -b -S ${file%_1.fq}_align.sam > ${file%_1.fq}_align.bam
samtools sort ${file%_1.fq}_align.bam -o ${file%_1.fq}_align_sorted.bam 
samtools index ${file%_1.fq}_align_sorted.bam 
echo $file aligned
done

#counting number of reads per gene for both slender and slumpy separately
echo Counting genes

bedtools multicov -bams $(ls | grep "216\|218\|219" | grep "d.bam" | grep -v "bai") -bed Tbbgenes.bed > slender_count.bed
bedtools multicov -bams $(ls | grep "220\|221\|222" | grep "d.bam" | grep -v "bai") -bed Tbbgenes.bed > slumpy_count.bed

#computing the average of caunts per gene
awk '{FS="\t";
if ($5=="gene") {printf "%s\t%s\n", $4, ($7+$8+$9)/3;}}' slender_count.bed >> average_slender.txt
awk '{FS="\t";
if ($5=="gene") {printf "%s\n", ($7+$8+$9)/3;}}' slumpy_count.bed >> average_slumpy.txt

#merging the data into a unique output file
echo "Gene_name\tSlender\tSlumpy" > average_counts_slender_slumpy.txt
paste -d"\t" average_slender.txt average_slumpy.txt >> average_counts_slender_slumpy.txt

echo Finished! You will find the output in your working directory named as: average_counts_slender_slumpy.txt



