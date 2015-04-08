#!/usr/bin/env perl


my $inputFasta = $ARGV[0];
my $CUR_FILE_UNIQUE_ID = $ARGV[1];


# create dir for all blast output files, if it doesn't exist.
my $BLAST_OUTPUT_DIR = "./Blast_Output/";
if (! -e "$BLAST_OUTPUT_DIR") {
	mkdir("$BLAST_OUTPUT_DIR") or die "Can't create $BLAST_OUTPUT_DIR:$!\n";
}

my $blastOutputFile = $BLAST_OUTPUT_DIR."out_".$CUR_FILE_UNIQUE_ID.".txt";


print "Blast job ($inputFasta --> $blastOutputFile)  has started!\n";
system("blastn -db Human_3p_Exons -query $inputFasta -num_threads 8 -outfmt \"7 qacc sacc qstart qend length qseq nident mismatch gaps evalue score\" -out $blastOutputFile");



my $topHitsFname = $blastOutputFile.".top";
system("sort -u -k1,1 --merge $blastOutputFile > $topHitsFname");


print "==> Blast job for $inputFasta has finished!\n";


