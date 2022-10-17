#!/usr/bin/perl
use Getopt::Long;
use File::Basename;
 
my $prog = basename($0);
$o='.';
$printevery = 200000;
$t = 0;
$bt= 0;
$mincov=2;
$opt = GetOptions (
  'i=s'     => \$inputFile,
  't'       => \$t,
  'bt'      => \$bt,
  'ref=s'   => \$refFile,
  'sam=s'   => \$samFile,
  'save=s' => \$splitFile,
  'o=s'     => \$outDir,
  'cov=i'   => \$mincov,
  'len=i'   => \$minlen,
  'print=i' => \$printevery,
  'help'    => \$help,
);

$o=$o.'/' if ($o!~/\/$/);;

print STDERR "
   ScaMPI Suite
 +--------------------------------------------------------------------+
 |  PHYSICAL COVERAGE ANALYSIS           v. 2.00         CRIBI 2013   |
 +--------------------------------------------------------------------+
";
print STDERR "
 -i      file  Unique Pair sorted (simplified format)
 -o      dir   Output directory for tracks (default: current)
 -m      int   Minimum physical coverage
 -t            Print all tracks (contigname.track)
 -bt           Print tracks of broken contigs/sequence
 -sam    file  SAM file to read header
 -ref    file  Reference (no need to provide -sam)
 
 -save   file  Print splitted contigs to file (requires -ref)
 -cov    int   Minimum physical coverage of contigs to be printed
 -len    int   Minimum length of contigs to be printed
 
 -ref is required to print splitted contigs.
 -ref or -sam are recommended to improve analysis accuracy.
 
" if ($help or !$i);

unless ($inputFile) {
	die " FATAL ERROR:\n Missing argument -i ...\n";
}
if ($t or $bt) {
	print STDERR " Save tracks: $t (only broken: $bt)\n";
}

open (I, "$inputFile") || die "Unable to load input file: $inputFile.\n";

die " FATAL ERROR:\n SAM file not exists: $sam.\n" if ($samFile and !-e $samFile);
die " FATAL ERROR:\n Reference file not exists: $ref.\n" if ($ref and !-e $ref);



if ($samFile) {
	die " Unable to find SAM: $samFile.\n" unless (-e $samFile);
	print STDERR " Using SAM file and ignoring reference!\n" if ($refFile);
	print STDERR " Loading SAM header: $samFile.\n";
	%size = samsize($samFile);
} 
if ($refFile) {
		my @aux = undef;
		die " Unable to find REFERENCE: $refFile.\n" unless (-e $refFile);
		print STDERR " Loading reference: $refFile.\n";
		my $cnt;
		my $len;
		open (R, "$refFile") || die " FATAL ERROR\n Unable to load \"$refFile\".";
		
		while (my ($name, $seq, $qual) = readfq(\*R, \@aux)) {
			$refseq{$name} = $seq if ($splitFile);
			$size{$name} = length($seq);
			$cnt++;
			$len+=length($seq);
		}
	$tot = bp($len);
	close X;
	print STDERR " REFERENCE: $cnt sequences found ($tot).\n";
	#%size = refsize($refFile);
}

if (!$samFile and !$refFile) {
	print STDERR " WARNING:\n You did not provide a reference (or SAM) file! Expect partial results...\n";
}

if ($splitFile) {
	open (F, ">$splitFile") || die " FATAL ERROR:\n Unable to open output file \"$splitFile\".\n";
}


print STDERR "\n";


while (<I>) {
	chomp;
	$line++;

	my ($contig, $strand, $from, $middle1, $middle2, $to) = split ( /\t/, $_);
	printstatus($line);
	
	$last = 1 if eof;
	if ($contig eq $previous and !$last) {
		### => still on previous contig 

		##$min = $middle1 if ($middle1<$min);
		##$max = $middle2 if ($middle2>$max);
		my $F = $from+1;
		my $T = $to  -1;
		$min = $F if ($F < $min);
		$max = $T if ($T > $max);
		
		for ($i=$F; $i<=$T; $i++) {
			$physcoverage{$i}++;
		}
		
	} else {
		### => first contig or contig changed
		

		# ========================================================================================		
		# analyze $coverage for $previous
		# ========================================================================================
		if ($previous) {
			my @fragments;
			$end = $size{$previous};
			$end = $max unless ($end);
			print STDERR " [ANALYSIS] Starting coverage analysis in $previous (".bp($end).")\n";

			my $on;
			my $broken='0';
			my $covered;
			for (my $p = 0; $p < $end; $p++) {
				$pc = $physcoverage{$p};
				$pc = '0' unless ($pc);
				$covTrack.="$pc\n";
				
				if ($pc>=$mincov) {
					$on = $p unless ($on);
				} else {
					if ($on) {
						push (@fragments, "$on-$p");
						my $value = 0;
						$covered += $p-$on+1;
						$value =  $totcov/($p-$on+1) if ($p-$on+1);
						push (@covfrags, $value);
						$totcov = 0;
						$on = 0;
						$broken++;
					} 
				
				}
				
				$totcov+=$pc;
				#print STDERR "$previous\t$p\t$max\tBAD_CONTIG\n" if ($physcoverage{$p}==0);
			}
			$breaks{$previous} = $broken;
		
		print STDERR " [ANALYSIS] Physical coverage analyzed (".bp($covered)." covered, $broken breaks).\n";
		print STDERR " [WARNING!] $previous -> $broken breackages.\n";
		if ($t or ($bt and $broken)) {			
			open (O, ">$o$previous.track") || die " FATAL ERROR:\n Unable to write '$o$previous.track'.\n";
			print STDERR " [TRACK]  Saving track to $o$previous.track\n";
			print O "$covTrack";
			close O;
		}
		print STDERR " [ANALYSIS] Extracting contiguous fragments\n";
		for (my $idx = 0; $idx<=$#fragments; $idx++) {
#		foreach my $frag (@fragments) {
			my $frag = $fragments[$idx];
			my $cov  = sprintf("%.2f", $covfrags[$idx]);
			my ($f, $t ) = split /-/, $frag;
			my $l = $t-$f+1;
			my $L = bp($l);
			print " subcontig$idx\t$previous\t$frag\t$L\t$cov X\n";
			if ($cov > $mincov and $l > $minlen) {
				$span = $t-$f+1;
				$seq = substr($refseq{$previous}, $f, $span);
				print F ">$previous\_$idx $f-$t\n".formatdna($seq);
			}
		}
		
		
		$t = time()-$^T;	
		$lps = int($line/$t) if ($t);
		print STDERR " [CYCLE_END] $line\t$previous finished. Now starting $contig\t$t s\t($lps l/s)\n";
		}
		last if $last;
		# ========================================================================================		
		#  START NEW CONTIG
		# ========================================================================================
		#CHECK SORTED FILE
		$totalChrs++;
		print STDERR " [ANALYSIS] Analyzing $contig ".bp($size{$contig})."...\n";
		if ($known{$contig}) {
			die "FATAL ERROR: FILE NOT SORTED! $contig ALREADY VISITED [$line]\n";
		}

		#CLEANUP
   	    for (keys %physcoverage)    {        delete $physcoverage{$_};     }
		$previous = $contig;
		$known{$contig}++;
		$covTrack='';
		$wrong = 0;
		
		$min = $middle1;
		$max = $middle2;
		for ($i=$middle1; $i<=$middle2; $i++) {
			$coverage{$i}++;
		}	
	}
}
print STDERR " End. $totalChrs sequences analyzed.\n";

sub printstatus {
my $line= shift;
unless ($line%$printevery) {
		$t = time()-$^T;
		$lps = int($line/$t);
		$t = formatsec($t);
		print STDERR " [READING_STATUS] $line lines\t$t\t$lps l/s\n";
	}
}

sub formatdna {
	my $s = shift;
	my $formatted;
	my $line = 70; # change here
	for ($i=0; $i<length($s); $i+=$line) {
		my $frag = substr($s, $i, $line);
		$formatted.=$frag."\n";
	}
	return $formatted;
}
sub formatsec { 
  my $time = shift; 
  my $days = int($time / 86400); 
   $time -= ($days * 86400); 
  my $hours = int($time / 3600); 
   $time -= ($hours * 3600); 
  my $minutes = int($time / 60); 
  my $seconds = $time % 60; 
 
  $days = $days < 1 ? '' : $days .'d '; 
  $hours = $hours < 1 ? '' : $hours .'h '; 
  $minutes = $minutes < 1 ? '' : $minutes . 'm '; 
  $time = $days . $hours . $minutes . $seconds . 's'; 
  return $time; 
}

sub samsize {
	my $f = shift;
	my %x;
	my $cnt;
	my $len;
	open (F, "$f")|| return 0;
	while (<F>) {
		if ($_=~/^\@/) {

			if ($_=~/SN:(\w+)\s+LN:(\d+)/) {
				$x{$1}=$2;
				$cnt++;
				$len+=$2;
			}
		} else {
			last;
		}
	}
	close F;
	my $tot = bp($len);
	print STDERR " SAM header: $cnt sequences found ($tot).\n";
	return %x;
}

sub bp {
	 my $i = shift;
	if ($i<1000)  {
           return "$i bp";
        } elsif ($i<1000*1000) {
           return sprintf("%.2f", $i/1000).' kbp';
        } elsif ($i<1000*1000*1000) {
	   return sprintf("%.2f", $i/1000000).' Mbp';
        } elsif ($i<1000*1000*1000*1000) {
	   return sprintf("%.2f", $i/1000000000).' Gbp';
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
#foreach my $cnt (keys %known) {
#	my $warn = 'OK';
#	$warn = 'BAD' if $wrong{$cnt};
	
#	print "$cnt\t$warn\t$wrong{$cnt}\n";
#}
