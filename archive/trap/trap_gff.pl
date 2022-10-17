#!/usr/bin/perl

print STDERR "
 +----------------------------------------------+
 | Terminal regions alignments check            | 
 +----------------------------------------------+
 |                                              | 
 | Parameters:                                  |
 |  GFF Reference Window LibSize > Output.txt   |
 +----------------------------------------------+
";
($gff, $ref, $wnd, $factor) = @ARGV;

open(GFF, "$gff") || die " FATAL ERROR:\n Unable to load $gff GFF file.\n";
open(R,   "$ref") || die " FATAL ERROR:\n Unable to load $gff reference file.\n";


my @aux = undef;
print STDERR " [Step1] Loading reference...\r";
while (my ($name, $seq) = readfq(\*R, \@aux)) {
  $c++;
  $len{$name} = length($seq);
  
}

print STDERR " [Step1] Reference info loaded ($c sequences).\n";

print STDERR " [Step2] Parsing alignments...\r";
while (<GFF>) {
  #00286   pass    single  2359    2408    0       -       .       ID=1_926_1246_F3:N:0;Name=1_9
  ($name, $x, $x, $from, $to, $x, $st) = split (/\t/, $_);
  
  $alignments++;
  $p = int(($from+$to)/2);# Position (middle of read)

  ${"$name$st"}{$p}++;	  # Strand specific alimnents in position $p
  $tot{$name}++;	  # Total alignments:
  unless ($alignments%85300) { 
	  $a = $alignments;
	  $a =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
	  $t = time() - $^T;
	  print STDERR " [Step2] Loading alignments ($a) in $t s...\r" ; 
  }
}
print STDERR " [Step2] Step finished:  $alignments alignments loaded.\n";

foreach $seqname (sort {$len{$a} <=> $len{$b}} keys %len) {
	$counter++;
	print STDERR " [Step3] Processing seq \#$counter: $seqname... \r";
	print "# ------ Seq:$seqname ($len{$seqname} bp, $tot{$seqname} alignments)\n";
	next unless ($tot{$seqname});
	for ($i = 0; $i<$len{$seqname}; $i+=$wnd) {
		$hitsPlus = 0;
		$hitsMinus = 0;
		for ($j=$i; $j<$i+$wnd; $j++) {
			$hitsPlus+=${"$seqname\+"}{$j};
			$hitsMinus+=${"$seqname\-"}{$j};
		}
		$align = $hitsMinus + $hitsPlus;
		
		my $slots = $len{$seqname}/$wnd;
		my $exp   = $tot{$seqname} / $slots;
		my $ratio = sprintf("%.1f", $align / $exp);
		my $star  = 'T' if ($ratio > $factor);
		if ($ARGV[$#ARGV] eq '-debug') {
			$if="\talign=$tot{$seqname};len=$len{$seqname};\tslots=$slots;expexted=$exp;ratio=$ratio";
		}
		my $p = sprintf("%.2f", $i*100/$len{$seqname});
		print "$seqname\t$i\t$p\t$hitsPlus\t$hitsMinus\t$star\t$ratio\X$if\n";
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

