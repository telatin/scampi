<div id="navcontainer" style="width: 100%;">
<ul style="padding:3px;">

<li><a href="index.php" <? if (preg_match('/index.php/', $_SERVER['REQUEST_URI'])) { echo 'style="font-weight:700;"';}?>>Home</a></li><li><a href="contig.php" <? if (preg_match('/contig.php/', $_SERVER['REQUEST_URI'])) { echo 'style="font-weight:700;"';}?>>Contig Browser</a></li><li><a href="scaffold.php" <? if (preg_match('/scaffold.php/', $_SERVER['REQUEST_URI'])) { echo 'style="font-weight:700;"';}?>>Scaffolds</a></li><li><a href="scampi.php?seed=<?php echo $contigname; ?>" <? if (preg_match('/scampi.php/', $_SERVER['REQUEST_URI'])) { echo 'style="font-weight:700;"';}?>>Scaffolder</a></li>

<?php
// SCAN FOR PLUGINS!
if ($handle = opendir('inc/plugins/')) {
   
    /* This is the correct way to loop over the directory. */
    while (false !== ($entry = readdir($handle))) {
    	if (preg_match('/^_(.*).php$/', $entry, $h)) {
    	$l = ucfirst($h[1]);
        	include_once("inc/plugins/$entry");
        	if (!isset($hide)) {
        	$sum=hash('md5', "$file$title");
        	$plugin_title2=base64_encode($plugin_title);
        	$linktitle = $plugin_desc;
        	if ($_REQUEST['plug'] == $plugin_file) { $dec = 'bold'; } else { $dec = '300'; }
        	print "<li><a style=\"font-weight: $dec\" title=\"$linktitle\" 
        	href=\"plugin.php?plug=$plugin_file&title=$name&h1=$plugin_title2\">$plugin_name</a></li>";
        	}
        }
    }

   
    closedir($handle);
    unset($plugin_title);
 	unset($plugin_desc);   
}	
?>

<li><a href="help.php" title="Online manual">?</a></li>
</ul>
</div>

<div id="footer">
<?
include_once('inc/db_con.php');
echo "
<a href=\"http://genomics.cribi.unipd.it/scampi/\">

<strong style=\"font-size: 1.2em; color: #A00 !important;\">
ScaMPI Scaffolding program
</strong>
</a> - Project &laquo;".ucfirst($scampi_project)."&raquo;</em>";
?>
</div>
