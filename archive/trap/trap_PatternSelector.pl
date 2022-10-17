#!/usr/bin/perl

@spin = ('⠁','⠂','⠄','⠠','⠐','⠈');
($file, $pattern, $out) = @ARGV;
print STDERR "
  ------------------------------------------------------------
   [TRAP Step1] Pattern Finder in SOLID MP reads
  ------------------------------------------------------------
  Scans a tabular file of mate pairs (NAME SEQ1 QUAL1 SEQ2 QUAL2)
  for a pattern and prints sequences in FASTQ format
  
  USAGE:
   Filename Pattern Output -single
   
  Saves into .F3 and .R3 files, unless -single switch is added
  ------------------------------------------------------------
";

$out = $file unless ($out);

$t1 = 'F3';
if ($ARGV[$#ARGV] eq '-single') {
	$t2 = 'F3';
} else {
	$t2 = 'R3';
}
open (I, "$file") || die " FATAL ERROR:\n Unable to load $file.\n";
open (F3, ">$out.$t1") || die " FATAL ERROR:\n Unable to write to $out.F3\n";
open (R3, ">$out.$t2") || die " FATAL ERROR:\n Unable to write to $out.R3\n" unless ($single);
while (<I>) {
  chomp;
  ($name, $s1, $q1, $s2, $q2) = split /\t/, $_;
  $tot++;
  if ($s1=~/$pattern/ || $s2=~/$pattern/)  {
    $pos++;
    #print "\@$name\F3\n$s1\n+\n$q2\n\@$name\R3\n$s2\n+\n$q2\n";
    print F3 "\@$name\F3\n$s1\n+\n$q1\n";
    print R3 "\@$name\R3\n$s2\n+\n$q2\n";
  }
  
  unless ($tot%100000) {
    $r = sprintf("%.2f", $pos*100/$tot) if ($tot);
    $found = $pos; $found =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
    $total = $tot; $total =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
    $print++;
    $i = $print%6;
    print STDERR " $spin[$i] $r% matching pairs ($found/$total) \r";
  }
  
}
print STDERR "\nFinished scanning for $pattern ($pos/$tot matches)\n";

