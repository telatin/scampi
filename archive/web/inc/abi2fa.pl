#!/usr/bin/perl

use lib "$ENV{PWD}/";

require "ABI.pm";
($file) = @ARGV;

my $abi = ABI->new(-file=>"$file");
my $seq = $abi->get_sequence();
$seq = formatdna($seq);

print ">$file\n$seq\n";

sub formatdna {
	my $s = shift;
	my $formatted;
	my $line = 70; # change here
	for ($i=0; $i<=length($s); $i+=$line) {
		my $frag = substr($s, $i, $line);
		$formatted.=$frag."\n";
	}
	return $formatted;
}
 
