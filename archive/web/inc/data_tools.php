<?php
// this script contains functions that
// DO REQUIRE database connection active
global $scampi_version;
$scampi_version = '1.4';
function arcsfromcontig($contig, $min, $arcstable) {
	$query = "SELECT * FROM $arcstable WHERE 
		(c1='$contig' OR c2='$contig') 
		AND (arcs > $min)
		AND (sigma > 90)";
	$run   = mysql_query($query);
	$count=0;
	while ($r = mysql_fetch_array($run)) {
		$count++;
	}

	return $count;
}
function minarcs($contig, $arcs) {
	return ('10');
	$q = "SELECT *, SUM(arcs) as totarcs, SUM(lib) AS lib2 
		FROM $arcs 
		WHERE (c2='$contig' or c1='$contig') AND (sigma > 90)
		GROUP BY c1,c2 
		ORDER BY arcs DESC;";
	$r = mysql_query($q);
	$sum = 0;
	$count;
	$list = array();
	while ($f = mysql_fetch_array($r)) {
			$count++;
			$sum += $f['totarcs'];
			array_push($list, $f['totarcs']);
	}
	$count/=0.5;
	if ($count) { return round($sum/$count); } else { return 0; }
	
}
// Function to retrieve contig record by name (partial name). Error if more than 1 contig found.
function contig($contig) {
	
	
	$q = "SELECT * FROM contigs WHERE name LIKE '%$contig' LIMIT 20" or die(mysql_error());
	$r = mysql_query($q) or die(mysql_error());
	$contignum=mysql_num_rows($r) or die(mysql_error());
	if ($contignum>1) {
		while ($x = mysql_fetch_array($r)) {
			//$list.="<a href=\"?name=$x[name]\">$x[name]</a><br>\n";
		}
		die ("");
		
	}
	
	$row=mysql_fetch_array($r);
		$id = $row['id'];
		$rd= $row['rd'];
		$len=$row['len'];
		$cov=$row['cov'];
		$notes=$row['notes'];
		$added=$row['added'];
		$array = array($id, $rd, $len, $cov, $notes, $added, $row['name'],$row['scaffold'], $row['alien'], $row['sid'], $row['skipto']);

	
		return $array;
	
}


function format($s, $c) {
	$info = contig($s);
	$coverage=round($info[3]).'X';
	$length=round($info[2]/1000, 1);
	$added=$info[5];
        $scaffold=$info[7];
	if ($scaffold) {
		$scf='</a><span style="text-decoration:none;color:gray;"><sup>'.$info[9].'</sup></span>';
	}	
	if ($added) {
		$formats	= '<span style="color: #9A1E00;">'.$s.$scf.'</span>';
	} else {  $formats=$s.$scf; }
	
	if ($coverage>21) {
		$coverage='<span style="color:red;">'.$coverage.'</span>';	
	}
	$tag="<small>($length&nbsp;kb/$coverage".')</small><br>';
	if ($s == $c) { 
		$r = "$formats&nbsp;$tag";
	} else {
		$r = "<a onmouseout=\"document.getElementById('scaffoldname').innerHTML = '&nbsp;';\" onmouseover=\"document.getElementById('scaffoldname').innerHTML = '$scaffold&nbsp;<strong>$info[9]</strong>';\" title=\"$info[7]  $info[9]\" href=\"?name=$s\">$formats&nbsp;$tag</a>";}
	return $r;
}

function plotarcs($contig, $lib, $arcs) {
	

	
	$minconn=minarcs($contig, $arcs);
	
	$qtemp = "SELECT count(arcs) AS tot, sum(arcs) AS sum FROM $arcs WHERE (c1 LIKE '%$contig' OR c2 LIKE '%$contig') AND (sigma > 80)";
	$run   = mysql_query($qtemp) or die (mysql_error());
	$row1  = mysql_fetch_array($run);
	$totarcs = $row1['sum'];
	$totconn = $row1['tot'];
	
	$q = "select *, SUM(arcs) as totarcs, SUM(lib) AS lib2 from $arcs 
		WHERE (c1 like '$contig' OR c2 like '$contig' ) AND (sigma > 75)
		GROUP BY c1,c2
		ORDER BY totarcs DESC, sigma DESC" or die(mysql_error());
	$r = mysql_query($q) or die(mysql_error());
	
	$arctable= '<table cellpadding="3" cellspacing="0"><tr bgcolor="#CCC">
			 <!--<td>id</td>-->
			 <th><strong>Lib</strong><th width="180px">Contig1</th><th width="40px">End1</th><th width="40px">End2</th><th width="180px">Contig2</th><th width="80px">Distance</th><th>#Mates</th><th>Concordance</td>
		</tr>';
	
	while ($row=mysql_fetch_array($r)) {
		$id = $row['id'];
		$c1= $row['c1'];
		$c2=$row['c2'];
		$end1=$row['end1'];
		$end2=$row['end2'];
		$perc=$row['sigma'];
	
		if ($c1 === $contig) {
			$c0=$c1;$c4=$c2;
			$e0=$end1;	$e4=$end2;
		} else {	
			$c0=$c2;$c4=$c1;
			$e0=$end2;	$e4=$end1;
		}
		
	
		$dist=$row['dist'];
		$arcs=$row['totarcs'];
		$lib=$row['lib2'];
	 	$scf=$row['scaffold'].'/'.$row['sid'];	
		if ($lib == 1) {$libcol=''; } else { $libcol='';}
	
		//print "$c1-$c2 --> $c0-$c4<br>";
		$cf1=format($c0, $contig);
		$cf2=format($c4, $contig);
		if ($arcs<=$minconn) {$color='#E0E0E0';} else {$color='#ffffff';}
		if ($perc<70) {$color='#C0C0D0'; $sigmacol='span';} else {$sigmacol='strong';}
		$ratio = sprintf("%.2f", $arcs/$totarcs);
		$c++;
		$pos   = sprintf("%.2f", $c/$totconn);
		if ($pos<0.6) {$ok='OK';} else {$ok='';}
		$arctable.= "<tr class=\"$c4\" bgcolor=\"$color\">
           <!--<td>$id</td>--><td><strong>$lib</strong><td>$cf1</td><td>$e0</td><td>$e4</td><td>$cf2</td>
	<td>$dist</td><td>$arcs</td><td>$perc%</td>
		</tr>\n";
	/*	print "<style>
		.$c4 {background-color: white;}
		</style>
		";*/
		
		if (($e0 === '3') and ($arcs>$minconn) and ($perc > 70)) {
			$C4=format($c4, $contig);
			$table3.="<tr>
			<td style=\"text-align: right; width: 10px; background:#CCC;\">$e4</td>
			<td  class=\"$c4\" onmouseover=\"changecss('.$c4','background-color','#FFDD8D')\" onmouseout=\"changecss('.$c4','background-color','white')\" >
			<$sigmacol>$C4</$sigmacol> <small>$arcs&nbsp;$perc%</small></td></tr>\n";
		}
		
		if (($e0 === '5') and ($arcs>$minconn) and ($perc > 70)) {
			$C4=format($c4, $contig);
			$table5.="<tr><td class=\"$c4\"  onmouseover=\"changecss('.$c4','background-color','#FFDD8D')\" onmouseout=\"changecss('.$c4','background-color','white')\"  style=\"text-align: right; \">
			<$sigmacol>$C4</$sigmacol><small>$arcs&nbsp;$perc%</small></td><td style=\"width: 10px; 
background:#CCC;\">$e4</td></tr>\n";	
		}
	}
	$arctable.= "
	</table>
	";
 $pt=contig($contig);
 $scf=$pt[7];
if ($scf) {
	$sidnumber=$row['sid'];
	$writescf="<a href=\"scaffold.php?s=$scf\">$scf $row[sid]</a><br><strong>";
} else {
	$writescf='<strong>';
}
 $cov=round($pt[3]).'X';
$nameend=substr($contig,-4,4);
$namestart=substr($contig,0,1);
if ($namestart == 'F' or $namestart == 'G') {
	$contig="<a href=\"getseq.php?p=$contig\">$nameend</a>";
}
 $le=sprintf("%.1f", ($pt[2]/1000)).'kb';
	$visual='<table style="font:Verdana, Geneva, sans-serif;" align="center" width="550px" border="0" cellspacing="0" cellpadding="3">
  <tr>
    <td>    
	<table width="200" border="0" cellspacing="0" cellpadding="3">'.$table5.'</table>    </td>
    
    <td>
    <table style="background:#C3C3C3;">
    <td style="width:8px; background:#C3C3C3;">
    	<div style="text-align:center; color: white;"><a href="extend.php?seed='.$contig.'&dir=5">5\'</a></div></td>
    <td style="width: 120px; background:#CEF; text-align: center;">
<div align="center"><span style="color:gray;">'."<small>$scf</small>&nbsp;<sup><strong>$pt[9]</strong> ".'</strong></sup></span><b><big>'.$contig.'</big></b></strong><br>'."$le - $cov".'</div></td>
    <td style="width:8px; background:#C3C3C3;">
    	<div style="text-align:center; color: white;"><a href="extend.php?seed='.$contig.'&dir=3">3\'</a></div></td>
    </table></td>
    
    <td>
	    <table width="200" border="0" cellspacing="0" cellpadding="3">'.$table3.'</table>
	
	</td>
  </tr>
</table>';

	print "<div>$visual</div>\n";
	return "<div><h3>Arcs for $contig</h3>
	$arctable</div>";
	
}

?>
