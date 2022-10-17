<!doctype html>

<?php 
	include_once('inc/tools.php');
	include_once('inc/db_con.php');
	include_once('inc/data_tools.php');
	if ($error) {
		print "<h2>Error</h2>
		<p>$error</p>";
		
	}
	$what = array('gt' => '>', 'lt' => '<', 'eq' => '=');

	$order = $_REQUEST['o'];
	$contigname = $_REQUEST['name'];
	
	$size = $_REQUEST['size'];
	$cov = $_REQUEST['cov'];
	
	$size1 = $_REQUEST['size_how'];
	$cov1 = $_REQUEST['cov_how'];
	
	$size2 = $what[$size1];
	$cov2 = $what[$cov1];
		if (!isset($order)) {$order = 'len DESC';}
	
	$contigname = $_REQUEST['name'];
	$scaffold_is = $_REQUEST['scaffold'];
	
	if (!empty($cov) and !is_null($cov2)) { $COV = "AND cov $cov2 $cov ";}
	if (!empty($size) and !is_null($size2)) { $SIZE = "AND len $size2 $size ";}
	if ($scaffold_is == 'Y') {$SCAFFOLD = 'AND NOT ISNULL(scaffold) ';}
	if ($scaffold_is == 'N') {$SCAFFOLD = 'AND  ISNULL(scaffold) ';}
	
	$order = $_REQUEST['o'];
	if (!isset($order)) {$order = 'len';}
	$desc  = $_REQUEST['i'];
	$ORDER = $order;
	if (isset($desc)) {$ORDER.= " ASC";} else {$ORDER.= " DESC";}
	$query = "SELECT * FROM $contigtable WHERE (name LIKE '%$contigname%') $COV $SIZE $SCAFFOLD ORDER BY $ORDER";
	print "<!-- query: $query -->\n";
	$handle = mysql_query($query);
	
 
	
		#$query = "SELECT * FROM $contigtable WHERE name like '%$contigname%' ORDER BY $order LIMIT 20";
		$handle = mysql_query($query);
		while ($contig_info = mysql_fetch_array($handle)) {
			$count_res++;
			$sum_len+=$contig_info[len];
			$list.="
			<tr>
			<td><a href=\"?name=$contig_info[name]\">$contig_info[name]</a></td>
			<td>$contig_info[cov]X</td>
			<td>$contig_info[len] bp</td>
			<td><a href=\"scaffold.php?name=$contig_info[scaffold]\">$contig_info[scaffold] $contig_info[sid]</a></td>
			</tr>";
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
	<h1><span style="color: #33C;font-weight: 400;">Contig selector</span> <span style="text-decoration: none;"><?php echo $contigname; ?></span></h1>
	</div>
<div id="main">


<form action="?">
<div id="contigpanel">
<table>
<tr>
	<td style="vertical-align:top">
		<div style="padding: 14px; background-color: #CEF;-moz-border-radius: 5px; border-radius: 5px;">
		<table>
		<tr><td>Name:</td><td> <strong>
		<form action="?">
		<input name="name" class="input" 
		size="10" type="text" value="<?php echo $contigname; ?>">
		</form></strong></td></tr>
		<tr><td>Size:</td><td> 
			<strong><select name="size_how">
				<option value="gt" <?if ($size1 == 'gt') {print 'selected="selected"';}?>>&gt;</option>
				<option value="lt" <?if ($size1 == 'lt') {print 'selected="selected"';}?>>&lt;</option>
				<option value="eq"<?if ($size1 == 'eq') {print 'selected="selected"';}?>>=</option>
			</select>
			<input class="input" name="size" size="6" value="<? echo $size; ?>">bp
			</strong></td></tr>
		<tr><td>Coverage:</td><td> <strong>
		
		<select name="cov_how">
				<option value="gt" <?if ($cov1 == 'gt') {print 'selected="selected"';}?>>&gt;</option>
				<option value="lt" <?if ($cov1 == 'lt') {print 'selected="selected"';}?>>&lt;</option>
				<option value="eq" <?if ($cov1 == 'eq') {print 'selected="selected"';}?>>=</option>
			</select>
			<input class="input" name="cov" size="6" value="<?php echo $cov; ?>">
		X
		
		</strong></td></tr>
		
		<tr>
			<td>In scaffold</td>
			<td><input type="radio" name="scaffold" value="Y" <? if ($scaffold_is =='Y')  { print 'checked="checked"';}?>/>Yes
			<input type="radio" name="scaffold" value="N" <? if ($scaffold_is =='N')  { print 'checked="checked"';}?>/>No
			<input type="radio" name="scaffold" value="" <? if ($scaffold_is =='')  { print 'checked="checked"';}?>/>Both
			</td>
		</tr>
		<tr><td></td></tr>
		<tr>
			<td>Order</td>
			<td>
			<select name="o">
				<option value="len" <?if ($order == 'len') {print 'selected="selected"';}?>>Size</option>
				<option value="cov" <?if ($order == 'cov') {print 'selected="selected"';}?> >Coverage</option>
				<option value="name" <?if ($order == 'Name') {print 'selected="selected"';}?>>Name</option>
				<option value="scaffold" <?if ($order == 'scaffold') {print 'selected="selected"';}?>>Scaffold</option>
			</select>
			
			<input type="checkbox" name="i" <? if ($desc) {print 'checked="checked"';}?>>Reverse
						</td>
		</tr>
		
		
				<tr><td></td><td>
		<input type="submit" value="Search"></td>
		</tr>
		<?php
		if ($contig_scaffold) {
		print "<tr><td>Scaffold:</td><td> <strong><a href=\"scaffold.php?name=$contig_scaffold\">$contig_scaffold</a></strong> ($contig_sid)</td></tr>";
		}
		?>

		</table>
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
		print "Select a contig from the list or type its name in the search box.<br>Found $count_res contigs, $sum_len bp<br><br>
		
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
</form>


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
