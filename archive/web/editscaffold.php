<!doctype html>

<?php 
	include_once('inc/tools.php');
	include_once('inc/db_con.php');
	include_once('inc/data_tools.php');
	if ($error) {
		print "<h2>Error</h2>
		<p>$error</p>";
		
	}
	$scaffold = $_REQUEST['name'];
	
	if ($_REQUEST['update']) {
		mysql_query("UPDATE $contigtable SET scaffold=NULL WHERE scaffold='$scaffold'");
		$text = trim($_REQUEST['newscaffold']);
		$text = explode ("\n", $text);

		foreach ($text as $line) {
			$counter++;
		   $line = str_replace("\n", "", $line);
		   $line = ereg_replace( "\r", '', $line);
		   $Tcontig = substr($line, 0, -1);
		   $Tdir = substr($line, -1);
		   $sid=$counter*10;
		   mysql_query("UPDATE $contigtable SET scaffold='$scaffold',sid='$sid',dir='$Tdir' WHERE name='$Tcontig'");
	    }	
		
		$msg = "Scaffold $scaffold updated ($counter items)";
		
	}
	
	
	$query = "SELECT name,dir,len FROM contigs WHERE scaffold='$scaffold' ORDER BY sid";
	$x=mysql_query($query);
	$text='';
	while ($r = mysql_fetch_array($x)) {
		$conta++;
		$scasum+=$r[len];
		$text .= "$r[name]$r[dir]\n";
	}
?>


<html lang="en">

<head>
  <meta charset="utf-8">
  <title>Edit scaffolding data for <?php echo $contigname; ?> - ScaMPI</title>
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
	<h1><span style="color: #33C;font-weight: 400;">Edit Scaffold</span> <span style="text-decoration: none;"><?php echo $scaffold; ?></span></h1>
	</div>

<div id="main" style="margin: 0 auto 0 auto; padding-left:3em;">
	<p>
		<? print "$conta contigs in scaffolds (total size $scasum bp)"; ?>
	</p>
	<form action="?" method="post">
		<input type="submit" value="Update scaffold"> <? if ($msg) {print 
			"<em><span style=\"background-color:lightyellow;\">$msg</span></em>";}
		?><br>
		
		<input type="hidden" name="update" value="1"><br>
		
		<input type="hidden" name="name" value="<? echo $scaffold; ?>"><br>
		
		<textarea style="font-size: 12px;" name="newscaffold" cols="50" rows="30"><? echo $text; ?>
		</textarea>
		
	</form>
	
	<?
		if ($list) {
			
			print $list;
		}
	?>
</div>


<!-- 
  <script src="js/scripts.js"></script>
-->
</body>
</html>
