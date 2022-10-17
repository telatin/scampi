#!/usr/bin/perl
use Getopt::Long;
use File::Basename;
($progname,$progpath,$suffix) = fileparse($0);

print STDERR
"
 ---------------------------------------------
 | ScaMPI TOOLS                              |
 | arcs2table: populate arcs mysql table     |
 ---------------------------------------------

 Usage: cat arcsfile | $progname [parameters] > outputfile.sql
 Or:    $progname -f arcsfile [parameters] > output.sql

 -f input_file Arcs file (produced by ScaMPI)
 -t table_name MySQL table name (default: 'arcs');
 -l lib_name   Tag for library (default: '1');
 -head         Print DROP AND CREATE TABLE statement
               (only for first library, default off)
";


$t = 'arcs';
$l = '1';

$opt = GetOptions (
  'f=s'       => \$file_name,    
  't=s'       => \$table_name,
  'l=s'       => \$lib_name,
  'head'      => \$header
);

if ($file_name) {
	die " FATAL ERROR:\n Input file '$file_name' can't be accessed.\n" unless (-e $file_name);
	open (STDIN, "$file_name") || die " FATAL ERROR:\n Can't read input file $file_name.\n";
}


print_header($table_name) if ($header);

while (<STDIN>) {
	@f = split /\t/;
	$c++;
	next if ($c<2);
	die " WRONG FORMAT: End1 and End2 have to be either 5 or 3.

 We expect a tab delimited file with these fields:
 Contig1  Contig2  End1  End2  Distance  Concordance  ArcsNumber.\n" if (($f[2] != 5 and $f[2] != 3) or ($f[3] != 5 and $f[3] != 3));

	print "INSERT INTO $table_name (lib, c1, c2, end1, end2, dist, sigma, arcs) VALUES
  ($lib_name,\"$f[0]\", \"$f[1]\", '$f[2]', '$f[3]', '$f[4]', '$f[5]', '$f[6]' );\n";
  #Library     Contig    Contig     End1     End2     Distance  Sigma   Arcs
}

print STDERR "
  $c lines parsed. All done.\n";

sub print_header {

print "
DROP TABLE IF EXISTS $table_name;
CREATE TABLE $table_name ( 
	id		INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	lib		INT,
	c1		VARCHAR(200), 
	c2		VARCHAR(200), 
	end1		INT, -- orientation 5 or 3
	end2		INT, -- orientation 5 or 3
	dist		INT,
	sigma		INT,
	arcs		INT,
	comments	VARCHAR(200));
";	
return 1;
}
