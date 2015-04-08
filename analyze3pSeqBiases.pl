#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;


# get lengths of all query sequences


my $BLAST_INPUT_FILE = $ARGV[0];
my $BLAST_OUTPUT_TOP_HITS = $ARGV[1];
my $CUR_FILE_UNIQUE_ID = $ARGV[2];



open (MY_QUERY_FH, $BLAST_INPUT_FILE);

my %allQueryExonsSeqs = ();

my $curExon = "";
while(my $line = <MY_QUERY_FH>){

	chomp $line;

	if($line =~ /^>/){
		$line =~ s/>//;
		$curExon = $line;
	} else{
		$allQueryExonsSeqs{$curExon} = $line;
	}

}
close MY_QUERY_FH;
#print keys %allQueryExonsSeqs;
#print values %allQueryExonsSeqs;


# ======================================================


open (BEST_HITS_FH, $BLAST_OUTPUT_TOP_HITS);


my @allSeqBiases = ();
my @allBiasesCounts = ();
my $MAX_BIAS_LENGTH_THRESHOLD = 10;


my $artifactOffset = 10;
my $biasesSeqsCnt = 0;

while(my $line = <BEST_HITS_FH>){

        if(!($line =~ /^#/)){

                my @vals = split('\t', $line);

		my $curSeqId = $vals[0];
	        my $qStart = $vals[2];
                my $qEnd = $vals[3];
                my $alignLength = $vals[4];
		my $curSeq = $vals[5];
		$curSeq =~ s/-//g;
		
		#print "curSeqId: $curSeqId\n";
		#print "qStart: $qStart, qEnd:$qEnd, alignLength: $alignLength\n";
		#print "curSeq: $curSeq\n";



		if($qStart <= $artifactOffset){


			my $wholeQuerySeq = $allQueryExonsSeqs{$curSeqId};


			my $alignedSubseqStartIndex = index($wholeQuerySeq, $curSeq);
			my $alignedSubseqEndIndex = $alignedSubseqStartIndex + length($curSeq);

			if($alignedSubseqEndIndex < length($wholeQuerySeq) ){

				print "curSeqId: $curSeqId\n";
#				print "qStart: $qStart, qEnd:$qEnd, alignLength: $alignLength\n";
#				print "curSeq: $curSeq\n";
#				print "wholeQuerySeq: $wholeQuerySeq\n";

				my $wholeQuerySeqLength = length($wholeQuerySeq);

#				print "alignedSubseqEndIndex: $alignedSubseqEndIndex, wholeQuerySeqLength: $wholeQuerySeqLength\n";

					
				my $biasSeqLength = length($wholeQuerySeq) - $alignedSubseqEndIndex;			
				my $biasSeq = substr($wholeQuerySeq, $alignedSubseqEndIndex, $biasSeqLength);
	
				if($biasSeqLength < $MAX_BIAS_LENGTH_THRESHOLD){
		
					$biasesSeqsCnt++;
					push(@allSeqBiases, $biasSeq);	
				
					my @curSeqIdVals = split('x', $curSeqId);
					my $curSeqCounts = $curSeqIdVals[$#curSeqIdVals];
		
					push(@allBiasesCounts, $curSeqCounts);

	
					print "curSeq: $curSeq\n";
					print "wholeQuerySeq: $wholeQuerySeq\n";
					print "bias: $biasSeq\n\n";
				}

			}	

		} 

                #if(($qStart <= $artifactOffset) && ($alignLength > ($qEnd- $qStart + 1))){                      
		#	my $biasLength = $alignLength - ($qEnd- $qStart + 1);
		#	#my $curSeqBias = substr($curSeq, 
		#	print BIASES_FH "$line";
                #       $biasesSeqsCnt++;
                #}		
                
        }
}
close BEST_HITS_FH;




foreach(@allSeqBiases){
	s/T/U/g;
}



print "\n\n------------------------\nallSeqBiases:\n";
print join("\n", @allSeqBiases);

print "\n\n------------------------\n";
my $allSeqBiasesLen = $#allSeqBiases + 1;
print "allSeqBiases length: $allSeqBiasesLen\n";




# ==============================================
# - Analyze biases content using an array of hashes.
# Each hash will be referring to a distinct index position at the bias sequence
# and it will be containing the NTs distribution at that indes. 


my @arrayOfNtsDistrHashes = ();

#initialize the array of hashes with 0 counts for all the NTs at all indexes
foreach my $i (0..($MAX_BIAS_LENGTH_THRESHOLD-1)){

	my $tmpNtsDistrHash = {};

	$tmpNtsDistrHash->{'A'} = 0;
	$tmpNtsDistrHash->{'U'} = 0;
	$tmpNtsDistrHash->{'G'} = 0;
	$tmpNtsDistrHash->{'C'} = 0;
	$tmpNtsDistrHash->{'N'} = 0;

	push(@arrayOfNtsDistrHashes, $tmpNtsDistrHash);

}




my $tmpSeqCnt = 0;
foreach(@allSeqBiases){

	my $bias = $_;
	print "\n===> curBias: $bias\n";
	print "allBiasesCounts: $allBiasesCounts[$tmpSeqCnt]\n";

	my @nts = split(//, $bias);
	print join("\n", @nts);

	
	my $tmpIdx = 0;
	foreach(@nts){

		my $curNt =$_; 
		print "\ncurNt: $curNt\n";

		$arrayOfNtsDistrHashes[$tmpIdx]->{$curNt} += $allBiasesCounts[$tmpSeqCnt];
		
		$tmpIdx++;
	}

	print "----\n";

	$tmpSeqCnt++;
	#if($tmpSeqCnt > 10){
	#	exit;
	#}
}


# write hash to file
my $BIASES_OUTPUT_DIR = "./Biases_Output/";
if (! -e "$BIASES_OUTPUT_DIR") {
        mkdir("$BIASES_OUTPUT_DIR") or die "Can't create $BIASES_OUTPUT_DIR:$!\n";
}


my $biasesOutputFile = "$BIASES_OUTPUT_DIR/biases_".$CUR_FILE_UNIQUE_ID.".txt";
open (BIASES_FH, ">$biasesOutputFile");

my %tempHash = %{$arrayOfNtsDistrHashes[0]};
my @tmpSortedKeys = sort(keys %tempHash);

for(my $c=0; $c <= $#tmpSortedKeys; $c++){

	print BIASES_FH "$tmpSortedKeys[$c]";

	if($c < $#tmpSortedKeys){
		print BIASES_FH "\t";
	} elsif($c == $#tmpSortedKeys){
		print BIASES_FH "\n";
	}
}


foreach(@arrayOfNtsDistrHashes){
	my %tmpHash = %{$_};

	my $tmpKeyCnt = 1;
	my $numOfKeysInHash = keys %tmpHash;

	foreach my $key (sort(keys %tmpHash)) {
        	
		print BIASES_FH "$tmpHash{$key}";

		if($tmpKeyCnt < $numOfKeysInHash){
			print BIASES_FH "\t";
		}
		
		$tmpKeyCnt++;		
  
	}
	print BIASES_FH "\n"; 
	print Dumper(\%tmpHash);
}

close BIASES_FH;
