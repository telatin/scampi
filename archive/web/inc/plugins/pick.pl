#!/usr/bin/perl
use CGI qw(:standard);
#print "Content-type: text/html\n\n";

# Program constants

# ======================================================
# BINARIES EXPECTED FOR PICK PRIMERS TO WORK
# ======================================================
$primer3='/home/proch/tools/primer3/src/primer3_core';	# Primer3 binary
$blast = '/home/proch/blast/bin/blastall';				# blastall binary 
# ======================================================

# ======================================================
# OTHER VARIABLES TO SET (DEFAULT SETTINGS COULD WORK)
# ======================================================
$blastdb   = './inc/plugins/blast/contigs.fa';			# BLAST database (contigs)
$contigpath='contigs/';									# directory containing contigs as single fasta files
$outputdir = '/tmp/';									# Directory where to save files (/tmp)
$contigext ='fa';										# Extension of contigs files (fa)
# ======================================================


$rand=int(rand(10000));
$id=1;

# Determine script filename
$0 =~/([^\\\/]+)$/;
$scriptname = $1; 

# Get CGI parameters
$contig1    = param('contig1') || 'contig00001U';
$contig2    = param('contig2') || 'contig00002C';
$mintm      = param('mintm')            || 55;
$maxtm      = param('maxtm')            || 60;
$minproduct = param('minproduct')   || 160;
$maxproduct = param('maxproduct')   || 300;
$optsize    = param('optsize')      || 20;
$silence    = param('silence');
 
printheader() unless ($silence);
$x = `pwd`;
# Check contig path and primer3
$msg.= " <strong>FATAL ERROR $x:</strong><br>\n Unable to locate contigs path: $contigpath <br>\n" unless (-d $contigpath);
$msg.= " <strong>FATAL ERROR $x:</strong><br>\n Unable to locate primer3 executable: $primer3 <br>\n" unless (-e $primer3);
$msg.= " <strong>FATAL ERROR $x:</strong><br>\n Unable to locate blast executable: $blast <br>\n" unless (-e $blast);
#$msg.= " <strong>FATAL ERROR:</strong><br>\n Unable to locate blast database: $blastdb <br>\n" unless (-e "$blastdb.nih");

#Contig given in the format contigname[U|C]. Remove last character (orientation) and check it
$orient1 = uc(chop($contig1));
$orient2 = uc(chop($contig2));
$msg.= " <strong>FATAL ERROR:</strong><br>\n Missing contig orientation? [$contig1 $orient1 - $contig2 $orient2]\n" if (($orient1!~/[UC]/) or ($orient1!~/[UC]/));
if (!$contig1 or !$contig2) {
		print "<p>Missing parameters: two contig names (with direction) are required.</p>";
        end;
}
# Load contigs from path and check them
$c1 = loadseq("$contigpath$contig1\.$contigext"); 
 $msg.= " <strong>FATAL ERROR $x:</strong><br>\n Unable to open contig1: '$contigpath$contig1'.<br>\n" if (!$c1);
$c2 = loadseq("$contigpath$contig2\.$contigext"); 
 $msg.= " <strong>FATAL ERROR $x:</strong><br>\n Unable to open contig2: '$contigpath$contig2'.<br>\n" if (!$c2);
$l1 = length($c1);
$l2 = length($c2);


print "<p>$msg</p>";

if ($orient1 eq 'U') {  $d1 = 'right'; } else { $d1 = 'left'; }
if ($orient2 eq 'U') {  $d2 = 'right'; } else { $d2 = 'left'; }

if (!$silence) {
# print cell containing visual contig orientation
my $cell  = qq(
<tr style="background:#FFFFE0; font-size: 14px;text-align: left;">
<td colspan="3">
<strong><a href="contig.php?name=$contig1">$contig1</a></strong> ($l1 bp) 
<img align="absmiddle" width="32" height="32" src="inc/plugins/pick/$d1\_arrow.png">
<img align="absmiddle" width="32" height="32" src="inc/plugins/pick/$d2\_arrow.png"> 
<strong><a href="contig.php?name=$contig2">$contig2</a></strong> ($l2 bp)
</td></tr>
</table>
);
print $cell;

}



# Prepare template
$c1 = rc($c1) if ($orient1 eq 'C');
$c2 = rc($c2) if ($orient2 eq 'C');

# Merge template
$minus = $maxproduct*-1;
if (length($c1)>$maxproduct) {
        $ctemp=reverse($c1);
        $begin =  substr($ctemp, 0, $maxproduct+100);
        $begin = reverse($begin);
} else {
        $begin = $c1;
}
if (length($c2)>$maxproduct) {
        $end = substr($c2, 0, $maxproduct+100);
} else {
        $end = $c2;
}
$myseq = $begin.'nnnnnn'.$end;
$myhtmlseq=$begin.'<span style="color:gray;">nnnnnn</span>'.$end;
$len=length($begin).'+'.length($end);
$from = length($begin)-3;
$to   = 8;
unless ($silence) {
        $seqtable= "
        <tr>
        <td style=\"word-break:break-all; font-size:11px;font-family:Andale mono, Courier new, monospace;\">
        <strong>&gt;$contig1-$contig2</strong><a href=\"#\" onclick=\"hidesequence();\">Hide sequence</a><br>
        $myhtmlseq
        </td>
        </tr>
        ";
        print   "<table width=\"600\" id=\"sequencetable\">".$seqtable."</table>";
}
# Prepare primer3 file
$file="SEQUENCE_ID=$contig1$orient1\_$contig2$orient2
PRIMER_TM_FORMULA=1
PRIMER_SALT_CORRECTIONS=1
SEQUENCE_TEMPLATE=$myseq
SEQUENCE_TARGET=$from,$to 
PRIMER_MIN_TM=$mintm
PRIMER_MAX_TM=$maxtm
PRIMER_TASK=pick_detection_primers
PRIMER_PICK_LEFT_PRIMER=1 
PRIMER_PICK_INTERNAL_OLIGO=0
PRIMER_PICK_RIGHT_PRIMER=1
PRIMER_OPT_SIZE=$optsize
PRIMER_MIN_SIZE=14
PRIMER_MAX_SIZE=28
PRIMER_MAX_NS_ACCEPTED=0
PRIMER_PRODUCT_SIZE_RANGE=$minproduct-$maxproduct
P3_FILE_FLAG=0
PRIMER_EXPLAIN_FLAG=0
=
";

# Save to file
open O, ">$outputdir$contig1$orient1\_$contig2$orient2.txt" or print "<b>FATAL ERROR</b>: UNABLE TO WRITE\n";
print O "$file";
# Execute primer3
@output = `$primer3 < $outputdir$contig1$orient1\_$contig2$orient2.txt`;

# Print output!
print "<!--<h2>Primers for <a href=\"contigsreads.php?p=$contig1\">$contig1$orient1</a> to <a href=\"contigsreads.php?p=$contig2\">$contig2$orient2</a></h2>-->".
'<table id="primers" border="0" cellspacing="0" cellpadding="3">';
foreach $l (@output) {
        print O "$l";
        if ($l=~/ERROR/) {
                print "<tr><td>$l</td></tr>";
        }
        if ($l=~/LEFT_(\d+)_PENALTY/) {
        		$laltro=pop(@primers);
        		$last=pop(@primers);
				if ($last) {
					#print "<tr><td bgcolor=\"#F0F0F0\">Primers with list</td><td><a href=\"primerview.php?seqfor=$last&seqrev=$laltro\">Add primers</a></td></tr>\n";
				}
				print "<tr><td><strong>PRIMER PAIR $1</strong></td><td></td></tr>";
        } elsif ($l=~/_($1)_/) {
                ($left, $right) = split /=/, $l;
                $left=~s/(_[0-9]_|_)/ /g;
                my $tag;
                if ($left=~/SEQUENCE/) {
                        chomp($right);
                        $seqp = 'TEMPSPAM';
                        $seqp = $right if ($left=~/LEFT/);
                        $seqp = rc($right) if ($left=~/RIGHT/);
						push(@primers, $right);
                        ($tag, $num, $tot)=blast($right);
                        if ($silence) {
                        $tag="(<a href=\"blast.pl?evalue=1&sequence=$seqp\">$tot hits</a>)";
                        } else {

                        $tag.="<img src=\"inc/plugins/pick/info.png\" id=\"box_$num\" 
                        onmouseover=\"xstooltip_show('tooltip_$num', 'box_$num', 20, 20);\" 
                        onmouseout=\"xstooltip_hide('tooltip_$num');\" > 
                        <span style=\"font-size:10px; text-decoration:underline; color:gray;cursor: pointer;\" onclick=\"highlightSearchTerms('$seqp', false, true)\">Highlight</span>";
                        }
                } else {
                        $tag='';
                } 
                if ($rev) {
                                $revprim=rc($rev);
                                $myseq=~/($for)(\w*)($revprim)/;
                                print "<tr><td>Amplicon</td></td><strong>$1</strong>$2<strong>$3</strong></td></tr>";
                                $for='';
    					        $rev='';
                        }
                if ($left=~/(SEQUENCE|TM|SIZE)/) {
                        print "<tr><td bgcolor=\"#F0F0F0\">$left</td><td>$right 
                        $tag
                        </td></tr>";

                } else {
                        print "<!-- $left = $right -->\n" if ($debug);  
                } 

        }
}

$laltro=pop(@primers);
$last=pop(@primers);
if ($last) {
	#print "<tr><td bgcolor=\"#F0F0F0\">Primers with list</td><td><a href=\"primerview.php?seqfor=$last&seqrev=$laltro\">Add primers</a></td></tr>\n";
}
print '</table>';

if (param('debug')) {
        print "<pre>@output</pre>";
}

print '</body></html>';

sub loadseq {
        my $name = shift;
        my $seq;
        open (I, "$name") or die " FATAL ERROR $x:\n Unable to load $name\n";
        while (<I>) {
                chomp;
                next if ($_=~/\>/);
                $seq.=$_;
        }
        return $seq;
}

sub rc {
        my $s = shift;
        $s=reverse($s);
        $s=~tr/ACGTNacgtn/TGCANtgcan/;
        return $s;
}

sub blast {
        my $s = shift;
        $id++;
        my $count;
        my $string;
        my @out = `echo $s | $blast -p blastn -e 1 -m 8 -d $blastdb`;
        print "<!-- echo $s | $blast -p blastn -e 1 -m 8 -d $blastdb -->\n" if ($debug);
        foreach my $l (@out) {
                my ($x, $ctg, $id, $len, $mm, $x, $x, $x,$start, $end) = split /\t/, $l;
                my $t1; my $t2;
                if ($ctg=~/($contig1|$contig2)/) {
                 $t1='<span style="color:gray;">'; $t2='</span>';

                }
                $count++ if ($len >= length($s)-2);

                $string.="$t1$ctg: Aligned $len bp, $id\% ($start-$end)$t2<br>";


        }
        $string="($count hits)".' <div id="tooltip_'.$id.'" class="xstooltip">'.$string.'</div>';
        return ($string, $id, $count);
}

sub printheader {
print<<END;

<style>
<!--

.xstooltip {
    visibility: hidden; 
    position: absolute; 
    top: 0;  
    left: 0; 
    z-index: 2; 
    background:white;
    font-size:0.8em; 
    padding: 3px; 
    border: solid 1px;
}
-->
</style>



<body>



<!--
<table style="font-size:11px;" bgcolor="#ECECEC" width="600" border="0" cellspacing="3" cellpadding="3px">
<form id="form1" name="form1" method="get" action="">
  <tr>
    <td colspan="3" bgcolor="#99CCFF">
        <label>From contig:
          <input name="contig1" type="text" id="from" size="16" maxlength="33" value="$contig1"/>
        </label>    <label>To contig:
          <input name="contig2" type="text" id="to" size="16" maxlength="33" value="$contig2" />
    </label></td>
    </tr>
  <tr>
    <td width="33%"><label>Min amplicon size:
      <input name="minproduct" type="text" id="minproduct" size="4" maxlength="4" value="$minproduct" />
    </label></td>
    <td width="33%"><label>Min T<sub>M</sub>:
      <input name="mintm" type="text" id="mintm" size="4" maxlength="2" value="$mintm" />
    </label></td>
    <td  width="33%"><label>Ideal primer size:
      <input name="optsize" type="text" id="optsize" size="4" maxlength="2" value="$optsize" />
    </label></td>
  </tr>
  <tr>
    <td><label>Max amplicon size:
      <input name="maxproduct" type="text" id="maxproduct" size="4" maxlength="4"  value="$maxproduct" />
    </label></td>
    <td><label>Max T<sub>M</sub>:
      <input name="maxtm" type="text" id="maxtm" size="4" maxlength="2"  value="$maxtm" />
    </label></td>
    <td><label>
      <input type="checkbox" name="silence" id="silence" />
      Silent output</label></td>
  </tr>
         <td> </td>
         <td> </td>
         <td><input type="submit"> </td>
</form>
-->
END

}

