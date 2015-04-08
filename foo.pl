#!/usr/bin/env perl

my $str ="AAAAAABBBBBBCCCCCCDDDDDEFFFFFFGGGGGGIIJ";
print "$str\n";
my @codons = unpack("(A6)*", $str);

foreach(@codons){
	print "$_, ";
}
