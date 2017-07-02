# Prepare reference database of sequences 


** sample run (extended - in practice)**:
```
blastn -db Human_3p_Exons -query nt.fa -num_threads 8 -outfmt "7 qacc sacc qstart qend qseq length nident mismatch gaps evalue score" -out out.txt 
```

** sample run (in practice) **:
```

blastn -db Human_3p_Exons -query nt.fa -outfmt "7 qacc sacc qstart qend evalue" 

```

** sample run (verbose) **:
```

blastn -db Human_3p_Exons -query nt.fa -outfmt 6

```


** Make blastable database **:
```

makeblastdb -in 3pExons.fa -dbtype nucl -title Human_3p_Exons -out db/Human_3p_Exons

```

* get best hits only from blast output:
```

sort -u -k1,1 --merge outTest.txt > outBestHits.txt
```




# Run
```

./get3pExonSeqsFromHumanTranscriptome.pl

./prepareReadsForBlast.pl # (if query sequences change)

makeblastdb -in 3pExons.fa -dbtype nucl -title Human_3p_Exons -out db/Human_3p_Exons # (if subject sequnces / db change)

./runBlastJob.pl

# when using the cluster:
bsub -M 4096 -R "rusage[mem=4096]" -n 2 ./runBlastJob.pl 


***

1. RUN THE WHOLE BLAST PIPELINE:
```
./run.pl data/c11.lane.clean.uniquified.fa  #for a single file
```

# or 
```
./run.pl data/  #for multiple files inside a folder
```

2. Analyze BLAST output:
```
./runAnalysisPipeline.pl Blast_Output/
```

3. Merge the results and plot the overall biases distribution
```
Rscript mergeBiasesResultsAndPlot.R 
```
