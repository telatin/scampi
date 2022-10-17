#!/usr/bin/perl
use DBI;
use Pod::Usage;
use Getopt::Long;
use File::Basename;
$errors_sql='0';
$this_program = basename($0);
$short_usage  = "-i filename.agp -d dbconf.php [-html]"; # [X] Change this
$printlines = 50000;

our $VERSION = 1.00;
our $AUTHOR  = 'Andrea Telatin <andrea@telatin.com>';

$minqual = 12;
my $result = GetOptions(
	'i|input=s' => \$input,
	'd|db=s'    => \$dbfile,
	'version' => \$opt_version,
	'html' => \$html,
	'help' => \$opt_help
);

# VERSION
$opt_version && version();
pod2usage({-exitval => 0, -verbose => 2}) if $opt_help;
die usage() unless ($input);

# DATABASE CONNECTION
if (-e $dbfile) {
    open (I, "$dbfile") || die " FATAL ERROR 01:\n Unable to open db file: $dbfile.\n";
	while (<I>) {
		
		if ($_=~/scampi_(\w+)="(.+)"/) {
			
			${$1} = $2;
		}
	}
	die " FATAL ERROR 01A:\n No database connection data in $dbfile.\n" unless ($db and $host and $user);
	$dbh = DBI->connect("DBI:mysql:$db;host=$host", $user, $pass, { RaiseError => 1 } ) || error("error mysql");
	print STDERR " [MySQL] Connected to '$user'\@'$host'.\n";

} else {
    die " FATAL ERROR 02:\n DB file not found: $dbfile\n\n";
}


open (I, "$input") || die " FATAL ERROR 04:\n Unable to open input file \"$input\".\n";
my $contigsParsed='0';
my $errors_sql ='0';
while (<I>) {
	$x++;
#EG1_scaffold1   1       3043    1       W       AADB02037551.1  1       3043    +
#EG1_scaffold2   1       40448   1       W       AADB02037552.1  1       40448   +
#EG1_scaffold2   40449   40661   2       N       213     scaffold        yes     paired-ends
#EG1_scaffold2   40662   117642  3       W       AADB02037553.1  1       76981   +
#EG1_scaffold2   117643  117718  4       N       76      scaffold        yes     paired-ends
#EG1_scaffold2   117719  145387  5       W       AADB02037554.1  1       27669   +
#EG1_scaffold2   145388  145485  6       N       98      scaffold        yes     paired-ends
#EG1_scaffold2   145486  148437  7       W       AADB02037555.1  1       2952    +
#EG1_scaffold2   148438  148560  8       N       123     scaffold        yes     paired-ends
#EG1_scaffold2   148561  152709  9       W       AADB02037556.1  1       4149    -
#EG1_scaffold2   152710  153074  10      N       365     scaffold        yes     paired-ends
#	
	chomp;
	my ($scaffold, $from,$to, $item, $tag, $contig, $span0, $span1, $strand)= split /\t/, $_;
	next if ($tag ne 'W');
	next if ($scaffold=~/^#/);
	$contigsParsed++;	

	update($contig, $scaffold, $strand, $item);

	$was = $scaffold;
}
print STDERR "
 [END]  $input imported into 'contigs' database
	
	Contigs     $contigsParsed
	Errors      $errors_sql
";

$msg = "$errors_sql errors found! AGP file seems invalid, as its contig did not match current dataset." if ($errors_sql);
print "<h2>Import of &laquo;$input&raquo;</h2>
<p>$x lines containing $contigsParsed contigs parsed from AGP file. <br>
$msg.</p>" if ($html);
sub update {
	my($contig, $name, $s, $i) = @_;
	my $dir;
	if ($s eq '+') {
		$dir = 'U';
	} else {
		$dir = 'C';
	}
	my $query = "UPDATE contigs SET scaffold=\"$name\",sid=$i,dir=\"$dir\" WHERE name=\"$contig\"";

	$query_handle = $dbh->prepare($query);
	$query_handle->execute() or sqlerror($query);
	
}

sub sqlerror {
	print STDERR " [SQL ERROR] when trying '$_[0]'.\n";
	$errors_sql++;
}

sub version {
    # Display version if needed
    die "$this_program $VERSION ($AUTHOR)\n";
}
 
sub usage {
    # Short usage string in case of errors
    die "SHORT USAGE:\n$this_program  $short_usage\nType --help for instructions.\n";
}
sub strand{
  my $flag = shift;
  my $strand = '+';
  if ($flag & 0x10) {
	  $strand = '-';
  }
  return $strand;		
}
__END__
 
=head1 NAME
 
B<scampi_import_agp> - this program imports scaffolds produced by any scaffolder (AGP format).
 
=head1 AUTHOR
 
Andrea Telatin <andrea@telatin.com>
 
=head1 DESCRIPTION
 


=head1 PARAMETERS
 -i, --input       AGP file to be converted
 -d, --db          ScaMPI database connection file
 
=head1 BUGS
 
Please report them to <andrea@telatin.com>
 
=head1 COPYRIGHT
 
Copyright (C) 2013 Andrea Telatin 
 
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. 
 
You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
=cut


