<!doctype html>

<?php 
	include_once('inc/tools.php');
	include_once('inc/db_con.php');
	include_once('inc/data_tools.php');
	if ($error) {
		print "<h2>Error</h2>
		<p>$error</p>";
		
	}
	
	$order = $_REQUEST['o'];
	if (!isset($order)) {$order = 'len DESC';}
	
	$contigname = $_REQUEST['name'];
	$query = "SELECT * FROM $contigtable WHERE name LIKE '$contigname' ";
	$handle = mysql_query($query);
	
	while ($contig_info = mysql_fetch_array($handle)) {
		$count++;	
		$contig_cov = number_format($contig_info[cov], 2, ',', ' ');
		$contig_len = number_format($contig_info[len], 0, ',', ' ');
		$contig_scaffold = $contig_info[scaffold];
		$contig_sid = $contig_info[sid];
	}
	
	if ($count == 0) {
		$query = "SELECT * FROM $contigtable WHERE name like '%$contigname%' ORDER BY $order LIMIT 20";
		$handle = mysql_query($query);
		while ($contig_info = mysql_fetch_array($handle)) {
			//$list.="<a href=\"?name=$contig_info[name]\">$contig_info[name]</a> ($contig_info[cov]X, $contig_info[len] bp)<br>";
						$count_res++;
			$sum_len+=$contig_info[len];
			$list.="
			<tr>
			<td><a href=\"?name=$contig_info[name]\">$contig_info[name]</a></td>
			<td>$contig_info[cov]X</td>
			<td>$contig_info[len] bp</td>
			<td><a href=\"scaffold.php?name=$contig_info[scaffold]\">$contig_info[scaffold]</a></td>
			</tr>";
		}
	}
?>

<html lang="en">

<head>
  <meta charset="utf-8">
  <title>Online help (Google Document) - ScaMPI</title>
  <meta name="description" content="ScaMPI scaffolding interface">
  <meta name="author" content="Andrea Telatin, CRIBI">
  <script type="text/javascript" src="http://www.shawnolson.net/scripts/public_smo_scripts.js"></script>
  <link href='http://fonts.googleapis.com/css?family=Roboto:400,700,300' rel='stylesheet' type='text/css'>
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
	<h1>Online help</h1>
	</div>
<div id="main">

<iframe src="https://docs.google.com/document/d/1CU3pgM5T8cJ-L3shnB7MqGvVP9O65jPFc_usVTohWek/pub" width="100%" height="700">
</iframe>
</div>
<!-- 
  <script src="js/scripts.js"></script>
-->
</body>
</html>
