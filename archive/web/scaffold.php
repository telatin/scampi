<!doctype html>

<?php 
	include_once('inc/tools.php');
	include_once('inc/db_con.php');
	include_once('inc/data_tools.php');
	if ($error) {
		print "<h2>Error</h2>
		<p>$error</p>";
		
	}	

	$scaffoldname = $_REQUEST['name'];

	
	$query = "SELECT * FROM $contigtable WHERE scaffold LIKE '$scaffoldname' ORDER BY sid";
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
		$query = "SELECT scaffold, count(*) AS count, sum(len) AS size FROM $contigtable
		WHERE NOT ISNULL(scaffold)
		AND scaffold LIKE '%$scaffoldname%'
		GROUP BY scaffold
		ORDER BY size DESC";
		$handle = mysql_query($query);
		$list.="<br><table>
		<tr style=\"background: #F0F0F0;\">
		<th>#</th><th>Scaffold</th><th>Size</th><th>#contigs</th>
		</tr>\n";
		while ($r = mysql_fetch_array($handle)) {
			$item++;
			$list.="<tr>
			<td>$item</td>
			<td><a href=\"?name=$r[scaffold]\"><strong>$r[scaffold]</strong></a></td>
			<td>".number_format($r[size],0,',',' ')." bp</td>
			<td>$r[count] contigs</td>
			</tr>";
		
		}
		$list.= "</table>\n";
	}
?>

<html lang="en">

<head>
  <meta charset="utf-8">
  <title>Scaffold <?php echo $scaffoldname; ?> - ScaMPI</title>
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
	<h1><span style="color: #33C;font-weight: 400;"><? if ($found_name) { echo ' Scaffold '; } else { if ($_REQUEST[name]) {echo ' Searching scaffold: '; }} ?></span> 
	<span style="text-decoration: none;"><?php echo $scaffoldname; ?></span>
	<? if ($found_name) { echo ''; } else { if ($_REQUEST[name]) { echo ' (not found) ';} } ?>
	</h1>
	</div>
<div id="main">



<div id="contigpanel">
<table>
<tr>
	<td style="vertical-align:top">
		<div style="padding: 14px; background-color: #CEF;-moz-border-radius: 5px; border-radius: 5px;">
		<table>
		<tr><td>Scaffold:</td><td> <strong>
		<form action="?">
		<input name="name" 
		style="font-family: 'Roboto', serif; font-size: 0.9em; font-weight: 700; padding: 2px; border: 0px; border-bottom: solid 2px  #ACE; background-color: #CEF;" 
		type="text" placeholder="<?php if (!isset($scaffoldname)) { echo 'Search...';} else {echo $scaffoldname; } ?>"><input type="submit" value="go">
		</form></strong></td></tr>
		<tr><td>Total length:</td><td> <strong><?php echo $scaffold_len; ?> bp</strong></td></tr>
		<tr><td>Total contigs:</td><td> <strong><?php echo $scaffold_items; ?></strong></td></tr>
		</table>
		</div>
		
		&nbsp;<br/>

		<div style="padding: 14px; background-color: #CEF;-moz-border-radius: 5px; border-radius: 5px;">
		<a href="scaffold_to_fasta.php?scaffold=<?php echo $found_name; ?>">
		Export to FASTA <?php echo $found_name; ?></a>
		
		<? if ($found_name=='') { print '<br><br>
		<a href="scaffold_to_agp.php">
		Export to AGP</a>';
		} else {
			print "<br><br>
		<a title=\"change scaffold structure\" href=\"editscaffold.php?name=$found_name\"><img src=\"img/edit.png\">
		Edit scaffold</a>";
			
		}
		?>
		</div>
	</td>
	<td style="width: 100px;">
	&nbsp;
	</td>
	<td><p id="scaffoldname" style="font-size: 0.9em;">&nbsp;</p>
	<?php
	if ($error) {
		print "$error";
	
	}
	if ($list) {
		print "Select a contig from the list or type its name in the search box:<br> $list";
	}
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
