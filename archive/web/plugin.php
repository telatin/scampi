<!doctype html>

<?php 
	$plugin = $_REQUEST['plug'];
	$title  = $_REQUEST['title'];
	$h1		= base64_decode($_REQUEST['h1']);
	
	$chk = hash('md5', "$plugin$title");
	include_once('inc/tools.php');
	include_once('inc/db_con.php');
	include_once('inc/data_tools.php');
	
	if ($error) {
		print "<h2>Error</h2>
		<p>$error</p>";
		
	}
	

?>

<html lang="en">

<head>
  <meta charset="utf-8">
  
  <link rel="stylesheet" href="http://code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css" />
  <script src="http://code.jquery.com/jquery-1.9.1.js"></script>
  <script src="http://code.jquery.com/ui/1.10.3/jquery-ui.js"></script>
  
  <script>
  $(function() {
    $( document ).tooltip();
  });
  </script>
  <style>
  label {
    display: inline-block;
    width: 5em;
  }
  </style>
  <title><?php echo $h1; ?> - ScaMPI plugins</title>
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
	<h1><?php echo $h1; ?></h1>
	</div>

<div id="main">
<?php
	//if ($chk == $sum) {
		$filename = "inc/plugins/$plugin";
		if (file_exists($filename)) {
			include_once($filename);
			
		} else {
			print "Sorry, plugin $filename not found...";
		}
	/*} else {
		print "Sorry, this plugin seems invalid... <!--
		$plugin$title = $chk
		GOT: $sum
		-->\n";
	}
	*/
?>


</div>
<!-- 
  <script src="js/scripts.js"></script>
-->
</body>
</html>
