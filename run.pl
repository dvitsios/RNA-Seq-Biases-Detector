#!/usr/bin/env perl

use strict;
use warnings;
use threads;


my $inputDirOrFilePath = $ARGV[0];


# =====  PREPARE SUBJECT SEQUENCES - REFERENCE DATABASE  =====

## - Create the fasta with all the 3p-exons and their sequences
#  ...in order to build the subject blastable database.
system("./get3pExonSeqsFromHumanTranscriptome.pl"); 


## If [subject sequnces/db change] then run:
system("makeblastdb -in 3pExons.fa -dbtype nucl -title Human_3p_Exons -out db/Human_3p_Exons"); 

# =============================================================


my @inputFeqFiles = ();

if(-f $inputDirOrFilePath){
	push(@inputFeqFiles, $inputDirOrFilePath);
} elsif(-d $inputDirOrFilePath){

	opendir my $dh, $inputDirOrFilePath
		or die "$0: opendir: $!\n";

	while (defined(my $name = readdir $dh)) {
 		next unless -f "$inputDirOrFilePath/$name";
		my $tmpInputFile = $inputDirOrFilePath.$name;
		push(@inputFeqFiles, $tmpInputFile);
	}
	
}



my @blastJobsThreads = ();
my $BLAST_INPUT_DIR = "./Blast_Input/";	


for(my $fId=0; $fId<=$#inputFeqFiles; $fId++){

	
	

	push @blastJobsThreads, threads->create(sub{
		
		print "--> Started thread: $fId\n";
	
		# input files follow the following name structure: data/c11.lane.clean.uniquified.fa ---> c11 is the uniqe file id
		my $CUR_FILE_UNIQUE_ID = substr($inputFeqFiles[$fId], index($inputFeqFiles[$fId], '/') + 1, (index($inputFeqFiles[$fId], '.') - (index($inputFeqFiles[$fId], '/')+1)));


		## If [query sequences change] then run:
		system("./prepareReadsForBlast.pl $inputFeqFiles[$fId] $CUR_FILE_UNIQUE_ID");

		# in case I want to keep only 2000 lines from the input file
		# system("./prepareReadsForBlast.pl $inputFeqFiles[$fId] $CUR_FILE_UNIQUE_ID 2000");


		my $CUR_BLAST_INPUT_FILE = $BLAST_INPUT_DIR."blast3pInput_".$CUR_FILE_UNIQUE_ID.".fa";

		
		print "Starting blast job for thread $fId...\n\n";
		## Blast the query sequences against the subject db
		#system("./runBlastJob.pl $CUR_BLAST_INPUT_FILE $CUR_FILE_UNIQUE_ID");


		## When using the cluster:
		system("bsub ./runBlastJob.pl $CUR_BLAST_INPUT_FILE $CUR_FILE_UNIQUE_ID");
	});
	
}

foreach (@blastJobsThreads) {
	$_->join();
}

print "All blast jobs have been submitted\n";

