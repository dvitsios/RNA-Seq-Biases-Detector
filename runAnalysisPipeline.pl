#!/usr/bin/env perl

use strict;
use warnings;
use threads;


my $analysisFolder = $ARGV[0];
my @uniqueFileIds = ();

if(-d $analysisFolder){

        opendir my $dh, $analysisFolder
                or die "$0: opendir: $!\n";

        while (defined(my $name = readdir $dh)) {
		next unless $name =~ /txt$/;

		my $tmpUniqueId = substr($name, index($name, '_')+1, (index($name, '.') - (index($name, '_')+1)));

		print "tmpUniqueId: $tmpUniqueId\n";
                push(@uniqueFileIds, $tmpUniqueId);
        }
}


my @resultsAnalysisThreads = ();

foreach(@uniqueFileIds){

	push @resultsAnalysisThreads, threads->create(sub{
		my $CUR_FILE_UNIQUE_ID = $_;
		my $BLAST_INPUT_FILE = "Blast_Input/blast3pInput_".$CUR_FILE_UNIQUE_ID.".fa";
		my $BLAST_OUTPUT_TOP_HITS = "Blast_Output/out_".$CUR_FILE_UNIQUE_ID.".txt.top";

		print "CUR_FILE_UNIQUE_ID: $CUR_FILE_UNIQUE_ID\n";
		print "BLAST_INPUT_FILE: $BLAST_INPUT_FILE\n";
		print "BLAST_OUTPUT_TOP_HITS: $BLAST_OUTPUT_TOP_HITS\n";

		print "-----------\n\n";

		system("./analyze3pSeqBiases.pl $BLAST_INPUT_FILE $BLAST_OUTPUT_TOP_HITS $CUR_FILE_UNIQUE_ID");
	});
}

foreach (@resultsAnalysisThreads){
	$_->join();
}
