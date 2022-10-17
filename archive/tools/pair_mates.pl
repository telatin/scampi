#!/usr/bin/perl
use Getopt::Long;

print STDERR "
------------------------------------------------------------------------
   PAIR READS
------------------------------------------------------------------------
   Takes two input files, and prints only
   paired reads in the same order.

   Usage:
   -file1 csfasta/q -file2 csfasta/q -tag1 string -tag2 string -o name
------------------------------------------------------------------------
";

GetOptions('file1=s' => \$file1,
           'file2=s' => \$file2,
           'tag1=s'  => \$tag1,
           'tag2=s'  => \$tag2,
           'o=s'     => \$o);

 if (!$file1 or !$file2 or !$tag1 or !$tag2 or !$o) {
  die "
  This program reads all reads in file1 (fasta/fastq formats are accepted). Then
  reads also file2 and then prints two files (adding tag name as suffix) with
  reads shared by the two, in the same order.
  
  Missing parameters.
";
}
open (F, "$file1")   || die " FATAL ERROR:\n Unable to open file1: $file1.\n";
open (R, "$file2")   || die " FATAL ERROR:\n Unable to open file1: $file2.\n";
open (O1, ">$o.$tag1")|| die " FATAL ERROR:\n Unable to write $o.$tag1.\n";
open (O2, ">$o.$tag2")|| die " FATAL ERROR:\n Unable to write $o.$tag2.\n";

print STDERR " [Step1]   Loading $file1...\n";

my @aux = undef;
while (my ($name, $seq, $qual) = readfq(\*F, \@aux)) {
	if (!$f and $qual) { print STDERR "           * FASTQ format detected\n";$fastq=1; }
	$f++;
	print STDERR " [Step1]   $f sequences parsed...\r" unless ($f%125000);
	if ($name !~s/$tag1//) {
		die " FATAL ERROR: TAG NOT FOUND\n$tag1 not found in $name ($file1).\n";
	} 

	$seq1{$name} = $seq;
	$qual1{$name}= $seq;
		
}
print STDERR " [Step1]   $f reads loaded into memory.

 [Step2]   Pairing with file $file2...\n";
my @aux = undef;
while (my ($name, $seq, $qual) = readfq(\*F, \@aux)) {
	$r++;
	$name =~s/$tag2//;
	print STDERR " [Step1]   $f sequences parsed...\r" unless ($f%125000);
	if ($seq1{$name}) {
		if ($fastq) { 
			print O1 "\@$name$tag1\n$seq1{$name}\n+\n$qual1{$name}\n";
			print O2 "\@$name$tag2\n$seq\n+\n$qual\n";
		} else {
			print O1 ">$name$tag1\n$seq1{$name}\n";
			print O2 ">$name$tag2\n$seq\n";
		}
	}
		
}





sub readfq {
    my ($fh, $aux) = @_;
    @$aux = [undef, 0] if (!defined(@$aux));
    return if ($aux->[1]);
    if (!defined($aux->[0])) {
        while (<$fh>) {
            chomp;
            if (substr($_, 0, 1) eq '>' || substr($_, 0, 1) eq '@') {
                $aux->[0] = $_;
                last;
            }
        }
        if (!defined($aux->[0])) {
            $aux->[1] = 1;
            return;
        }
    }
    my $name = /^.(\S+)/? $1 : '';
    my $seq = '';
    my $c;
    $aux->[0] = undef;
    while (<$fh>) {
        chomp;
        $c = substr($_, 0, 1);
        last if ($c eq '>' || $c eq '@' || $c eq '+');
        $seq .= $_;
    }
    $aux->[0] = $_;
    $aux->[1] = 1 if (!defined($aux->[0]));
    return ($name, $seq) if ($c ne '+');
    my $qual = '';
    while (<$fh>) {
        chomp;
        $qual .= $_;
        if (length($qual) >= length($seq)) {
            $aux->[0] = undef;
            return ($name, $seq, $qual);
        }
    }
    $aux->[1] = 1;
    return ($name, $seq);
}
