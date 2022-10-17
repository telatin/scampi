<!doctype html>

<?php 
	include_once('inc/tools.php');
	include_once('inc/db_con.php');
	include_once('inc/data_tools.php');

	$seed = $_REQUEST['seed'];
	$direction  = $_REQUEST['dir']; if ($direction == 0) { $direction = 3; }
	$cov  = $_REQUEST['cov'];  if ($cov == 0) { $cov = 100; }
	$arcs  = $_REQUEST['arcs']; if ($arcs == 0) { $arcs = 10; }
	
	if (strlen($seed)<1) { $error = "No contig requested"; }
	$query = "SELECT * FROM $contigtable WHERE name='$contigname'";
	$handle = mysql_query($query);
	
	while ($contig_info = mysql_fetch_array($handle)) {
		if ($contig_len>0) {
			$error = 'Invalid contig name.';
			exit;
		}
		
		$contig_cov = number_format($contig_info[cov], 2, ',', ' ');
		$contig_len = number_format($contig_info[len], 0, ',', ' ');;
	}
?>

<html lang="en">

<head>
  <meta charset="utf-8">
  <title>contig <?php echo $seed; ?> - ScaMPI</title>
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
	<h1><span style="color: #555;font-weight: 400;">Extend contig</span> <span style="text-decoration: none;">
	<a href="contig.php?name=<?php echo $seed; ?>"><?php echo $seed; ?></a></span> 
	<span style="color: #555;font-weight: 400;"></span> </h1>
	</div>
<div id="main">


<div id="contigpanel">
<?php
	if ($error) {
		print "<h2>Error</h2>
		<p>$error</p>";
		exit;
	}
	
?>
<!--
<table>
<tr><td>Contig name:</td><td> <strong><?php echo $contigname; ?></strong></td></tr>
<tr><td>Contig length:</td><td> <strong><?php echo $contig_len; ?> bp</strong></td></tr>
<tr><td>Contig coverage:</td><td> <strong><?php echo $contig_cov; ?>X</strong></td></tr>
</table>
-->
</div>

<form>
	<table>
	<tr><td>Contig seed:</td>
	<td><input name="seed" value="<?php echo $seed; ?>"></td></tr>

	<tr><td>Minimum number of arcs:</td>
	<td><input name="arcs" value="<?php echo $arcs; ?>"></td></tr>

	<tr><td>Maximum accepted coverage:</td>
	<td><input name="cov" value="<?php echo $cov; ?>"></td></tr>
	
	<tr><td> </td>
	<td><input  type="submit" value="scaffold"></td></tr>
	</table>
	
</form>
<p id="scaffoldname" style="font-size: 0.9em;">&nbsp;</p>
<p>
<table>
<?php
  $output5 = shell_exec("perl inc/divorce.pl -db inc/db_con.php -s $seed -cov $cov -min $arcs -dir 5 -html");
  $output3 = shell_exec("perl inc/divorce.pl -db inc/db_con.php -s $seed -cov $cov -min $arcs -dir 3 -html");
	echo "<div>$output5$output3</div>";
?>
</table>
</p>
</div>
<!-- 
  <script src="js/scripts.js"></script>
-->
</body>
</html>
