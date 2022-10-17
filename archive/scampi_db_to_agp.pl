#!/usr/bin/perl
use DBI;
use Getopt::Long;
$dbfile = 'web/inc/db_con.php';
print STDERR "
	+-------------------------------------------------------+
	|           Database to AGP/FASTA dumper v1.03          |
	+-------------------------------------------------------+
	  -d  FILE     Database config [$dbfile]
	  -o  FILE     Output base name
	  -c  FILE     Contigs file
	  -t  STRING   Prefix for scaffolds
	+-------------------------------------------------------+

";

$opt = GetOptions (
  'd=s'       => \$dbfile,
  'o=s'       => \$output,
  'c=s'       => \$contigsfile,
  't=s'       => \$tag
 );
 
if (-e $dbfile) {
    open (I, "$dbfile") || die "Unable to open db file: $dbfile.\n";
	while (<I>) {
		
		if ($_=~/scampi_(\w+)="(\w+)"/) {
			${$1} = $2;
		}
	}
	$dbh = DBI->connect("DBI:mysql:$db;host=$host", $user, $pass, { RaiseError => 1 } ) || error("error mysql");
	print STDERR " [MySQL] Connected to '$user'\@'$host'.\n";

} else {
    die " FATAL ERROR:\n DB file not found: $dbfile\n\n";
}

die " FATAL ERROR:
 Missing parameters.\n" unless ($output);



# TEST FILE RW
open(I,   "$contigsfile")          || die " FATAL ERROR: \n Unable to load contigs file: $contigsfile.\n";
open(AGP, ">$output.agp")          || die " FATAL ERROR: \n Unable to write AGP file: $output.agp.\n";
open(FNA, ">$output.fsa")          || die " FATAL ERROR: \n Unable to write Fasta file: $output.fsa.\n";
open(SCA, ">$output.scaffolds.fsa")|| die " FATAL ERROR: \n Unable to write Fasta file: $output.scaffolds.fsa.\n";

my @aux = undef;
while (my ($name, $seq, $qual) = readfq(\*I, \@aux)) {
	$seq{$name} = $seq;
	$len{$name} = length($seq);
	$countseq++;
	$countlen+=   length($seq);
}
%printed = ();

print STDERR " Contigs file loaded: $countseq sequences, $countlen bp.\n";

@scaffolds = getScaffolds();
print STDERR " Printing scaffolds: $#scaffolds\n";
foreach my $scaffold (@scaffolds) {
	$snumber++;
	my $cnumber;
	my $position = 1;
	my @contiglist = getScaffold($scaffold);
	print SCA ">$scaffold\n";
	$scaffoldseq='';
	foreach my $item (@contiglist) {
		$used{$item}++;
		$cnumber++;
		$direction = chop($item);
		($contig, $gap) = split /:/, $item;
		if ($gap == 0) {
				$gap = $defaultgap;
				$gaptype = 'U';
		} else {
				$gaptype = 'N';
		}
		$gap = 10 if ($gap < 10);
		$to = $position + $len{$contig} - 1;
		die " FATAL ERROR: Unable to find $contig in FASTA file. Needed by scaffold $scaffold ($cnumber).\n" unless length($seq{$contig});
		if ($printed{$contig} == 0) {
			print FNA ">$contig\n".formatdna($seq{$contig});
			$printed{$contig}++;
		}
		if ($direction eq '+') {
			$scaffoldseq.=$seq{$contig};
		} else {
			$scaffoldseq.=rc($seq{$contig});
		}
		print AGP "$tag$scaffold\t$position\t$to\t$cnumber\tW\t$contig\t1\t$len{$contig}\t$direction\n";
		
		next if ($item eq $contiglist[$#contiglist]);
		# Prepare GAP
		$position = $to+1;
		
		$to = $position + $gap - 1;
		$scaffoldseq.='N' x $gap;
		$cnumber++;
		print AGP "$tag$scaffold\t$position\t$to\t$cnumber\t$gaptype\t$gap\tscaffold\tyes\tpaired-ends\n";
		$position = $to+1;
# 		EG1_scaffold2	1	    40448	1	W	AADB02037552.1	1			40448		+
# 		EG1_scaffold2	40449	40661	2	N	213	            scaffold	yes			paired-ends
# 		EG1_scaffold2	40662	117642	3	W	AADB02037553.1	1			76981		+
# 		EG1_scaffold2	117643	117718	4	N	76	            scaffold	yes			paired-ends
# 		EG1_scaffold2	117719	145387	5	W	AADB02037554.1	1			27669		+
# 		EG1_scaffold2	145388	145485	6	N	98				scaffold	yes			paired-ends
# 		EG1_scaffold2	145486	148437	7	W	AADB02037555.1	1			2952		+
# 		EG1_scaffold2	148438	148560	8	N	123				scaffold	yes			paired-ends
	}
	print SCA formatdna($scaffoldseq);
}

@contigslist = getContigs();

print STDERR " Printing spare contigs: $#contigslist + 1\n";
foreach my $contig (@contigslist) {
	$dbcnt++;
	next if ($printed{$contig});
	$notprinted++;
	if ($seq{$contig}) {
		$hasSeq++;
		my $size = length($seq{$contig});
		print AGP "$tag$contig\t1\t$size\t1\tW\t$contig\t1\t$size\t+\n";
		print FNA ">$contig\n".formatdna($seq{$contig});
		print SCA ">$tag$contig\n".formatdna($seq{$contig});
		$printed{$contig}++;
	}
}
print STDERR " $dbcnt contigs in DB, $notprinted not in scaffold, $hasSeq found in fasta file.\n";



sub getContigs {
	my @scaffolds;
	my $cnt;
	my $query = "SELECT name FROM contigs";
	my $s = $dbh->prepare("$query");
	$s->execute();
	while (my $result = $s->fetchrow_hashref()) {
			$cnt++;
			push(@scaffolds, $result->{name});
	}
	print STDERR " $cnt scaffolds found in database.\n";
	return @scaffolds;	

}

sub rc {
	my $s = shift;
	$s = reverse($s);
	$s=~tr/ACGTacgt/TGCAtgca/;
	return $s;
}
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
sub getScaffold {
	my ($scaffold, $direction) = @_;
	my @scaffold;
	my $order;
	if ($direction eq 'C') {
		$order = 'DESC';
	}
	my $query = "SELECT * FROM contigs WHERE scaffold='$scaffold' ORDER BY sid $order";
#	my $query = "SELECT * FROM scaffolds WHERE scaffold='$scaffold' ORDER BY position $order";
	my $sth = $dbh->prepare("$query");
	$sth->execute();
	while (my $result = $sth->fetchrow_hashref()) {
		#was {contig}
		$contig    = $result->{name};
		my $direction;
		#was {direction}
		$direction = '+' if ($result->{dir} eq 'U');
		$direction = '-' if ($result->{dir} eq 'C');
#		$gap       = $result->{gap};
		push(@scaffold, "$contig:$gap$direction");
	}
	
	return @scaffold;
}

sub getScaffolds {
	my @scaffolds;
	my $cnt;
	
	#new
	my $query = "SELECT scaffold FROM contigs GROUP BY scaffold";
	#my $query = "SELECT scaffold FROM scaffolds GROUP BY scaffold";
	my $s = $dbh->prepare("$query");
	$s->execute();
	while (my $result = $s->fetchrow_hashref()) {
			$cnt++;
			push(@scaffolds, $result->{scaffold});
	}
	print STDERR " $cnt scaffolds found in database.\n";
	return @scaffolds;	
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

sub printexample {

print <<END
##agp-version	2.0
# ORGANISM: Homo sapiens
# TAX_ID: 9606
# ASSEMBLY NAME: EG1
# ASSEMBLY DATE: 09-November-2011
# GENOME CENTER: NCBI
# DESCRIPTION: Example AGP specifying the assembly of scaffolds from WGS contigs
EG1_scaffold1	1	3043	1	W	AADB02037551.1	1	3043	+
EG1_scaffold2	1	40448	1	W	AADB02037552.1	1	40448	+
EG1_scaffold2	40449	40661	2	N	213	scaffold	yes	paired-ends
EG1_scaffold2	40662	117642	3	W	AADB02037553.1	1	76981	+
EG1_scaffold2	117643	117718	4	N	76	scaffold	yes	paired-ends
EG1_scaffold2	117719	145387	5	W	AADB02037554.1	1	27669	+
EG1_scaffold2	145388	145485	6	N	98	scaffold	yes	paired-ends
EG1_scaffold2	145486	148437	7	W	AADB02037555.1	1	2952	+
EG1_scaffold2	148438	148560	8	N	123	scaffold	yes	paired-ends
EG1_scaffold2	148561	152709	9	W	AADB02037556.1	1	4149	-
EG1_scaffold2	152710	153074	10	N	365	scaffold	yes	paired-ends
EG1_scaffold2	153075	158982	11	W	AADB02037557.1	1	5908	+
EG1_scaffold2	158983	163333	12	N	4351	scaffold	yes	paired-ends
EG1_scaffold2	163334	172851	13	W	AADB02037558.1	1	9518	+
EG1_scaffold2	172852	172894	14	N	43	scaffold	yes	paired-ends
EG1_scaffold2	172895	213547	15	W	AADB02037559.1	1	40653	+
EG1_scaffold2	213548	213664	16	N	117	scaffold	yes	paired-ends
EG1_scaffold2	213665	226801	17	W	AADB02037560.1	1	13137	+
EG1_scaffold2	226802	227200	18	N	399	scaffold	yes	paired-ends
EG1_scaffold2	227201	230202	19	W	AADB02037561.1	1	3002	+
EG1_scaffold2	230203	230907	20	N	705	scaffold	yes	paired-ends
END
}
