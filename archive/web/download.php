<?php
$file_name = base64_decode($_REQUEST['file']);
$out_name  =base64_decode($_REQUEST['id']);
if (!preg_match('/tmp/', $file_name)) {
	print "<h1>Wrong filename</h1>";
	exit;
}
if (strlen($out_name)<2) {$out_name = 'scampi_file.txt';}
if (file_exists($file_name)) {
/*
	header("X-Sendfile: $file_name");
	header("Content-type: application/octet-stream");
	header('Content-Disposition: attachment; filename="' .$out_name . '"');
*/	
	header("Content-Type: application/octet-stream; "); 
	header("Content-Transfer-Encoding: binary"); 
	header("Content-Length: ". filesize($file_name).";"); 
	header("Content-disposition: attachment; filename=$out_name");
	$fp = fopen("$file_name", "r"); 
	while(!feof($fp)){
    	$buffer = fread($fp, 1024); 
		echo $buffer;
    flush(); 
    } 
    fclose($fp);
    shell_exec("rm $file_name");
} else {
	print "<h3>File Not Found $file_name</h3>";
	
}
?>