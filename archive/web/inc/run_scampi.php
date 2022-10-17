<?php
if(isset($_REQUEST['file'])){ $file = $_REQUEST['file']; }
	
	$pid  = $_REQUEST['link'];
	
	$arcs = $_REQUEST['arcs'];
	$cov  = $_REQUEST['cov'];
	$fil  = $_REQUEST['fil'];
	$action=$_REQUEST['action'];
	$id   = $_REQUEST['id'];


if ($file and $arcs) {
	print "0|Starting scaffolding <!-- 
	COMMAND:  echo \"perl multi-scampi.pl -cov $cov -arc $arcs -fil $fil $action -web $id \" | at now
	FILE:     $file -->
	...";
	//shell_exec("echo \"perl multi-scampi.pl -cov $cov -arc $arcs -fil $fil $action -web $id \" | at now");
	shell_exec("perl multi-scampi.pl -cov $cov -arc $arcs -fil $fil $action -web $id  2> /tmp/lastX.scampi > /tmp/last.scampi &");
	
} elseif ($file) {
	$output = shell_exec("tail -n 1 /tmp/$file");
	if ($output) {
		print "$output";
	} else {
		print "0|<!-- FILE NOT FOUND: $file -->";
	}
} else {
	print "0| <!-- run_scampi didnt get a 'file' parameter -->";
}
?>

