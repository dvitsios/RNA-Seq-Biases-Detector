#!/usr/bin/env perl

use strict;
use warnings;
use List::Util 'first';  
use Data::Dumper;


sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

sub getComplementraySeq {

	my $seq = $_[0];

	print "seq: $seq\n";

	my $newSeq = "";

	for(my $i=0; $i<length($seq); $i++){
	
		my $curNt = substr($seq, $i, 1);

		if($curNt eq 'A'){
			$newSeq = $newSeq.'T';
		} elsif($curNt eq 'T'){
                        $newSeq = $newSeq.'A';
                } elsif($curNt eq 'G'){
                        $newSeq = $newSeq.'C';
                } elsif($curNt eq 'C'){
                        $newSeq = $newSeq.'G';
                } elsif($curNt eq 'N'){
                        $newSeq = $newSeq.'N';
                }
	}
	return $newSeq;
}


open (MYFILE, 'Hsa_Transcriptome_Db/Homo_sapiens.GRCh37.75.gtf');

my ($prevTranscriptID, $prevExonID, $prevExonNumber, $prevStartCoord) = ();
my ($prevExonOneTranscriptID, $prevExonOneExonID, $prevExonOneExonNumber, $prevExonOneStartCoord) = ();


my @only3pExons = ();

my $exonCnt = 0;
while(my $line = <MYFILE>){
	chomp $line;


	if($line =~ /exon_id/){
		
		$exonCnt++;
		my @vals = split(';', $line);
	

		# get start coord for cur transcript
		my $firstField = $vals[0];
		my @firstFieldVals = split(' ', $firstField);
		my $curStartCoord = $firstFieldVals[3];


		# get transcript ID	
		my $transcriptID_match = first { /transcript_id/ } @vals;
		$transcriptID_match =~ s/transcript_id//;
		$transcriptID_match =~ s/"//g;
		$transcriptID_match =~ s/ //g;
		my $curTranscriptID = $transcriptID_match;


		# get exon number
		my $exonNumber_match = first { /exon_number/ } @vals;  		
		$exonNumber_match =~ s/exon_number//;
		$exonNumber_match =~ s/"//g;
		$exonNumber_match =~ s/ //g;
		my $curExonNumber = $exonNumber_match;

		# get exon id
		my $exonID_match = first { /exon_id/ } @vals;
                $exonID_match =~ s/exon_id//;
                $exonID_match =~ s/"//g;
                $exonID_match =~ s/ //g;
                my $curExonID = $exonID_match;

		
	
		if($exonCnt == 1){
			$prevTranscriptID = $curTranscriptID;
			$prevExonID = $curExonID;
			$prevExonNumber = $curExonNumber;
			$prevStartCoord = $curStartCoord;


			$prevExonOneTranscriptID = $curTranscriptID;
			$prevExonOneExonID = $curExonID;
			$prevExonOneExonNumber = $curExonNumber;
			$prevExonOneStartCoord = $curStartCoord; 

		} else{
			if($curExonNumber == 1){
				
				if($prevStartCoord > $prevExonOneStartCoord){		
					push(@only3pExons, $prevExonID);
				} else{
					# special treatment for anti-sense transcripts
					# 1st strategy: consider the exon number - 1 as the 3' exon
					##$prevExonOneExonID = "_antiSense".$prevExonOneExonID;
					##push(@only3pExons, $prevExonOneExonID);
					
					# 2nd strategy: consider the last exon as the 3' exon
					# since according to ensembl's annotation
					# (e.g. http://www.ensembl.org/Homo_sapiens/Transcript/Summary?db=core;g=ENSG00000185418;r=15:102194416-102249031;t=ENST00000558533)
					# the exon at the left-most edge of the transcript at this image
					# corresponds to the LAST exon in the .gtf file.
					# So, probably that's the 3p exon.
					# ! The only thing is that I may have to get the *REVERSE* of that
					# sequence since in the .gtf file the coordinates of that transcript are given
					# in an increasing order, which is opposite to the direction of transcription.
					$prevExonID = "_antiSense".$prevExonID;
                                        push(@only3pExons, $prevExonID);

				}
				
	
				$prevExonOneTranscriptID = $curTranscriptID;
				$prevExonOneExonID = $curExonID;
				$prevExonOneExonNumber = $curExonNumber;
				$prevExonOneStartCoord = $curStartCoord;

			}

			$prevTranscriptID = $curTranscriptID;
                        $prevExonID = $curExonID;
                        $prevExonNumber = $curExonNumber;
			$prevStartCoord = $curStartCoord;
		}

		
		if(($exonCnt % 500) == 0){
			print "$exonCnt...";
		}
		
		#if($exonCnt > 100){
		#	last;
		#}

	}


}

@only3pExons = uniq(@only3pExons);


# read all exon_ids - sequences pairs into a hash.
my %allExonsAndSeqs = ();

open (ALL_EXONS_FH, 'Hsa_Transcriptome_Db/mart_export.txt');

my $exonsCnt = 0;

my $curExonId = "";
my $prevExonId = "";
my $exonSeq = "";
while(my $line = <ALL_EXONS_FH>){
    
    chomp $line;

    
    if($line =~ /^>/){

	$line =~ s/>//;
	$curExonId = $line;

        if($exonSeq ne ""){
                
		$allExonsAndSeqs{$prevExonId} = $exonSeq;

        	$exonSeq = "";

		#$exonsCnt++;
        	#if($exonsCnt > 10){
		#	last;
		#}
	}   	 
    
    } else{
	    $prevExonId = $curExonId;
            $exonSeq = $exonSeq.$line;
    }

}

#print Dumper(\%allExonsAndSeqs);

print "\nCreated %allExonsAndSeqs hash!\n";
print "size of hash:  " . keys( %allExonsAndSeqs ) . ".\n";



open EXONS_3p_FH, ">3pExons.fa" or die "can't open exons3p.txt: $!"; 


foreach(@only3pExons){

	my $curExonId = $_;
	my $curExonSeq = "";

	print "1. curExonId: *$curExonId*\n";

	# include special treatment for anti-sense transcripts:
	if($curExonId =~ /_antiSense/){
	
	
		$curExonId =~ s/_antiSense//;
		print "2. curExonId: *$curExonId*\n";
		
		$curExonSeq = $allExonsAndSeqs{$curExonId};

		print "curExonSeq: $curExonSeq\n";
		
		# not needed: it s already reversed by ensembl
		#$curExonSeq = scalar reverse $curExonSeq;
		
		# get the complementary sequence at the positive strand - which will resemble to the final mRNA transcript
		# required! ====>
		$curExonSeq = getComplementraySeq($curExonSeq);	

		print "curExonSeq: $curExonSeq\n";

	} else{
		$curExonSeq = $allExonsAndSeqs{$curExonId};
	}


	# write sequences to fasta in 60-nt long parts
	my @exonSeqChunksForFasta = unpack("(A60)*", $curExonSeq);

	if($curExonSeq eq "" || !(defined $curExonSeq)){
		die "undefined or empty curExonSeq for curExonId: $curExonId\n";
	}	

	print EXONS_3p_FH ">$curExonId\n";
	foreach(@exonSeqChunksForFasta){
		print EXONS_3p_FH "$_\n";
	}

}

close EXONS_3p_FH;

print "==> get3pExonSeqsFromHumanTranscriptome.pl returned succesfully!\n";
