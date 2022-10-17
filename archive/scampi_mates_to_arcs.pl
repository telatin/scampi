#!/usr/bin/perl

# Make arcs from matepaired SOLiD reads
# Parses the UNIQUE_PAIR_OUT file produced by pass_pair (Davide Campagna)
# and returns arcs connecting contigs 

use Getopt::Long;
use File::Basename;
($selfname,$selfpath) = fileparse($0);


@spin = ('<o  >','< o >','<  o>','< o >');
 
$minarcs   = 3;
$ths       = '0';
$maxlen    = 10**50;

$opt = GetOptions(
	'i|f=s'     => \$uniquepairoutfile,
	'm|minarcs=i' => \$minarcs,
	'c|concordance' => \$ths,
	'l'         => \$maxlen,
	't|test'    => \$stoplines,
	'd|debug'   => \$printinfo,
	'sql'       => \$sql,
	'tab=s'     => \$tab,
	'lib=i'     => \$lib,
	'h|help'    => \$help	
);


print STDERR "
    ___          __  __ ___ ___ 
   / __| __ __ _|  \\/  | _ \\_ _|
   \\__ \\/ _/ _\` | |\\/| |  _/| | 
   |___/\\__\\__,_|_|  |_|_| |___|
  -------------------------------------------------------------------------------
  MATE PAIRS (UNIQUE_PAIR_OUT) to ARCS                  CRIBI Biotech Center 2012
  -------------------------------------------------------------------------------
";

if ($help or !$uniquepairoutfile) {
print STDERR "
  This program parses the UNIQUE_PAIR_OUT output of 'pass_pair' to create 'arcs'
  for scaffolding. Default output is a tabular file as described in the manual.
   
    -i or -f          Input file (UNIQUE_PAIR_OUT from 'pass_pair' (GFF)
    -m, --minarcs     Minimum number of mates to create a connection [$minarcs]
    -c, --concorcance Minimum \% of concordant mates per connection [$ths]
    -l                Maximum length of the connection [off]
    -t, --test        Stop after parsing this number of lines [off]
    -d, --debug       Print a debug column [off]

    To print output in SQL format:
    -tab              MySQL table name (eg: 'arcs')
    -lib              Library id for the MySQL database (eg: '1')
    
    
    -h, --help        Prints this message
    
    Example:
    $selfname -i UNIQUE_PAIR_OUT -c 80 -m 10 > library1.arcs
  -------------------------------------------------------------------------------

";
exit;
}

if (($tab and !$lib) or ($lib and !$tab)) {
	die "\n FATAL ERROR:\n Must specify both -tab and -lib for MySQL output!\n";
}
if ($tab and $lib) { $sql = 1; }
# Exit if missing first parameter (filename) or
die "\nFATAL ERROR:\n\tMissing parameter filename or filename not found [$uniquepairoutfile].\n\n" if !(-e $uniquepairoutfile);


open U, $uniquepairoutfile || die "\nFATAL ERROR:\n\tUnable to read $uniquepairoutfile.\n\n";

while (<U>) {
	$c++;
	last if ($stoplines and ($c > $stoplines));
	chomp;
	# Extract data from line
	($cont2, $null, $null, $a2, $b2, $d2, $strand2, $null, $comm2) = split /\t/;
#	$cont2 =~s/-/_/g; 	# bug splitting on "-"
	$comm2=~/M:(\d+)/;
	$mismatch2=$1;
	
	# Print progress 
	if (!($c%50000)) {
		if ($cont1 eq $cont2) {
			die "\n FATAL ERROR:\n Input format not valid. Are you parsing UNIQUE_PAIR?\n";
		}
		$elap = (time - $^T);
		$dots=$c/300000;
		$dots=50 if ($dots>50);
		$dot='.'x$dots;
		$lps=int($c/(0.1+$elap)/1000);
		my $elapv=fsec($elap);
		my $mem = mem();
		$spincnt++;
		$place = $spin[$spincnt%4];
		print STDERR "\r $place Parsing input. Read $c lines ($lps klines/s, $elapv, $mem\% memory)...";	
	}
	
	# READ PAIRS (even lines with odd lines)
	if ($c%2) {
		# Even lines
		
		$cont1    = $cont2;
		$a1       = $a2;
		$b1       = $b1;
		$d1       = $d2;
		$strand1  = $strand2;
		$comm1    = $comm2;
		$mismatch1= $mismatch2;
		$hits1    = $hits2;
		
		
	} else {
		# Odd lines (populate hashes)
		

		
		for (my $i=$a2; $i<=$b2; $i++) {
			
			$coverage{$cont2}{$i}++;
			$covpair{$cont2}{$cont1}{$i}++;
			#print "$cont2\t$a2,$b2\t$i <$coverage{$cont2}{$i},$covpair{$cont2}{$cont1}{$i}>\n";
		}
		for (my $i=$a1; $i<=$b1; $i++) {
			$coverage{$cont1}{$i}++;
			$covpair{$cont1}{$cont2}{$i}++;
		}
		
		$key = "$cont1\>$cont2";
		$arc{$key}++;							# Arcs counter
		$strand{$key}{"$strand1$strand2"}++;	# Strand combination counter
		$dist{$key}+=$d1+$d2;					# Distance (unnormalized)
		$pos1{$key}+=int(($a1+$b1)/2);			# Mapping position 1
		$pos2{$key}+=int(($a2+$b2)/2);			# Mapping position 2
		
		$max1{$key} = int(($a1+$b1)/2) if (int(($a1+$b1)/2) > $max1{$key});
		$max2{$key} = int(($a2+$b2)/2) if (int(($a2+$b2)/2) > $max2{$key});
		
		$mm1{$key} += $mismatch1;				# Mismatches (unnormalized)
		$mm2{$key} += $mismatch2;		
	}
}
$elap=fsec(time - $^T);
print STDERR "\n Input parsed: $c lines total ($elap).\n";

foreach my $contig (keys %coverage) {
	my $min=1000**10;
	my $max;
	foreach $pos (sort {$a <=> $b} keys %{$coverage{$contig}}) {
		my $v = $coverage{$contig}{$pos};
		$min = $pos if ($min>$pos);
		$max = $pos if ($max<$pos); 
	}	
	#print "> $contig\t$min\t$max\n";
	$max{$contig}=$max;
	$min{$contig}=$min;
	$C++;
}
$elap=fsec(time - $^T);
print STDERR " $C contig coverage analyzed ($elap).\n";

foreach $conn (keys %arc) {
  $elabcount++;
  if (!($elabcount%100000)) {
		$spincnt++;
		$place = $spin[$spincnt%4];
		$elap = (time - $^T);
		my $elapv=fsec($elap);
		my $mem = mem();
		print STDERR "\r $place Elaborating arcs. Read $elabcount connections ($elapv, $mem\% memory)";	
  }
  
  # SPLIT HERE
  my ($c1, $c2) = split (/>/, $conn);
 
  if ($c1 lt $c2) {
  	$countout++;
   	my $cn="$c2-$c1";
	$fg{$cn};
	
	my $pp = $strand{$conn}{'++'} + $strand{$cn}{'--'};
	my $pm = $strand{$conn}{'+-'} + $strand{$cn}{'+-'};
	my $mp = $strand{$conn}{'-+'} + $strand{$cn}{'-+'};
	my $mm = $strand{$conn}{'--'} + $strand{$cn}{'++'};

	my ($e1, $e2, $p, $m, $tot) = getark($pp, $pm, $mp, $mm);
	
	my $dist = int(($dist{$conn}+$dist{$cn})/($arc{$conn}+$arc{$cn}+0.1));
	my $x1   = int(($pos1{$conn}+$pos2{$cn})/($arc{$cn}+$arc{$conn}+0.1));
	my $x2   = int(($pos2{$conn}+$pos1{$cn})/($arc{$cn}+$arc{$conn}+0.1));
	my $max1 = int(($max1{$conn}+$max2{$cn})/2);
	my $max2 = int(($max2{$conn}+$max1{$cn})/2);
	my $M1   = sprintf "%.2f", (($mm1{$conn}+$mm2{$cn})/($arc{$cn}+$arc{$conn}));
	my $M2   = sprintf "%.2f", (($mm2{$conn}+$mm1{$cn})/($arc{$cn}+$arc{$conn}));

	#Stats
	$arcdec = int($tot/10);
	$arcscount{$arcdec}++;
	$lendec = int($dist/100);
	$distcount{$lendec}++;
	$thsdec = int($p/10);
	$thscount{$thsdec}++;
	
	#Contig check
	($minpos1, $maxpos1, $skip1) = contigland($c1, $c2);
	($minpos2, $maxpos2, $skip2) = contigland($c2, $c1);
	$contstring="$c1=[$min{$c1}<$minpos1, $maxpos1, $skip1>$max{$c1}];"."$c2=[$min{$c2}<$minpos2, $maxpos2, $skip2>$max{$c2}]";
	
	my $string;
	
	if ($sql) {
		$string = "INSERT INTO $tab (lib, c1, c2, end1, end2, dist, sigma, arcs) VALUES ($lib,\"$c1\", \"$c2\", '$e1', '$e2', '$dist', '$p', '$tot');\n";
	} else {
		my $com  = "max=$m;X1=$x1<$max1;X2=$x2<$max2;M1=$M1;M2=$M2;chk=\"$contstring\"" if ($printinfo);
		$string = "$c1\t$c2\t$e1\t$e2\t$dist\t$p\t$tot\t$com\n";	
	}
	if ($tot>$minarcs) {
		$okmin++;	
		if ($p>$ths) {
			$okths++;	
			if ($maxlen and $dist<$maxlen) {
				$okmax++;
				print $string;	
			} else {
				$badmax++;
			}
		} else {
			$badths++;	
		}
	} else {
		$badmin++;	
	}
	
  } else {
	$bg{$conn};	
  }
}
foreach $v (keys %bg) {
	$maxbg = $arc{$v} if ($arc{$v}>$max and !($fg{$v}));	
} 

if ($countout == 0) {
	print STDERR "No arcs found.\n";
	exit;
}
$arcsp=sprintf( "%.2f", (100*$badmin/$countout));
$thsp=sprintf( "%.2f", (100*$badths/$okmin));
$lenp=sprintf( "%.2f", (100*$okmax/$okths));
print STDERR "
Work done. 
	Total connections (arcs)       $countout
	Discarded by arcs              $badmin ($arcsp% of total)
	Then discarded by threshold    $badths ($thsp% of accepted by arcs number)
	Then discarded by length       $badmax ($lenp% of accepted by threshold)
		
";

if ($debug) {
	print STDERR "ARCS by ARCS_NUMBER\n";
	foreach $x (sort {$a <=> $b} keys %arcscount) {
		$xa=$x.'0';
		$xb=$x+1;
		$xb=$xb.'0';
		$p=sprintf ("%.2f", 100*$arcscount{$x}/$countout);
		print STDERR "$xa\t$xb\t$arcscount{$x}\t$p%\n";
	}
	print STDERR "\nARCS by SCORE\n";
	foreach $x (sort {$a <=> $b} keys %thscount) {
		$xa=$x.'0';
		$xb=$x+1;
		$xb=$xb.'0';
		$p=sprintf ("%.2f", 100*$thscount{$x}/$countout);
		print STDERR "$xa\t$xb\t$thscount{$x}\t$p%\n";
	}
	print STDERR "\nARCS by MINLEN\n";
	foreach $x (sort {$a <=> $b} keys %distcount) {
		$xa=$x.'00';
		$xb=$x+1;
		$xb=$xb.'00';
		print STDERR "$xa\t$xb\t$distcount{$x}\n" if ($distcount{$x} > 10);
	}
}


sub contigland {
	my ($c1, $c2) = @_;
	my $min=1000*10;
	my $max=0;
	my %skip; my $skipped;
	#print "?$c1 - $c2 ";
	foreach $position (keys %{$covpair{$c1}{$c2}}) {
		#my $v=$covpair{$c1}{$c2}{$position};
		#print "- $position \t $covpair{$c1}{$c2}{$position}\n";
		$min = $position if ($min>$position);
		$max = $position if ($max<$position);			
	}	
	
	for (my $i=$min; $i<=$max; $i++) {
		#$skip{$i} if ($covpair{$c1}{$c2}{$i} == 0);	
		$skipped++;
	}
	return ($min, $max, $skipped);
}


sub getark {
	
	my ($a, $b, $c, $d) = @_;
	my $tot = $a+$b+$c+$d;
	return 0 unless ($tot);
	my ($max, $imax)=max($a, $b, $c, $d);
	@E1   = (5, 5, 3, 3);
	@E2   = (3, 5, 3, 5);
	if (100*$max/($tot)> $ths) {
		my $ratio=int(100*$max/($a+$b+$c+$d));
		return ($E1[$imax], $E2[$imax], $ratio, $max, $tot);
	} else {
		return 0;	
	}
}

sub max {
	my $max=0;
	
	for ($i=0; $i<=$#_; $i++) {
		if ($_[$i]>$max) {
			$max=$_[$i];
			$imax=$i;
		}
	}
	return ($max, $imax);

}

sub mem {
        @output = `ps aux | grep $$`;
        foreach my $line (@output) {
                my ($u, $pid, $cpu, $mem) = split /\s+/, $line;
                return $mem if ($pid == $$);
        }
}


sub fsec { 
  my $time = shift; 
  my $days = int($time / 86400); 
   $time -= ($days * 86400); 
  my $hours = int($time / 3600); 
   $time -= ($hours * 3600); 
  my $minutes = int($time / 60); 
  my $seconds = $time % 60; 

  $days = $days < 1 ? '' : $days .'d '; 
  $hours = $hours < 1 ? '' : $hours .'h '; 
  $minutes = $minutes < 1 ? '' : $minutes . 'm '; 
  $time = $days . $hours . $minutes . $seconds . 's'; 
  return $time; 
}
