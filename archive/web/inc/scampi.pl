#!/usr/bin/env perl

use DBI;
use Getopt::Long;

use File::Basename;
my $dirname = dirname(__FILE__);

$div = $dirname.'/divorce.pl';
$dbfile  = $dirname.'/db_con.php';

$arctable='arcs';
$minsigma=90;
$max_cov  = 55 if (!$max_cov);
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
  	-s   STRING     Seed contig
  	-cov INT        Maximum contig coverage [$max_cov]
  	-arc INT        Minimum amount of mates per arc [$min_arcs]
  	-con INT        Minimum percentage of concordance [$minsigma]
  	-fil FILE       Scampi optional module [$fil], optional
  	-html           Output in HTML format (for web interface)

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
  'html'       => \$html
);
if ($filler eq 'NO') {
	print STDERR " [Filler] Additional module excluded.\n";
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
	$opt = "| perl $filler STDIN $min_arcs $max_cov $host $user $pass $db";
}

die " FATAL ERROR:\n Missing -s parameter!\n" unless ($seed);
$cmd1 = "perl $div -db $dbfile -s $seed -dir 5 -cov $max_cov -arc $min_arcs -con $minsigma 2>/dev/null $opt";
$cmd2 = "perl $div -db $dbfile -s $seed -dir 3 -cov $max_cov -arc $min_arcs -con $minsigma 2>/dev/null $opt";
print STDERR " [Command] $cmd1\n";
@list_1 = `$cmd1`;
print STDERR " [Command] $cmd2\n";
@list_2 = `$cmd2`;

@scaffold_list = (@list_1, @list_2);

foreach $contig (@scaffold_list) {
	chomp($contig);
	print "$contig\n";
}


