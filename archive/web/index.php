<!doctype html>
<html lang="en">

<head>
	<link href='http://fonts.googleapis.com/css?family=Roboto:400,300,700' rel='stylesheet' type='text/css'>
   <meta charset="utf-8">
  <title>ScaMPI Scaffolding with Mate Pairs Information</title>
  <meta name="description" content="ScaMPI scaffolding interface">
  <meta name="author" content="Andrea Telatin, CRIBI">
  <link rel="stylesheet" href="inc/scampi.css?v=1.0">
  <!--[if lt IE 9]>
  <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
  <![endif]-->
</head>
<body>
<?php
	include_once('top.php');
	include_once('inc/db_con.php');
	include_once('inc/tools.php');
	include_once('inc/data_tools.php');
?>

	<div id="header">
	<h1 style="text-shadow:5px 5px 5px #BBB">
		<span style="font-weight:300; font-size: 2.5em;">ScaMPI
		<sup><span style="font-size:0.58em;font-weight:700;color:#3399ee;"><? echo $scampi_version; ?></span></sup>
		
		</span> 
		 </h1>
	</div>

<div id="main">


<p>

</p>

<?php 
// GENERAL STATISTICS
	$query = "SELECT count(*) AS total, sum(len) AS sizetot, AVG(cov) AS avgcov FROM $contigtable";
	$handle = mysql_query($query);
	$run = mysql_fetch_array($handle);
	$ctgtot = $run[total];
	$sizetot = $run[sizetot];
	$tt = number_format($run[total], 0, ',', ' ');
	$bp = number_format($run[sizetot], 0, ',', ' ');
	$av = number_format($run[avgcov], 2, ',', ' ');

	$query = "SELECT SUM(len) AS done FROM $contigtable WHERE NOT ISNULL(scaffold)";
	$handle = mysql_query($query);
	$run = mysql_fetch_array($handle);
	$done = $run['done'];
	if ($sizetot) {
	$frac = round(100*$done/$sizetot);
	}
?>
<table>
<tr>
	<td>

</form>
	</td>
	<td>
	<?php	
	print "There are <strong>$tt</strong> contigs in 
	<em><strong style=\"color: #036;text-transform:capitalize;\">$scampi_project</strong></em>,
	accounting for <strong>$bp</strong> bp and an average coverage <strong>$av X</strong>.
	
	";	?>
	</td>
</tr>
</table>
<br>
<div class="meter">
	<span style="width: <?php echo $frac; ?>%"></span>
</div>

<?php
	if ($frac == 0) {
	print "<p class=\"infomsg\">No scaffolds in database. Do you want to perform a first rush of <a href=\"scampi.php\">automatic scaffolding</a>?</p>";
	}
?>
<p>Bases in scaffold: <strong><?php  echo $frac; ?>%</strong>. <span id="sn50"></span></p><br>
<table class="space">
<tr>
<td  class="space"  valign="top">
	<h3>Contigs</h3>
	<table style="border-spacing:2px;   border-collapse:collapse; ">
	<tr style="padding: 13px; background-color: #E0E0E0;">
		<th>Contig name</th><th>Size</th><th>Pairs</th></tr>

<?php 
// FIRST CONTIGS NOT IN SCAFFOLD
	$query = "SELECT * FROM $contigtable WHERE ISNULL(scaffold) ORDER BY len DESC LIMIT 15";
	$handle = mysql_query($query);
	while ($r = mysql_fetch_array($handle)) {
		$tot = arcsfromcontig($r['name'], 10, $arcstable);
		print "<tr><td><a href=\"contig.php?name=$r[name]\">$r[name]</a></td>\n<td>$r[len]</td><td>$tot</td></tr>\n";	
	}
?>
	</table>

</td>
<td  class="space" valign="top">
	<h3>Scaffolds </h3>
	<table style="border-spacing:2px;   border-collapse:collapse; ">
	<tr style="padding: 13px; background-color: #E0E0E0;">
		<th>Scaffold name</th><th>Size</th><th>Contigs</th></tr>

<?php 
// SCAFFOLDS
	$query = "SELECT scaffold, count(name) AS cnum, sum(len) AS len FROM $contigtable WHERE NOT ISNULL(scaffold) GROUP BY scaffold ORDER BY len DESC";
	$handle = mysql_query($query);
	while ($r = mysql_fetch_array($handle)) {
		$scf_sum+=$r['len'];
		$count_scaff++;
		$tot = arcsfromcontig($r['name'], 10, $arcstable);
		print "<tr>
			<td><a href=\"scaffold.php?name=$r[scaffold]\">$r[scaffold]</a></td>
			<td>$r[len]</td> 
			<td>$r[cnum]</td>
		</tr>\n";	
		if ($sn50==0 and $scf_sum >= ($sizetot/2)) {
			$sn50 = number_format($r[len]/1000, 0, ',', ' ');
			print "<script>
				var my = document.getElementById('sn50');
				sn50.innerHTML = 'Scaffold N50: <strong>$sn50 kbp</strong>';
			</script>";
			break;

		}
	}

?>
	</table>
</td>

<td class="space"  valign="top">
	<h3>News from ScaMPI</h3>
	<em>Freshest posts in <a href="http://genomics.cribi.unipd.it/scampi/">ScaMPI's blog</a></em>
	<div id="feed" style="font-size:0.8em;">
	<?
		include('rss.php');
	?>
	</div>
</td>
</tr>
</table>
	
</div>
<!-- 
  <script src="js/scripts.js"></script>
-->
</body>
</html>
