#!/usr/bin/perl
# Divorce 2.2
use DBI;
use Getopt::Long;
use File::Basename;
my $dirname = dirname(__FILE__);
$dbfile   = $dirname.'/db_con.php';
$arctable ='arcs';
$minsigma =  90;
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
  	-s   STRING     Seed contig
  	-dir INT        Extension direction, 3 or 5 [$dir]
  	-cov INT        Maximum contig coverage [$max_cov]
  	-arc INT        Minimum amount of mates per arc [$min_arcs]
  	-con INT        Minimum percentage of concordance [$minsigma]
  	-html           Output in HTML format (for web interface)

";



$opt = GetOptions (
  'db=s'       => \$dbfile,
  's=s'        => \$seed,
  'dir=i'      => \$dir,
  'cov=f'      => \$max_cov,
  'arc=i'      => \$min_arcs,
  'con=f'      => \$minsigma,
  'html'       => \$html
);
die " Missing parameter -s [contig_name]\n" unless ($seed);

#print "<table>\n" if ($html);
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
	die " Missing parameter -db\n\n";
}

#Defaults
$maxIter  = 60;
$DIR=$dir;
print STDERR " [Start] Starting extension from $seed $dir\'... \n";

#Format contig name (user can provide just the contig number and/or leading and trailing spaces
if ($seed=~/([0-9][0-9][0-9][0-9][0-9])/) {
    $seed='contig'.$1;	
} else {
    die "\nERROR:\nIllegal contig name. Expected format is a five digits code. Eg: contig01234 or 01234.\n";
}
die "\nERROR:\nWrong extension direction (3 or 5).\n" if (($dir!=3) and ($dir!=5));
	

$iterations=0;
@list=();
%added=();
%visited=();
$arc_draw='';
$SIZE=0;
%continfo=();
#BEGIN
if ($seed) {
	extend($seed);
	#($fromSize) = getinfo($seed);
}

sub extend {
	my $s = shift;
	push(@added, $s);
	$t=0;
	while (($newseed, $newdir) = getarcs($s, $dir, $t)) {
		if ($newdir==5) {$try_to=3} else {$try_to=5}
		($testseed, $testdir) = getarcs($newseed, $try_to, -1);
		#Backcheck
		if (($visited{$testseed} ==0) and ($newseed ne $s)) {

			finish_all("Loop in graph: $newseed -> $testseed"); 
			$t++;
		}
		$s=$newseed;
		$dir=$newdir;
	}
		
}

sub getarcs {
	finish_all("Too many iterations ($interations).") if ($iterations > $maxIter);
	$iterations++;
	my $c;
	my %links;
	my %end;
	my %lib;
	($contig_name, $side, $test) = @_;
	finish_all("$contig_name->$side ($test)") if (($added{$contig_name}) and $test>0);
	
	$added{$contig_name}++ if ($test>=0);
	
	
	$query = "SELECT lib, c1, end1 AS e1, c2, end2 AS e2, arcs 
		FROM $arctable 
		WHERE (arcs > $min_arcs) and (c1 LIKE '$contig_name' OR c2 LIKE '$contig_name') AND (sigma>$minsigma)";

	$query_handle = $dbh->prepare($query);
	$query_handle->execute();
	$query_handle->bind_columns(\$lib, \$c1, \$e1, \$c2, \$e2, \$arcs);
	while($query_handle->fetch()) {
		($from, $to, $contig) = sortresult($contig_name, $c1, $c2, $e1, $e2);
		
		#print STDERR "? $from - $to - $contig  // called by ($contig_name, $side, $test)\n";
		#my ($cSize, $cCov) = getinfo($contig);
		
		next if ($from != $side);
  	 	$links{$contig}+=$arcs;
  	 	$lib{$contig}+=$lib;
  	 	$end{$contig}=$to;
  	} 

  	foreach $key (sort {$links{$b} <=> $links{$a}} keys %links ){
  		$visited{$key}++ if ($links{$key} > $min_arcs);	
  	}
  	foreach $key (sort {$lib{$b} <=> $lib{$a}} keys %lib ){
  		end if ($c);
  		$c=1;
  		
		foreach $x (sort {$links{$b} <=> $links{$a}} keys %links ){
			$EXT_TO=$end{$x};
			
			if ($EXT_TO==5) {$ext_to=3} else {$ext_to=5}
  			($kb, $cov) = getinfo($x);
  				$added{$contig_name}++;
  				finish_all( "Already visited, loop in graph. $contig_name; $added{$contig_name}") if ($added{$contig_name}>3);
				$arc_draw.="$contig_name -> $x [ label = \"$links{$x} ($lib{$x})\\n$side - $end{$x}\", fontsize=10, fontname=arial]\n" 
					if ($test>=0);
  				if ($test>=0) {
  					push(@list, $contig_name);
  					$iterations=0;	
  				}
  				if ($DIR==3) {
  					$Letter='U';
  					$Letter='C' if ($side==5);
  				}else {
  					$Letter='C';
  					$Letter='U' if ($side==5);
  				}
  				push(@end,  $Letter) if ($test>=0);
  				if ($cov > $max_cov) {
  					finish_all("Rejected by coverage $cov ($x)...");
  				} else {
	    			return ($x, $ext_to);
  				}
  			

		}	
	}
  	
  
}

sub finish_all {
	$code=shift;
	
	print STDERR " [Close] Extension blocked: $code\n";
	$text='digraph my_scaffold {
		rankdir=LR;
		size="28,5"
		node [shape = box];'."\n";
	foreach $a (keys %added) {
		$decorated = contig2box($a);
		$text.="$decorated\n";	
	}	
	#$text.= "$arc_draw\n}\n";
	
	#info("This script took ". (time - $^T) ." seconds.");
	$SIZE=sprintf("%.2f", $SIZE/1000);
	$totContigs = $#list+1;
	info("Extension results: $SIZE kbp total, $totContigs contigs.\n") if ($totContigs);

	if ($DIR == 5) {
		@list = reverse(@list);	
		pop(@list);
	}
	
	foreach ($i=0; $i<=$#list; $i++) {
		$ccount++;
		($size, $cov, $scaffold, $sid) = getinfo($list[$i]);
		$listprint.="$list[$i]$end[$i]\n";
        #my $d = ', ' if ($scaffold);
        $size = bp($size);
        my $stot = scaffitems($scaffold) if ($scaffold);
        $pi++;
        	if ($html) {
        		if (!($pi%2)) { $color = '#FFF'; } else { $color = '#EEE'; }
  	      		$color = '#DDF' if ($list[$i] eq $seed);
        		my $b = 'span';
        		$b = 'strong' if ($list[$i] eq $seed);
        		print "<tr style=\"background-color: $color;\">
        		<td><a href=\"contig.php?name=$list[$i]\"><$b>$list[$i]</$b></a></td><td>$end[$i]</td>
        		<td align=\"right\">$size</td><td>$cov\X</td><td>$scaffold</td><td>$sid $stot</td>\n</tr>\n";
        	} else {
		print "$list[$i]$end[$i]\t$cov\X\t$size\t$scaffold\t$sid\t$stot\n";	
		}
	}
	
	
	#print "<br/>Plot:<br/><textarea wrap=\"off\" cols=\"33\" rows=\"19\" readonly=\"readonly\">\n$text</textarea>";
	#print "<br/>Submit<br/><textarea wrap=\"off\" cols=\"33\" rows=\"19\" readonly=\"readonly\">\n$listprint</textarea>";
	#print "\n</table>\n" if ($html);
	exit;
}

sub bp {
	my $i = shift;
	return $i unless ($html);
	if ($i<1000)  {
           return "$i bp";
        } elsif ($i<1000*1000) {
           return sprintf("%.2f", $i/1000).' kbp';
        } elsif ($i<1000*1000*1000) {
	   return sprintf("%.2f", $i/1000000).' Mbp';
        } elsif ($i<1000*1000*1000*1000) {
	   return sprintf("%.2f", $i/1000000000).' Gbp';
	}
}
sub contig2box {
	my $c = shift;
	($kb, $cov, $scaffold) = getinfo($c);
	$boxed="\"$c\" [ style=bold,label = \"$scaffold|$c|$kb kb - $cov\X\" shape = \"record\" ]";
	
	$SIZE+=$kb;
	return $boxed;
}

sub getinfo {
	my $c = shift;
	if (!$continfo{$c}) {
		my $query = "SELECT name, len AS kb, round(cov) AS cov, added, scaffold, sid 
		FROM contigs 
		WHERE name like '$c'";
		$query_handle = $dbh->prepare($query);
		$query_handle->execute();
		$query_handle->bind_columns(\$name, \$kb, \$cov, \$added, \$scaffold, \$sid);
		while($query_handle->fetch()) {
			my $string="name=$name;size=$kb;coverage=$cov;scaffold=$scaffold-$sid;added=$added;";
			$continfo{$c}=$string;	
		}
	}
	
	my $data = $continfo{$c};
	
	$data =~/size=(.*?);coverage=(.*?);scaffold=(.*?)-(\d*);/;
	
	return ($1, $2, $3, $4);
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
		info("Everything is wrong");
		
	}
	
	
	return ($FROM, $TO, $C);
}
sub scaffitems {
	my $scaffold = shift;
	#info("Items of $scaffold ($scafnum{$scaffold})…?");
	my $total;
	if ($scafnum{$scaffold}>0) {
		#info("$scaffold items already seen $scafnum{$scaffold}\n");
		return $scafnum{$scaffold};	
	} else {
		#my $tot=$dbh->selectrow_array(qq{SELECT COUNT(*) FROM contigs WHERE scaffold LIKE ?}, undef, $c);
		my $query = "SELECT id FROM contigs WHERE scaffold LIKE '$scaffold'";
		#info("$query...");
		$query_handle = $dbh->prepare($query);
		$query_handle->execute();
		$query_handle->bind_columns(\$id);
		while($query_handle->fetch()) {
			#info("$scaffold -> $total");
			$total++;
		}
		$scafnum{$scaffold}=$total;
		return $total;
	}
}

sub error {
	($code, $msg) = @_;
	print STDERR "[ERROR] $code\n| $msg\n";
	
	
}

sub info {
	$msg = shift;
	print STDERR " [Messg] $msg\n";
}





