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
  <title>contig <?php echo $contigname; ?> - ScaMPI</title>
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
	<h1><span style="color: #33C;font-weight: 400;">View Contig</span> <span style="text-decoration: none;"><?php echo $contigname; ?></span></h1>
	</div>
<div id="main">



<div id="contigpanel">
<table>
<tr>
	<td style="vertical-align:top">
		<div style="padding: 14px; background-color: #CEF;-moz-border-radius: 5px; border-radius: 5px;">
		<table>
		<tr><td>Name:</td><td> <strong>
		<form action="?">
		<input name="name" style="font-family: 'Roboto', serif; font-size: 0.9em; font-weight: 700; padding: 2px; border: 0px; border-bottom: solid 2px  #ACE; background-color: #CEF;" 
		size="10" type="text" placeholder="<?php echo $contigname; ?>"><input type="submit" value="go">
		</form></strong></td></tr>
		<tr><td>Size:</td><td> <strong><?php echo $contig_len; ?> bp</strong></td></tr>
		<tr><td>Coverage:</td><td> <strong><?php echo $contig_cov; ?>X</strong></td></tr>
		<?php
		if ($contig_scaffold) {
		print "<tr><td>Scaffold:</td><td> <strong><a href=\"scaffold.php?name=$contig_scaffold\">$contig_scaffold</a></strong> ($contig_sid)</td></tr>";
		}
		?>
		</table>
		<br>
		<?
		if ($contigname) { print "
		<a href=\"editcontig.php?name=$contigname\"><img src=\"img/edit.png\">Edit contig info</a>";
		}
		?>
		</div>
		<br>
		<div style="padding: 14px; background-color: #DDD;-moz-border-radius: 5px; border-radius: 5px;">
		
		<a href="contig_query.php?">Advanced contig selection</a>
		</div>
	</td>
	<td style="width: 20px;">
	&nbsp;
	</td>
	<td><p id="scaffoldname" style="font-size: 0.9em;">&nbsp;</p>
		<?php
	if ($error) {
		print "$error";
	
	}
	if ($list) {
		print "Select a contig from the list or type its name in the search box ($count_res total, $sum_len bp):<br><br>
		
		<table>
		<tr style=\"font-weight: bold;\"><td>Contig</td><td>Coverage</td><td>Length</td><td>Scaffold</td>
		</tr>
		 $list
		 </table>";
	}
?>
	<?php
	$table = plotarcs("$contigname", 1, "$arcstable");
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
