#!/usr/bin/perl

$maxmem = 80;
($f3, $r3, $max) = @ARGV;

print STDERR "
  ------------------------------------------------------------
  [TRAP Step1] MP-PAIRING TOOL v.001
  ------------------------------------------------------------
";

if ( ($f3=~/-h/) or ($f3==0)) {
print STDERR "
  Reads two csfastq files (F3, R3) and prints a one-line 
  version of the two:   NAME  SEQ1  QUAL1  SEQ2  QUAL2
  
  Works only with F3 and R3 tags at the moment. 
  REQUIRES MEMORY TO STORE THE WHOLE F3 FILE!
  
  Usage:
  mp_pairsSelector F3.csfastq R3.csfastq
  ------------------------------------------------------------

";

}

die "Missing parameters\n" unless ($r3);
open(F, "$f3") || die " FATAL ERROR:\nUnable to read $f3 (F3).\n";
open(R, "$r3") || die " FATAL ERROR:\nUnable to read $r3 (R3).\n";

print STDERR "
  F3 file opened: $f3
  R3 file opened: $r3
  
";

my @aux = undef;
my @aux2 = undef;
while (my ($name, $seq, $qual) = readfq(\*F, \@aux)) {
   chop($name);
   chop($name);
   $c++;
   unless ($c%100000) {
    $m = mem();
    $reads = $c;
    $reads =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
    print STDERR "  F3: $reads reads loaded into memory ($m%)\r";
    if ($m>$maxmem) {
      print STDERR "\n  [WARNING]\n  Stopped reading $f3 at $reads because memory usage is $m% (max: $maxmem%)\n";
      last;
    }
   }
   $seq{$name}=$seq;
   $qual{$name}=$qual;   
   last if ($c > $max and $max);
}
print STDERR "\n";
while (my ($name, $seq, $qual) = readfq(\*R, \@aux2)) {
   $C++;
   chop($name);
   chop($name);
   
   if ($seq{$name}) {
    print "$name\t$seq\t$qual\t$seq{$name}\t$qual{$name}\n";
    $p++;
   }
   unless ($C%100000) {
    $m = mem();
    $reads = $C;
    $reads =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
    print STDERR "  R3: $reads reads printed ($m%)\r";
    last if ($m>80);
   }
   last if ($p==$c);
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

sub mem {
        @output = `ps aux | grep $$`;
        foreach my $line (@output) {
                my ($u, $pid, $cpu, $mem) = split /\s+/, $line;
                return $mem if ($pid == $$);
        }
}