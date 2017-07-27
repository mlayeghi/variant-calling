## **A quick & dirty code to call variants in bacterial genomes**

You have one or multiple newly sequenced bacterial draft genomes, sampled or cultured under different conditions, and want to call the SNPs against a reference genome to find phenotype-associated variants?
Well, here it is a quick & dirty way to do so!

## Requirements

Get or install:
1. bwa
2. samtools
3. bcftools
4. seqtk
5. Trimmomatic
6. Their dependencies

## Run

Make it executable:

```
sudo chmod +x variant_call.sh
```

Run it:
```
./variant_call.sh
```
