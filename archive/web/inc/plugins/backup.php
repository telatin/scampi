<h1>Backup database</h1>

<?php
$action = $_REQUEST['action'];

if ($action == '') {
	$root=$_SERVER["SERVER_NAME"].$_SERVER["REQUEST_URI"];
	print "<p>Perform full database backup (saved in /tmp): 
	<span style=\"font-weight: bold;padding: 6px; background:#F0F0F0;\"> <a onclick=\"return confirm('Confirm action?')\" href=\"http://$root&action=file\">GO</a></span><br>";
	print "<p>Perform full database backup (saved in /tmp and on screen): <span style=\"font-weight: bold;padding: 6px; background:#F0F0F0;\"><a href=\"http://$root&action=backup\"  onclick=\"return confirm('Confirm action?')\" >GO</a></span><br>";
} elseif ( $action == 'backup') {
	$id = uniqid();
	if ($g=backup_tables($id, $scampi_host, $scampi_user,$scampi_pass, $scampi_db)) {   
	
	print "<a href=\"file:///tmp/scampi_db_$id.sql\">Backup file</a> saved in <strong>/tmp/scampi_db_$id.sql</strong><br>\n<pre><strong>BACKUP:</strong>\n$g</pre>";
	}
} elseif ( $action == 'file') {
	$id = uniqid();
	if (backup_tables($id, $scampi_host, $scampi_user,$scampi_pass, $scampi_db)) {   
	
	print "<a href=\"file:///tmp/scampi_db_$id.sql\">Backup file</a> saved in <strong>/tmp/scampi_db_$id.sql</strong><br>\n";
	}
}

print "<h2>Backups</h2>\n<ul>";
if ($handle = opendir('/tmp')) {
   
    /* This is the correct way to loop over the directory. */
    while (false !== ($entry = readdir($handle))) {
    	if (preg_match('/^scampi_db(.*)/', $entry, $h)) {
    	    $d = date ("F d Y H:i:s.", filemtime("/tmp/$entry"));
    	    $f = base64_encode("/tmp/$entry");
    	    $i = base64_encode("ScaMPI_$entry");
	    print "<li style=\"line-height: 2.4em;\">
	    <span style=\"font-weight:400;\">$entry</span>, $d 
	    <span style=\"font-weight: bold;padding: 2px; background:#F0F0F0;\"> 
	    <a href=\"download.php?file=$f&id=$i\">Download</a></span></li>";
        }
    }

   
    closedir($handle);
}	
print "</ul>\n";
function backup_tables($pid,$host,$user,$pass,$name,$tables = '*')
{
	
	$link = mysql_connect($host,$user,$pass);
	mysql_select_db($name,$link);
	
	//get all of the tables
	if($tables == '*')
	{
		$tables = array();
		$result = mysql_query('SHOW TABLES');
		while($row = mysql_fetch_row($result))
		{
			$tables[] = $row[0];
		}
	}
	else
	{
		$tables = is_array($tables) ? $tables : explode(',',$tables);
	}
	
	//cycle through
	foreach($tables as $table)
	{
		$result = mysql_query('SELECT * FROM '.$table);
		$num_fields = mysql_num_fields($result);
		
		$return.= 'DROP TABLE '.$table.';';
		$row2 = mysql_fetch_row(mysql_query('SHOW CREATE TABLE '.$table));
		$return.= "\n\n".$row2[1].";\n\n";
		
		for ($i = 0; $i < $num_fields; $i++) 
		{
			while($row = mysql_fetch_row($result))
			{
				$return.= 'INSERT INTO '.$table.' VALUES(';
				for($j=0; $j<$num_fields; $j++) 
				{
					$row[$j] = addslashes($row[$j]);
					$row[$j] = ereg_replace("\n","\\n",$row[$j]);
					if (isset($row[$j])) { $return.= '"'.$row[$j].'"' ; } else { $return.= '""'; }
					if ($j<($num_fields-1)) { $return.= ','; }
				}
				$return.= ");\n";
			}
		}
		$return.="\n\n\n";
	}
	
	//save file
	$handle = fopen("/tmp/scampi_db_$pid.sql",'w+');
	fwrite($handle,$return);
	fclose($handle);
	return $return;
	
	if ($_REQUEST['action'] == 'restore') {
		shell_exec("mysql -h mysql.4ngs.com -u proch -pkcvqlha -D telatin < contigs.sql");
	}
}
?>
<h2>Restore</h2>
<div style="corner-radius: 8px; -webkit-border-radius: 8px;
-moz-border-radius: 8px;width: 350px; background-color: #FFE0E0; padding: 0.75em;">
<form  method="post" action="http://<?php echo $root; ?>">
This is a demo site:
<input type="hidden" name="action" value="restore"><input type="submit" value="Restore database backup"></form>
</div>
