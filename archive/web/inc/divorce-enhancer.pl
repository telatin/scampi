#!/usr/bin/perl
use DBI;

$lowArcs=6;
$minsigma=90;
use File::Basename;
my $dirname = dirname(__FILE__);
$dbfile = $dirname.'/db_con.php';
print STDERR "
   -------------------------------------
   SCAFFOLD FILLER beta2
   -------------------------------------
   parameters:
   input_file min_arcs max_coverage
   -------------------------------------
";
%long=();
($input_file, $min_arcs, $max_cov, $host, $user, $pwd, $db) = @ARGV;

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
	#die " Missing parameter -db\n\n";
	$dbh = DBI->connect("DBI:mysql:$db;host=$host", $user, $pwd, {RaiseError => 1 } ) || print "error";
}

$min_arcs = 10 unless ($min_arcs);
$max_cov  = 200 unless ($max_cov);
$CX='';
die "Missing parameter.\n" if (!$max_cov);


($list_array, $dir_array) = parsefile($input_file);
my (@list) = @$list_array;
my (@dir)  = @$dir_array;

for ($i=0; $i<$#list; $i++) {
	$l=end2dir($dir[$i]);
	#print STDERR " ***** Node: $list[$i] ($dir[$i]) ---> $list[$j]\n";
	print "$list[$i]$l\t$long{$list[$i]}\n";
	#print $long{"$i"}."\n";
	my ($cover, $size) = getcontiginfo($list[$i]);
	$TOTALSIZE+=$size;
	
	my $j = $i+1;
	firstseeds($list[$i], $dir[$i], $list[$j], ());	
	foreach $id (sort {length($path{$a}) <=> length($path{$b}) } keys %path) {
		
		#print "$id\t[$list[$i]] -> $path{$id} -> [$list[$j]]\n";	
		$P=$path{$id};
	}
	@added=split(/[;,\.]/, $P);
	foreach $c (@added) {
		$c2=uc($c);
		print "$c2$mydirection{$c}\t$long{$c}\n";	
		my ($cover, $size) = getcontiginfo($c);
		$TOTALSIZEADDED+=$size;
	}
	$K=end2dir($dir[$j]);
	print "$list[$j]$K\t$long{$list[$j]}\n" if ($i+1 == $#list);
	$CX=0;
	$P='';
	%path=();
}
$NOW = int(($TOTALSIZE+$TOTALSIZEADDED));
print STDERR "
Started with: $TOTALSIZE bp 
Added new:    $TOTALSIZEADDED bp
New size:     $NOW bp\n";

sub firstseeds {
	my ($contig, $direction, $next) = @_;
	($coverage, $size) = getcontiginfo($contig);	
	#print STDERR "SHIT $coverage X <- $contig\n" if ($coverage > $max_cov);
	my $c;
	my $hashref = getarcs($contig, $direction);
	foreach $cntg (keys %{$hashref}) {
		$tot_arcs = ${$hashref}{$cntg};
		($nextcontig, $nextdirection) = split ( /,/, $cntg);
		$goto=c($nextdirection);
		if ($tot_arcs < $min_arcs) {
			next;	
		}

		if (dejavu($nextcontig)) {
			#print STDERR "1: $contig -> $nextcontig*\n";	
			next;
		} else {
				
			$c++;
			#print STDERR "1: $contig -> $nextcontig...\n";
			#                                      from
			$goto=c($nextdirection);
			#print STDERR "1> $goto".end2dir($goto)."\n";
			$mydirection{$nextcontig}=end2dir($goto);
			secondseed($nextcontig, $goto, $next, $contig);
		}
	}

}

sub secondseed {
	my ($contig, $direction, $next, $from, @track) = @_;
	($coverage, $size) = getcontiginfo($contig);	
	return 0 if ($coverage > $max_cov);
	$CX++;
	my $c;
	my $hashref = getarcs($contig, $direction);
	foreach $cntg (keys %{$hashref}) {
		$tot_arcs = ${$hashref}{$cntg};
		($nextcontig, $nextdirection) = split ( /,/, $cntg);

		if ($tot_arcs < $min_arcs) {
			#pochi archetti
			
			next;	
		}
		if (dejavu($nextcontig)) {
		   #print STDERR "2: $from -> $contig -> $nextcontig*\n"; 
		   
		   $path{$CX}= "$contig" if ($nextcontig eq $next);
		   next;	
		} else {
				$goto=c($nextdirection);
				#print STDERR "2> $goto".end2dir($goto)."\n";
			 	#print STDERR "2: $from -> $contig -> $nextcontig...\n"; 
			 	$mydirection{$nextcontig}=end2dir($goto);
			 	thirdseed($nextcontig, $goto, $next, $from, $contig);
		}
	
}

}


sub thirdseed {
	my ($contig, $direction, $next, $from2, $from) = @_;
	($coverage, $size) = getcontiginfo($contig);	
	return 0 if ($coverage > $max_cov);
	my $c;
	$CX++;
	my $hashref = getarcs($contig, $direction);
	foreach $cntg (keys %{$hashref}) {
		$tot_arcs = ${$hashref}{$cntg};
		($nextcontig, $nextdirection) = split ( /,/, $cntg);
		$goto=c($nextdirection);
		
		if ($tot_arcs < $min_arcs) {
			#pochi archetti
			next;	
		}
		if (dejavu($nextcontig)) {
			#print STDERR "3: $from2 -> $from -> $contig -> $nextcontig*\n";
			
			$path{$CX}= "$from;$contig" if ($nextcontig eq $next);
			next;
		} 
		#print STDERR "3> $goto".end2dir($goto)."\n";
		$mydirection{$nextcontig}=end2dir($goto);
		fourthseed($nextcontig, $goto, $next, $from2, $from, $contig);
	}
}

sub fourthseed {
	my ($contig, $direction, $next, $from3, $from2, $from) = @_;
	($coverage, $size) = getcontiginfo($contig);	
	return 0 if ($coverage > $max_cov);
	my $c;
	$CX++;
	my $hashref = getarcs($contig, $direction);
	foreach $cntg (keys %{$hashref}) {
		$tot_arcs = ${$hashref}{$cntg};
		($nextcontig, $nextdirection) = split ( /,/, $cntg);
		$goto=c($nextdirection);
		$mydirection{$nextcontig}=end2dir($goto);
		#print STDERR "4> $goto".end2dir($goto)."\n";
		if ($tot_arcs < $min_arcs) {
			#pochi archetti
			next;	
		}
		if (dejavu($nextcontig)) {
			#print STDERR "4: $from3 -> $from2 -> $from -> $contig -> $nextcontig*\n";
			
			$path{$CX}= "$from2;$from;$contig"  if ($nextcontig eq $next);
			next;
		} 
		#print "4++: $from3, $from2, $from, $contig, $nextcontig.......?\n";
}

}


sub dejavu {
	my $c = shift;
	if 	(grep {$_ eq $c} @list) {
		
		return 1;
	}
	else {
		
		
		return 0;	
	}
}


sub getcontiginfo {
	my $c = shift;
	$query = "SELECT ROUND(cov) as cov, len, scaffold, sid FROM contigs WHERE name like '%$c'";
	$query_handle = $dbh->prepare($query);
	$query_handle->execute();
	$query_handle->bind_columns(\$cov, \$len, \$sc, \$sid);
	$query_handle->fetch();
	$long{$c}=$cov."X\t$len\t$sc\t$sid";
	return ($cov, $len, $sc, $sid);	
}

sub getarcs {
	
	my ($c, $d) = @_;
	my %arcs    = ();
	my %nextend = ();
	#print STDERR "> $c [$d] \n";
	$query = "SELECT lib, c1, end1 AS e1, c2, end2 AS e2, arcs 
				FROM arcs 
				WHERE (arcs > $lowArcs) and (c1 LIKE '$c' OR c2 LIKE '$c') AND (sigma > $minsigma) 
				ORDER BY lib DESC";
				

	$query_handle = $dbh->prepare($query);
	$query_handle->execute();
	$query_handle->bind_columns(\$lib, \$c1, \$e1, \$c2, \$e2, \$arcs);
	while($query_handle->fetch()) {
			($from, $to, $newcont) = sortresult($c, $c1, $c2, $e1, $e2);
			next if ($from != $d);
			$arcs{"$newcont,$to"}+=$arcs;
			$nextend{$newcont}=$to;
			
	}
	$query_handle->finish();
	return \%arcs;	
}

sub sortresult {
	my $C;
	my $TO;
	my $FROM;
	
	my ($contig_name, $c1, $c2, $e1, $e2) = @_;
	if ($contig_name eq $c1) {
		$C    = $c2;
		$TO   = $e2;
		$FROM = $e1;
	} elsif ($contig_name eq $c2) {
		$C    = $c1;
		$TO   = $e1;
		$FROM = $e2;	
	} else {
		print STDERR "Everything is wrong";
		
	}
	
	
	return ($FROM, $TO, $C);
}

sub parsefile {
	## --> filename
	## --> @list_of_contigs, @list_of_ends
	my $file = shift;
	my (@list, @dir);
	if ($file eq 'STDIN') { 
	while (<STDIN>) {
		chomp;
		my @fields = split(/\t/, $_);
		$dir=chop($fields[0]);
		my $end = dir2end($dir);
		push(@list, lc($fields[0]));
		$long{$fields[0]}=$fields[1]."\t".$fields[2]."\t".$fields[3]."\t".$fields[4];
		push(@dir,  $end);
		$line_count++;			
	}	
	} else {
	open I, $file || die "FATAL ERROR: Unable to open input file ($file).\n$!\n";

	
	while (<I>) {

		chomp;
		my @fields = split(/\t/, $_);
		$dir=chop($fields[0]);
		my $end = dir2end($dir);
		push(@list, lc($fields[0]));
		$long{$fields[0]}=$fields[1]."\t".$fields[2]."\t".$fields[3]."\t".$fields[4];
		push(@dir,  $end);
		$line_count++;	
	
	}
	close I;
	}
	print STDERR "$file -> $line_count lines parsed.\n";
	return (\@list, \@dir);
}

sub dir2end {
	my $dir = shift;
	if ($dir eq 'U') {
		return 3;
	} elsif ($dir eq 'C') {
		return 5;
	} else {
		return 0;
	}	
}
sub end2dir {
	my $dir = shift;
	if ($dir == 3) {
		return 'U';
	} elsif ($dir == 5) {
		return 'C';
	} else {
		return '_';
	}	
}


sub c {
	my $a = shift;
	if ($a==5) {return 3;} else {return 5;}
}

