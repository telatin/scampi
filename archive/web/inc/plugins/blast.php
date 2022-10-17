<h1>Online BLAST</h1>

<?php
$customblast = '/home/proch/blast/bin/blastall'; // full path to BLAST binary if not system wide available

$root=$_SERVER["SERVER_NAME"].$_SERVER["REQUEST_URI"];
$seq = $_REQUEST['seq'];
$evalue = $_REQUEST['evalue'];
$program = $_REQUEST['program'];
$format = $_REQUEST['format'];

$f = shell_exec("which formatdb");
$blastcmd = 'blastall';
if ($f=='') {
	if (!file_exists($customblast)) {
		
		$msg.="<p>BLAST program not found! Try <em>sudo aptitude install blast2</em> on a Ubuntu/Debian machine.<pre>$f</pre></p>";
	} else {
		$blastcmd = $customblast;
	}
} 
if (file_exists('inc/plugins/blast/contigs.fa.nin')) {
	$ok;
} elseif (file_exists('inc/plugins/blast/contigs.fa')) {
	$msg.='<p>Contigs file found but no BLAST database in place. Please create a BLAST database using <em>formatdb -p F -i contigs.fa</em> in the <em>web/inc/plugins/blast/</em> directory</p>';
} else {
	
	$msg.='<p>This plugin requires a /blast directory under the plugins one, containing contigs.fa formatted as BLAST database</p>';
	
}
if ($msg) {
	print "<h3>Some errors found:</h3>
	$msg
	
	<!-- /messages -->
	<p><em>Please, fix these issues before using the BLAST interface</em></p>\n";
	exit;
}
?>

<form action="http://<?php echo $root; ?>" method="POST">
<table>
<tr>
Sequence:<br>
<textarea cols="60" rows="8" name="seq" placeholder="Type your sequence here..." /><?php echo $seq; ?></textarea>
</tr>

<tr><td>Program</td>
<td>
<select name="program">
  <option value="blastn"  <?php if ($evalue == 'blastn') { print 'selected'; } ?>>BlastN</option>
  <option value="blastx"  <?php if ($evalue == 'blastx') { print 'selected'; } ?>>BlastX</option>
</select> </td></tr>

<tr><td>E-Value</td>
<td>
<select name="evalue">
  <option value="10" <?php if ($evalue == '10') { print 'selected'; } ?>>10</option>
  <option value="0.1" <?php if ($evalue == '0.1') { print 'selected'; } ?>>0.1</option>
  <option value="10e-3" <?php if ($evalue == '10e-3') { print 'selected'; } ?>>10 E-3</option>
  <option value="10e-3" <?php if ($evalue == '10e-6') { print 'selected'; } ?>>10 E-6</option>
  <option value="10e-9" <?php if ($evalue == '10e-9') { print 'selected'; } ?>>10 E-9</option>
  <option value="10e-12" <?php if ($evalue == '10e-12') { print 'selected'; } ?>>10 E-12</option>
  <option value="10e-18" <?php if ($evalue == '10e-18') { print 'selected'; } ?>>10 E-18</option>
</select>
</td></tr>
<tr><td>Output</td>
<td>
<select name="format">
  <option value="8" <?php if ($evalue == '8') { print 'selected'; } ?>>Tabular</option>
  <option value="0" <?php if ($evalue == '0') { print 'selected'; } ?>>Full BLAST</option>
</select>
</td></tr>


<tr>
<td></td>
<td><input type="submit" value="blast" /></td></tr>


</table>

</form>



<?
if ($program and $seq) {
	$w = shell_exec("pwd");
	
	$blast = shell_exec("echo \"$seq\" | $blastcmd -p $program -e $evalue -m $format -d ./inc/plugins/blast/contigs.fa");
	$l = explode("\n", $blast);
	$print = 0;
	if ($format == 0) {
		foreach ($l as &$i) {
			if (preg_match('/Score/i', $i)) { $print = 1; }
			if ($print) { $out.= "$i\n"; }
		}
	} else {
		foreach ($l as &$i) {
			$f = explode("\t", $i);
			$table.="<tr>";
			$c=0;
			foreach ($f as &$x) {
				$c++;
				if ($c==1) {continue;}
				if ($c==2) {$x = "<a href=\"contig.php?name=$x\">$x</a>";}
				$table.="<td>$x</td>";
				}
				$table.="</tr>\n";
		}
	}
	
	if($table) {
		print "<table>
		<tr style=\"font-weight:bold;\"><td>Contig</td><td>%id</td><td>Matches</td>
		<td></td><td></td><td></td><td></td>
		<td>From</td><td>To</td><td>e-val</td><td>BitScore</td></tr>$table</table>\n";
	} else {
		print "<pre>\n$out\n</pre>\n";
	}
	
}	
?>

