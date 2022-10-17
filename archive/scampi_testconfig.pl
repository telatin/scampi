#!/usr/bin/env perl
use DBI;

use Getopt::Long;
print STDERR
"
 -----------------------------------------------------------------------
 | ScaMPI TOOLS                                                        |
 | Test project file                                                   |
 -----------------------------------------------------------------------

";

$opt = GetOptions (
  'i=s'       => \$file
);

open (I, "$file") || die " FATAL ERROR:\n Unable to read configuration file: $file.\n";

while (<I>) {
	chomp;
	if ($_=~/scampi_(\w+)=(\w+);/) {
		${$1} = $2;
		$c++;
	}
}

print STDERR " Opening: $file
 File parsed: $c variables found.\n";

die " FATAL ERROR:\n Configuration file not valid\n" if ($c<4);

$dbh = DBI->connect("DBI:mysql:$db;host=$host", "$user", "$pass", { RaiseError => 1 } ) || die " FATAL ERROR: MySQL connection failed.\n$!\n";

print STDERR " Connection to $db: ok\n\n";
$query = "SHOW TABLES;";

$query_handle = $dbh->prepare($query);
$query_handle->execute();
$query_handle->bind_columns(\$lib);
while($query_handle->fetch()) {
	$X++;
	print "\tFOUND_TABLE $X: $lib\n";

}
print STDERR "\n $X TABLES FOUND IN DB '$db'.\n";

