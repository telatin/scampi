<?
	$minarcs = 10;	
	
	include_once('../db_con.php');
	$answer = array();
	
	$q = mysql_real_escape_string($_REQUEST['q']);
	
	$fx = mysql_query("SELECT c1,c2,arcs FROM $arcstable WHERE ((c1 LIKE '$q%') OR (c2 LIKE '$q%'))  AND arcs > $minarcs ORDER BY arcs DESC");
	//$results[] = array('query' => "SELECT c1,c2 FROM $arcstable WHERE ((c1 LIKE '$q%') OR (c2 LIKE '$q%'))  AND arcs > $minarcs ORDER BY arcs DESC");
	while ($r = mysql_fetch_array($fx)) {
		if (preg_match("/^$q/", $r['c1']) and !preg_match("/^$q/", $r['c2'])) {
			// query è C1 -> C2
			if ($r['e1'] == 3) {
				// =======>
				if ($r['e2'] == 5) { // ===========>}
					$t.= "<a href=\"#\"	onclick=\"document.forms['form'].from.value='$r[c1]U';document.forms['form'].to.value='$r[c2]U';\">".$r['c1']."U  &rarr;  ".$r['c2'].'U'."</a> with $r[arcs] arcs <br>";
					$results[] = array('contig' => $r['c2'].'U');
					$results[] = array('tag'    => 'U');
				} else {// <==========}
					$t.= "<a href=\"#\" onclick=\"document.forms['form'].from.value='$r[c1]U';document.forms['form'].to.value='$r[c2]C';\">".$r['c1']."U  &rarr;  ".$r['c2'].'C'."</a> with $r[arcs] arcs <br>";
					$results[] = array('contig' => $r['c2'].'C');
					$results[] = array('tag'    => 'U');
					
					
				}
 			} else {
				if ($r['e2'] == 5) { // ===========>}
					$t.= "<a href=\"#\" onclick=\"document.forms['form'].from.value='$r[c1]C';document.forms['form'].to.value='$r[c2]U';\">".$r['c1']."C  &rarr;  ".$r['c2'].'U'."</a> with $r[arcs] arcs <br>";
					$results[] = array('contig' => $r['c2'].'U');
					$results[] = array('tag'    => 'C');
				} else {// <==========}
					$t.= "<a href=\"#\" onclick=\"document.forms['form'].from.value='$r[c1]C';document.forms['form'].to.value='$r[c2]C';\">".$r['c1']."C  &rarr;  ".$r['c2'].'C'."</a> with $r[arcs] arcs <br>";
					$results[] = array('contig' => $r['c2'].'C');
					$results[] = array('tag'    => 'C');
					
					
				}	 			
	 			
 			}
			
		} elseif (preg_match("/^$q/", $r['c2']) and !preg_match("/^$q/", $r['c1'])){
				// query è C2 		
			if ($r['e2'] == 3) {
				//                                       <=======
				if ($r['e1'] == 5) { // <===========}
					$t.= "<a href=\"#\" onclick=\"document.forms['form'].from.value='$r[c2]C';document.forms['form'].to.value='$r[c1]C';\">".$r['c2']."C  &rarr;  ".$r['c1'].'C'."</a> with $r[arcs] arcs <br>";
					$results[] = array('contig' => $r['c1'].'C');
					$results[] = array('tag'    => 'C');
				} else {// ==========>}
					$t.= "<a href=\"#\" onclick=\"document.forms['form'].from.value='$r[c2]C';document.forms['form'].to.value='$r[c1]U';\">".$r['c2']."C  &rarr;  ".$r['c1'].'U'."</a> with $r[arcs] arcs <br>";
					$results[] = array('contig' => $r['c1'].'U');
					$results[] = array('tag'    => 'C');
					
					
				}
 			} else {                                   //  =======>
				if ($r['e1'] == 5) { // <===========}
					$t.= "<a href=\"#\" onclick=\"document.forms['form'].from.value='$r[c2]U';document.forms['form'].to.value='$r[c1]C';\">".$r['c2']."U  &rarr;  ".$r['c1'].'C'."</a> with $r[arcs] arcs <br>";
					$results[] = array('contig' => $r['c1'].'C');
					$results[] = array('tag'    => 'U');
				} else {// =========>}
					$t.= "<a href=\"#\" onclick=\"document.forms['form'].from.value='$r[c2]U';document.forms['form'].to.value='$r[c1]U';\">".$r['c2']."U  &rarr;  ".$r['c1'].'U'."</a> with $r[arcs] arcs <br>";
					$results[] = array('contig' => $r['c1'].'U');
					$results[] = array('tag'    => 'U');
					
					
				}	 			
	 			
 			}
			
		}
		
	}
	print " <br>".$t."</body></html><!--";
	//print json_encode($results);
?>