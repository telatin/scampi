	<!doctype html>

<?php 
	include_once('inc/tools.php');
	include_once('inc/db_con.php');
	include_once('inc/data_tools.php');
	if ($error) {
		print "<h2>Error</h2>
		<p>$error</p>";
		
	}
	
	$scaffoldname = $_REQUEST['scaffold'];
	
	$dir = "contigs";
	if (!file_exists($dir) and !is_dir($dir))  {
		$not_found =1;
	}
	function getseq($name,$d) {
		$handle = file_get_contents("$d/$name.fa");
		return preg_replace('/>\w+/', '', $handle);
	}
	
	/*$query = "SELECT * FROM $contigtable WHERE scaffold LIKE '$scaffoldname' ORDER BY sid";
	$handle = mysql_query($query);
	$scaffold_table='<table>
	<tr style="background-color: #CEF;"><th>#</th><th>Contig</th><th></th><th>Size</th><th>Coverage</th><th></th></tr>';
	while ($r = mysql_fetch_array($handle)) {
		$found_name=$scaffoldname;
		$scaffold_items++;	
		$scaffold_len+=$r[len];
		$scaffold_table.="\n<tr>
			<td>$r[sid]</td>
			<td><a href=\"contig.php?name=$r[name]\">$r[name]</a></td>
			<td>$r[dir]</td>
			<td>$r[len] bp</td>
			<td>$r[cov]X</td>
			<td>$r[contig]</td>
			<td>$r[contig]</td>
			<td>$r[contig]</td>\n</tr>";
	}
	
	if ($scaffold_items == 0) {
		// if no scaffold is found (eg: no name provided)
		// search all scaffolds...
		$query = "SELECT scaffold, name, dir FROM contigs WHERE NOT ISNULL(scaffold) ORDER BY scaffold, sid";
		$handle = mysql_query($query);
		
		while ($r = mysql_fetch_array($handle)) {
			$item++;
			$list.="<tr>
			<td>$item</td>
			<td><a href=\"?name=$r[scaffold]\"><strong>$r[scaffold]</strong></a></td>
			<td>".number_format($r[size],0,',',' ')." bp</td>
			<td>$r[count] contigs</td>
			</tr>";
		
		}
		
	}
		if (!isset($scaffoldname)) {
		$found_name = 'list';
	}
	*/
?>

<html lang="en">

<head>
  <meta charset="utf-8">
  <title>Scaffold to Fasta -<?php echo $scaffoldname; ?> ScaMPI</title>
  <meta name="description" content="ScaMPI scaffolding interface">
  <meta name="author" content="Andrea Telatin, CRIBI">
  <script type="text/javascript" src="http://www.shawnolson.net/scripts/public_smo_scripts.js"></script>
  <link href='http://fonts.googleapis.com/css?family=Roboto+Slab:400,700,300' rel='stylesheet' type='text/css'>
  <link rel="stylesheet" href="inc/scampi.css?v=1.0">
  <!--[if lt IE 9]>
  <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
  <![endif]-->
</head>
<body>
<?php
	include_once('top.php');
?>
	<div id="header">
	<h1>Scaffold to FASTA</span>
	</h1>
	</div>
<div id="main">



<div id="contigpanel">
<table>
<tr>
	<td style="vertical-align:top">
		<div style="padding: 14px; background-color: #CEF;-moz-border-radius: 5px; border-radius: 5px;">
		<? echo $found_name; ?>Scaffold to FASTA	
		</div>
		
		&nbsp;<br/>


	</td>
	<td style="width: 100px;">
	&nbsp;
	</td>
	<td><p id="scaffoldname" style="font-size: 0.9em;">&nbsp;</p>
	<?php
	if ($error) {
		print "$error";
	
	}
	
	if (strlen($scaffoldname)<2) { $scaffoldname = 'all'; }
	
	$filename = '/tmp/'.uniqid().".fa";
	$cmd = "perl scampi_fasta.pl -s $scaffoldname -db inc/db_con.php -dir $dir -o $filename ";
	$print = shell_exec("$cmd");
	$enfile = base64_encode($filename);
	$enid   = base64_encode("scampi_$scaffoldname.fasta.txt");
	print "<h3>Conversion to FASTA</h3>$print<hr>";
	print "<a href=\"download.php?file=$enfile&id=$enid\">Download FASTA</a>\n";
	
?>
	<?php
		
		print $scaffold_table;
	
	?>

	</td>
</tr>
</table>
</div>


<p>

<?php
 print $table;
?>
</p>
</div>
<!-- 
  <script src="js/scripts.js"></script>
-->
</body>
</html>
