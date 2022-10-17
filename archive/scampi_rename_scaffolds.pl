#!/usr/bin/perl
use DBI;

print STDERR "
--	+-------------------------------------------------------+
--	|              Rename scaffolds by size                 |
--	+-------------------------------------------------------+
--  Parameter: mysql-host chromosomename scaffoldname
";

($host, $c, $s) = @ARGV;
die " Specify at lest 'dbhostname'.\n" unless "$host";
$host     = $host || 'localhost';
$chrname  = $c || 'chr';
$scname   = $s || 'scf';
$dbname   = 'nannov1';
$username = '4ngs';
$password = 'nannochloropsis';
$dbh      = DBI->connect("DBI:mysql:$dbname;host=$host", "$username", "$password", { RaiseError => 1 });

@sortedscaffolds = getScaffolds();
my $n = length($#sortedscaffolds+1);
print STDERR "-- Items $#sortedscaffolds, $n\n";
my $ccount;
my $scount;
foreach my $s (@sortedscaffolds) {
		my $newname;
		if ($s=~/^C/i) {
				$ccount++;
				$newname = $chrname.sprintf("%0$n\d",$ccount);
				print STDERR "-- Rename $s\t=>\t$newname\n";
				
		} else {
				$scount++;
				$newname = $scname.sprintf("%0$n\d",$scount);
				print STDERR "-- Rename $s\t->\t$newname\n";
				
		}
		my $query = "UPDATE scaffolds SET scaffold='$newname' WHERE scaffold='$s';";
		print STDERR "$query\n";
		my $sth = $dbh->prepare("$query");
		$sth->execute();
}

sub getScaffold {
	my ($scaffold, $direction) = @_;
	my @scaffold;
	my $order;
	if ($direction eq 'C') {
		$order = 'DESC';
	}
	my $query = "SELECT * FROM scaffolds WHERE scaffold='$scaffold' ORDER BY position $order";
	my $sth = $dbh->prepare("$query");
	$sth->execute();
	while (my $result = $sth->fetchrow_hashref()) {
		$contig    = $result->{contig};
		my $direction;
		$direction = '+' if ($result->{direction} eq 'U');
		$direction = '-' if ($result->{direction} eq 'C');
		$gap       = $result->{gap};
		push(@scaffold, "$contig:$gap$direction");
	}
	
	return @scaffold;
}

sub getScaffolds {
	my @scaffolds;
	my $cnt;
	my $query = "SELECT s.scaffold FROM scaffolds AS s, contigs AS c WHERE (c.name = s.contig) GROUP BY s.scaffold ORDER BY sum(c.len) DESC;";
	my $s = $dbh->prepare("$query");
	$s->execute();
	while (my $result = $s->fetchrow_hashref()) {
			$cnt++;
			push(@scaffolds, $result->{scaffold});
	}
	print STDERR "-- $cnt scaffolds found in database.\n";
	return @scaffolds;	
}
