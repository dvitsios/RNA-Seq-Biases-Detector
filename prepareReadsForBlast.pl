#!/usr/bin/env perl


use strict;
use warnings;

# create dir for all blast input files, if it doesn't exist.
my $BLAST_INPUT_DIR = "./Blast_Input/";
if (! -e "$BLAST_INPUT_DIR") {
	mkdir("$BLAST_INPUT_DIR") or die "Can't create $BLAST_INPUT_DIR:$!\n";
}


my $INPUT_QUERY_FILE = $ARGV[0];
print "INPUT_QUERY_FILE: $INPUT_QUERY_FILE\n";
my $CUR_FILE_UNIQUE_ID = $ARGV[1];
print "CUR_FILE_UNIQUE_ID: $CUR_FILE_UNIQUE_ID\n";



my $SUBSET_FOR_BLAST_INPUT = 'FALSE';
my $LINES_TO_KEEP = 0;
if(@ARGV > 2){
	$SUBSET_FOR_BLAST_INPUT = 'TRUE';
	$LINES_TO_KEEP = $ARGV[1];
}

#read one file only first. All files will be already unzipped, with a .fa extension

my $CUR_OUTPUT_FILE = $BLAST_INPUT_DIR."blast3pInput_".$CUR_FILE_UNIQUE_ID.".fa";
open OUT_FILE, ">", $CUR_OUTPUT_FILE;


open FILE, "$INPUT_QUERY_FILE" 
	or die $!;

# check the first 10000 lines to get the max (standard) read length
my $MAX_READ_LENGTH = 0;
my $lineCnt = 0;
while(<FILE>){
	
	chomp;
	my $line = $_;
	$lineCnt++;
	
	if($lineCnt >= 10000){
		last;
	}

	if(!($lineCnt % 2)){	
		if(length($line) > $MAX_READ_LENGTH){
			$MAX_READ_LENGTH = length($line);
		}
	}
}
close FILE;
print "MAX_READ_LENGTH: $MAX_READ_LENGTH\n";



open FILE, "$INPUT_QUERY_FILE" 
        or die $!;

my $maxLengthLinesCnt = 0;
my $shortLinesCnt = 0;
my $linesToKeepCnt = 0;
my $minReadLenOfInterest = $MAX_READ_LENGTH;
my $maxReadLenOfInterest = 0;

$lineCnt = 0;
my $curSeqIdentifier = "";
while(<FILE>){

        chomp;
        my $line = $_;
        $lineCnt++;                

        if(!($lineCnt % 2)){
                if(length($line) == $MAX_READ_LENGTH){
                	$maxLengthLinesCnt++;
		}
		elsif(length($line) <= $MAX_READ_LENGTH/2){
			$shortLinesCnt++;
		} elsif(length($line) <= ($MAX_READ_LENGTH-10)){

			print OUT_FILE "$curSeqIdentifier\n$line\n";

        		$linesToKeepCnt++;
			if(length($line) > $maxReadLenOfInterest){
				$maxReadLenOfInterest = length($line);
			} 
			if(length($line) < $minReadLenOfInterest){
				$minReadLenOfInterest = length($line);
			}		
		}
	} else {
		$curSeqIdentifier = $line;
	}
}
close FILE;



close OUT_FILE;


print "\nmaxLengthLinesCnt: $maxLengthLinesCnt out of $lineCnt\n";
print "shortLinesCnt: $shortLinesCnt out of $lineCnt\n";
print "linesToKeepCnt: $linesToKeepCnt out of $lineCnt, range: $minReadLenOfInterest to $maxReadLenOfInterest\n";


if($SUBSET_FOR_BLAST_INPUT eq 'TRUE'){
	system("cat $CUR_OUTPUT_FILE | head -n$LINES_TO_KEEP > $CUR_OUTPUT_FILE.\"tmp\"");
	system("rm $CUR_OUTPUT_FILE");
	system("mv $CUR_OUTPUT_FILE.\"tmp\" $CUR_OUTPUT_FILE");
}

