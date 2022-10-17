#!/usr/bin/perl
use Getopt::Long;

print STDERR "
  +--------------------------------------------------------------+
  | GAP CLOSURE IS A PLEASURE                                    |
  +--------------------------------------------------------------+

   -s, -scaffold     Multifasta with scaffold 
                     (stretch of Ns between contigs)
   -f, -for          File with FOR reads
   -r, -rev          File with REV reads
   -l, -len          Average insert size
   -type             0 for Mate Pair, 1 for Paired Ends

";
$opt = GetOptions (
  's|scaffold=s'       => \$inputFile,
  'f|for=s'            => \$forReads,        
  'r|rev=s'            => \$revReads,
  'l|len=i'            => \$avgSize,
  'type=i'             => \$pairType
);

open(I, "$inputFile") || die " FATAL ERROR:\n Unable to load input scaffolds: '$inputFile'.\n";

 
my @aux = undef;

# PARSE SCAFFOLDS
while (my ($name, $seq, $qual) = readfq(\*I, \@aux)) {
    ++$n;

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
