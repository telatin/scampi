#!/usr/bin/env perl

use DBI;
use Getopt::Long;

use File::Basename;
my $dirname = dirname(__FILE__);

$div = $dirname.'/divorce.pl';
$dbfile  = $dirname.'/db_con.php';
$minlen = 1000;
$arctable='arcs';
$minsigma=90;
$max_cov  = 80 if (!$max_cov);
$min_arcs = 12 if (!$min_arcs);
$dir 	  = 3  if (!$dir);
print STDERR "
    ___          __  __ ___ ___ 
   / __| __ __ _|  \\/  | _ \\_ _|
   \\__ \\/ _/ _\` | |\\/| |  _/| | 
   |___/\\__\\__,_|_|  |_|_| |___|
  -------------------------------------------------------------------------------
  SCAFFOLDING FROM SEED                        CRIBI Biotech Center 2007
  -------------------------------------------------------------------------------
  	-db  FILE       Configuration file for MySQL connection [$dbfile]
  	-div FILE       Scampi core module [$div]
  	-cov INT        Maximum contig coverage [$max_cov]
  	-arc INT        Minimum amount of mates per arc [$min_arcs]
  	-con INT        Minimum percentage of concordance [$minsigma]
  	-fil FILE       Scampi optional module [$fil], optional
  	
  	-write          Save scaffold in DB
  	-rewrite        Erase all previous info and save scaffold in DB
  -------------------------------------------------------------------------------

";

$opt = GetOptions (
  'db=s'       => \$dbfile,
  'fil=s'      => \$filler,
  'div=s'      => \$div,
  's=s'        => \$seed,
  'dir=i'      => \$dir,
  'cov=f'      => \$max_cov,
  'arc=i'      => \$min_arcs,
  'con=f'      => \$minsigma,
  'html'       => \$html,
  'write'      => \$write,
  'rewrite'    => \$rewrite,
  'web=s'        => \$web
);

if ($web) {
	$webpercentage = 1;
	open WEB, ">/tmp/ScaMPI_Progress_$web.txt";
}
if ($filler eq 'NO') {
	print STDERR " [Filler] Additional module excluded.\n";
	$filler = '';
} else {
	unless ($filler) {
	$filler = $div;
	$filler=~s/divorce/divorce-enhancer/;
}
}

die " FATAL ERROR:\n Unable to locate core module -div\n" unless (-e $div);
if (-e $dbfile) {
    open (I, "$dbfile") || die "Unable to open db file.\n";
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

if (-e $filler) {
	print STDERR " [Filler] Enhancer module found.\n";
	$opt = "| perl $filler STDIN $min_arcs $max_cov $host $user $pass $db 2> /dev/null";
}
web(1, "<b>ScaMPI started.</b> Exploring all connections...");
print STDERR " [SCAMPI] Scaffolding from all possible seeds...\n";
$q = "SELECT name FROM contigs WHERE cov<=$max_cov AND len>$minlen ORDER BY len DESC";
$h = $dbh->prepare($q);
$h->execute();
$h->bind_columns(\$name);
while ($h->fetch()) {
	$pid++;

	push(@contig_list, $name);
	@{$name} = scaffold($name);
	my $count = $#{$name}+1;
	my $ssize = 0;
	foreach my $c (@{$name}) {
		chomp($c);
		($contig, $cov, $size) = split /\t/, $c;
		$dir = chop($contig);
		
		$included{$contig}.=$name.";";
		$included_count{$contig}++;
		$ssize+=$size;
	}

	$webpercentage++ if (!($pid%50) and $webpercentage<80);
	web($webpercentage, "$pid seeds extended. Now extending seed <em>$name</em>...") unless ($pid%100);

	print STDERR " [$pid]\tExtending seed $name:\t$count contigs ($ssize bp) ...    \r";
	$scaf_item{$name}=$count;
	$scaf_size{$name}=$ssize;
}
print STDERR "\n";
print STDERR " [SCAMPI] Removing overlapping scaffolds...\n";
web(81, "<b>All seeds extended</b>. Now removing overlapping scaffolds...");
foreach $scaffold (sort {$scaf_size{$b} <=> $scaf_size{$a}} keys %scaf_size) {
	print STDERR " [Test] $scaffold\t$scaf_size{$scaffold}\n";
	my $good = '';
	my $cnt;
	foreach my $c (@{$scaffold}) {
		$cnt++;
		chomp($c);
		my ($contig, $cov, $size) = split /\t/, $c;
		$dir = chop($contig);
		if ($last{$contig})  {
			#print STDERR " In '$scaffold' contig '$contig' was already visited...\n";
			$good = "$contig $cnt/$scaffold [was $last{$contig}]" ;
			last;
		}
		$last{$contig} = $scaffold;
	}
	if ($good eq '') {
		print STDERR  "\tOK: $scaffold is good\n";
		$sum += $scaf_size{$scaffold};
		$totscaf++;
		push(@good_scaffold, $scaffold);
	} else {
		print  STDERR "\t--: $scaffold skipped ($good)\n";
	}
	
	$webpercentage++ if (!($cnt%20) and $webpercentage<100);
	web($webpercentage, "Still removing overlapping scaffolds...") unless ($cnt%50);

}
web(100, "Finished. $totscaf scaffold produced ($sum bp)");
print  " [DONE] $totscaf scaffolds produced.\n";
print  " [DONE] $sum bp scaffolded in total.\n";

if ($rewrite) {
	$q = "Update contigs Set scaffold = NULL where 1";
	$h = $dbh->prepare($q);
	$h->execute();
	print STDERR " [SQL] Scaffolds erased...\n";
} 

if ($write or $rewrite) {
	foreach my $scaffold (@good_scaffold) {
		print STDERR " [SQL] Writing $scaffold...\n";
		my $id;
		foreach my $c (@{$scaffold}) {
			$id++;
			chomp($c);
			my ($contig, $cov, $size) = split /\t/, $c;
			$dir = chop($contig);	
			$q = "UPDATE contigs SET scaffold = '$scaffold', sid='$id', dir='$dir' WHERE name='$contig'";	
			$h = $dbh->prepare($q);
			$h->execute();
		}
	}
}
exit;

sub scaffold {
	my $seed = shift;
	$cmd1 = "perl $div -db $dbfile -s $seed -dir 5 -cov $max_cov -arc $min_arcs -con $minsigma 2>/dev/null $opt";
	$cmd2 = "perl $div -db $dbfile -s $seed -dir 3 -cov $max_cov -arc $min_arcs -con $minsigma 2>/dev/null $opt";
	#print STDERR " [Command] $cmd1\n";
	my @list_1 = `$cmd1`;
	#print STDERR " [Command] $cmd2\n";
	my @list_2 = `$cmd2`;
	my @scaffold_list = (@list_1, @list_2);
	return @scaffold_list;
}

sub web {
	my ($perc,$string) = @_;
	return 0 unless ($web);
	
	print WEB "$perc|$string\n";

}
