#!/usr/bin/perl
use DBI;
use Pod::Usage;
use Getopt::Long;
use File::Basename;
$errors_sql='0';
$this_program = basename($0);
$short_usage  = "-s scaffoldname -dir directory -d dbconf.php -o outputfile [-html]"; # [X] Change this
$printlines = 50000;

our $VERSION = 1.00;
our $AUTHOR  = 'Andrea Telatin <andrea@telatin.com>';

$minqual = 12;
my $result = GetOptions(
	's=s'     => \$s,
	'dir=s'   => \$directory,
	'o=s'     => \$output,
	'db=s'  => \$dbfile,
	'version' => \$opt_version,
	'html'    => \$html,
	'help'    => \$opt_help
);

# VERSION
$opt_version && version();
pod2usage({-exitval => 0, -verbose => 2}) if $opt_help;
die usage() unless ($s);

print STDERR "
$s|$directory|$output|$dbfile<br>
";
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

open(O, ">$output") || die "FATAL ERROR: Unable to write to $output.\n";

$msg.="Conversion <b>$s</b> started...<br>";

if ($s eq 'all') {
	my $query = "SELECT scaffold FROM contigs WHERE NOT ISNULL(scaffold) GROUP BY scaffold";
	my $query_handle = $dbh->prepare($query);
	$query_handle->execute();
	
	while (my $result = $query_handle->fetchrow_hashref()) {
		$cntscf++;
		my $is = $result->{scaffold};
		print O ">$is\n" if ($is);
		print O printscaffold($is);
	}
	
	$msg.="<p>$cntscf scaffold(s) converted</p>";
} else {
	print O ">$s\n";
	print O printscaffold($s);
	$msg.="<p>Scaffold $s converted</p>";
	
}

print $msg;




sub printscaffold {
	
	my $name = shift;
	return unless ($name);
	my $query = "SELECT name, dir FROM contigs WHERE scaffold='$name' ORDER BY sid ASC";
	my $scaffold;
	my $query_handle = $dbh->prepare($query);
	$query_handle->execute();
	while (my $result = $query_handle->fetchrow_hashref()) {
		
		my $contig = $result->{name};
		my $dir = $result->{dir};
	 	
	 	my $c;
	 	my $seq;
	 	open(I, "$directory/$contig.fa") || die " Unable to reads $directory/$contig.fa file\n";
	 	while (<I>) {
	 		$c++;
		 	next if ($c==1);
		 	chomp;
		 	$seq.=$_; 
	 	}
	 	$seq = revdnacomp($seq) if ($dir eq 'C');
	 	$scaffold.=$seq.'NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN';
	}
	return formatdna($scaffold);
}




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
sub revdnacomp {
 
 
  my $dna = shift;  

  my $revcomp = reverse($dna);
  $revcomp =~ tr/ACGTacgt/TGCAtgca/;
  return $revcomp;
}
sub sqlerror {
	print STDERR " [SQL ERROR] when trying '$_[0]'.\n";
	$errors_sql++;
}

sub version {
    # Display version if needed
    die "$this_program $VERSION ($AUTHOR)\n";
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


