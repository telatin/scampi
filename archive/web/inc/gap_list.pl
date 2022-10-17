#!/usr/bin/env perl

use DBI;
use Getopt::Long;

use File::Basename;
my $dirname = dirname(__FILE__);

$dbfile  = $dirname.'/db_con.php';
print STDERR "
    ___          __  __ ___ ___ 
   / __| __ __ _|  \\/  | _ \\_ _|
   \\__ \\/ _/ _\` | |\\/| |  _/| | 
   |___/\\__\\__,_|_|  |_|_| |___|
  -------------------------------------------------------------------------------
  GAP LIST                       CRIBI Biotech Center 2007
  -------------------------------------------------------------------------------
  	-db  FILE       Configuration file for MySQL connection [$dbfile]
  	
  -------------------------------------------------------------------------------

";

$opt = GetOptions (
  'db=s'       => \$dbfile,

);


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

$q = "SELECT scaffold FROM contigs WHERE NOT ISNULL(scaffold) GROUP BY scaffold";
$h = $dbh->prepare($q);
$h->execute();
$h->bind_columns(\$scaffold);
while ($h->fetch()) {
	$stot++;
	push(@s, $scaffold);
}
print STDERR "$stot scaffolds found.\n";

foreach my $i (@s) {
	print STDERR "scaffold $i...\n";
	my $q = "SELECT name, len, sid, dir FROM contigs WHERE scaffold='$i' ORDER BY sid";
	my $h = $dbh->prepare($q);
	$h->execute();
	$h->bind_columns(\$name, \$size, \$sid,\$dir);
	my $prev;
	my $p_d;
	my $p_s;
	my $p_i;
	while ($h->fetch()) {
		print STDERR "\t -> $name$dir\n";
		if ($prev) {
			print "$prev$dir\t$name$dir\t$p_s\t$size\t$scaffold\t$p_i\n";
		}
		$prev = $name;
		$p_d  = $dir;
		$p_s  = $size;  
		$p_i  = $sid;
	}
	
}
