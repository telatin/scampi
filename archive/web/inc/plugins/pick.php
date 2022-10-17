<script language="javascript" type="text/javascript" src="inc/plugins/pick/actb.js"></script>
<script language="javascript" type="text/javascript" src="inc/plugins/pick/common.js"></script>
<script language="javascript">
<!--
// Initialization of RequestObject
function createRequestObject() {
    var ro;
    var browser = navigator.appName;
    if(browser == "Microsoft Internet Explorer"){
        ro = new ActiveXObject("Microsoft.XMLHTTP");
    }else{
        ro = new XMLHttpRequest();    }
    return ro;}
var http = createRequestObject();

/* Send request to PHP script */
function complete(name) {
	
    http.open('get', 'inc/plugins/suggestcontig.php?q='+name);
    http.onreadystatechange = handleResponse;
    http.send(null);}

/* Manage received response */
function handleResponse() {				
    if(http.readyState == 4){
        var response = http.responseText;
        var update = new Array();
        
        var items = response.split('|');
        
        document.getElementById('answer').innerHTML = response;
       /*
        if(response.indexOf('|' != -1)) {
        	alert(items[0] + ' and ' + items[1]);
            document.getElementById('to').innerHTML = items[1];
            document.getElementById('from').innerHTML = from.value + items[0];
            
        }
        
        */
    }
}



function xstooltip_findPosX(obj) {
  var curleft = 0;
  if (obj.offsetParent)   {
    while (obj.offsetParent) {
            curleft += obj.offsetLeft
            obj = obj.offsetParent;
        }
    }
    else if (obj.x)
        curleft += obj.x;
    return curleft;
}

function xstooltip_findPosY(obj) {
    var curtop = 0;
    if (obj.offsetParent) {
        while (obj.offsetParent) {
            curtop += obj.offsetTop
            obj = obj.offsetParent;
        }
    }
    else if (obj.y)
        curtop += obj.y;
    return curtop;
}

function xstooltip_hide(id) {
    it = document.getElementById(id); 
    it.style.visibility = 'hidden'; 
}

function xstooltip_show(tooltipId, parentId, posX, posY) {
    it = document.getElementById(tooltipId);
    if ((it.style.top == '' || it.style.top == 0) 
        && (it.style.left == '' || it.style.left == 0))
    {
        // need to fixate default size (MSIE problem)
        it.style.width = it.offsetWidth + 'px';
        it.style.height = it.offsetHeight + 'px';
        
        img = document.getElementById(parentId); 
    
        // if tooltip is too wide, shift left to be within parent 
        if (posX + it.offsetWidth > img.offsetWidth) posX = img.offsetWidth - it.offsetWidth;
        if (posX < 0 ) posX = 0; 
        
        x = xstooltip_findPosX(img) + posX;
        y = xstooltip_findPosY(img) + posY;
        
        it.style.top = y + 'px';
        it.style.left = x + 'px';
    }
    
    it.style.visibility = 'visible'; 
}
-->
</script>
<script language=JavaScript>

/*
 * This is the function that actually highlights a text string by
 * adding HTML tags before and after all occurrences of the search
 * term. You can pass your own tags if you'd like, or if the
 * highlightStartTag or highlightEndTag parameters are omitted or
 * are empty strings then the default <font> tags will be used.
 */

function doHighlight(bodyText, searchTerm, highlightStartTag, highlightEndTag) {
  // the highlightStartTag and highlightEndTag parameters are optional
  if ((!highlightStartTag) || (!highlightEndTag)) {
    highlightStartTag = "<font style='color:blue; background-color:yellow;'>";
    highlightEndTag = "</font>";
  }

  

  // find all occurences of the search term in the given text,
  // and add some "highlight" tags to them (we're not using a
  // regular expression search, because we want to filter out
  // matches that occur within HTML tags and script blocks, so
  // we have to do a little extra validation)

  var newText = "";
  var i = -1;
  var lcSearchTerm = searchTerm.toLowerCase();
  var lcBodyText = bodyText.toLowerCase();


  while (bodyText.length > 0) {
    i = lcBodyText.indexOf(lcSearchTerm, i+1);
    if (i < 0) {
      newText += bodyText;
      bodyText = "";
    } else {
      // skip anything inside an HTML tag
      if (bodyText.lastIndexOf(">", i) >= bodyText.lastIndexOf("<", i)) {
        // skip anything inside a <script> block
        if (lcBodyText.lastIndexOf("/script>", i) >= lcBodyText.lastIndexOf("<script", i)) {
          newText += bodyText.substring(0, i) + highlightStartTag + bodyText.substr(i, searchTerm.length) + highlightEndTag;
          bodyText = bodyText.substr(i + searchTerm.length);
          lcBodyText = bodyText.toLowerCase();
          i = -1;
        }
      }
    }
  }

  return newText;

}





/*
 * This is sort of a wrapper function to the doHighlight function.
 * It takes the searchText that you pass, optionally splits it into
 * separate words, and transforms the text on the current web page.
 * Only the "searchText" parameter is required; all other parameters
 * are optional and can be omitted.
 */
function highlightSearchTerms(searchText, treatAsPhrase, warnOnFailure, highlightStartTag, highlightEndTag)
{
  // if the treatAsPhrase parameter is true, then we should search for 
  // the entire phrase that was entered; otherwise, we will split the
  // search string so that each word is searched for and highlighted
  // individually
  if (treatAsPhrase) {
    searchArray = [searchText];
  } else {
    searchArray = searchText.split(" ");
  }
  
  if (!document.body || typeof(document.body.innerHTML) == "undefined") {
    if (warnOnFailure) {
      alert("Sorry, for some reason the text of this page is unavailable. Searching will not work.");
    }
    return false;

  }


  /* HIGHLIGHT_WHERE */
  var bodyText = document.getElementById('sequencetable').innerHTML;
  for (var i = 0; i < searchArray.length; i++) {
    bodyText = doHighlight(bodyText, searchArray[i], highlightStartTag, highlightEndTag);
  }
  
  document.getElementById('sequencetable').innerHTML = bodyText;
  return true;
}



function hidesequence() {
  document.getElementById('sequencetable').innerHTML = '<br>';
  return true;

}



/* } */ 

/*
 * This displays a dialog box that allows a user to enter their own
 * search terms to highlight on the page, and then passes the search
 * text or phrase to the highlightSearchTerms function. All parameters
 * are optional.
 */
function searchPrompt(defaultText, treatAsPhrase, textColor, bgColor)
{
  // This function prompts the user for any words that should
  // be highlighted on this web page
  if (!defaultText) {
    defaultText = "";
  }
  
  // we can optionally use our own highlight tag values
  if ((!textColor) || (!bgColor)) {
    highlightStartTag = "";
    highlightEndTag = "";
  } else {
    highlightStartTag = "<font style='color:" + textColor + "; background-color:" + bgColor + ";'>";
    highlightEndTag = "</font>";
  }
  
  if (treatAsPhrase) {
    promptText = "Please enter the phrase you'd like to search for:";
  } else {
    promptText = "Please enter the words you'd like to search for, separated by spaces:";
  }
  
  searchText = prompt(promptText, defaultText);

  if (!searchText)  {
    alert("No search terms were entered. Exiting function.");
    return false;
  }
  
  return highlightSearchTerms(searchText, treatAsPhrase, true, highlightStartTag, highlightEndTag);
}


/*
 * This function takes a referer/referrer string and parses it
 * to determine if it contains any search terms. If it does, the
 * search terms are passed to the highlightSearchTerms function
 * so they can be highlighted on the current page.
 */

function highlightGoogleSearchTerms(referrer)
{
  // This function has only been very lightly tested against
  // typical Google search URLs. If you wanted the Google search
  // terms to be automatically highlighted on a page, you could
  // call the function in the onload event of your <body> tag, 
  // like this:
  //   <body onload='highlightGoogleSearchTerms(document.referrer);'>
  
  //var referrer = document.referrer;
  if (!referrer) {
    return false;
  }
  
  var queryPrefix = "q=";
  var startPos = referrer.toLowerCase().indexOf(queryPrefix);
  if ((startPos < 0) || (startPos + queryPrefix.length == referrer.length)) {
    return false;
  }
  
  var endPos = referrer.indexOf("&", startPos);
  if (endPos < 0) {
    endPos = referrer.length;
  }
  
  var queryString = referrer.substring(startPos + queryPrefix.length, endPos);
  // fix the space characters
  queryString = queryString.replace(/%20/gi, " ");
  queryString = queryString.replace(/\+/gi, " ");
  // remove the quotes (if you're really creative, you could search for the
  // terms within the quotes as phrases, and everything else as single terms)
  queryString = queryString.replace(/%22/gi, "");
  queryString = queryString.replace(/\"/gi, "");
  
  return highlightSearchTerms(queryString, false);
}


/*
 * This function is just an easy way to test the highlightGoogleSearchTerms
 * function.
 */
function testHighlightGoogleSearchTerms()
{
  var referrerString = "http://www.google.com/search?q=javascript%20highlight&start=0";
  referrerString = prompt("Test the following referrer string:", referrerString);
  return highlightGoogleSearchTerms(referrerString);
}



</script>
<h1>Primers for Finishing</h1>

<form id="form" action="?" method="get">
	<table>
	<input type="hidden" name="action" value="pick">
	<input type="hidden" name="plug" value="<? echo $_REQUEST['plug']; ?>">
	<input type="hidden" name="title" value="<? echo $_REQUEST['title']; ?>">
	<input type="hidden" name="h1" value="<? echo $_REQUEST['h1']; ?>">
		<tr style="background-color: #F0F0FF;">
			<td colspan="2">From contig:</td>
			<td colspan="2">To contig:</td>
			
					<td>Min T<sub>a</sub>:</td><td><input name="mintm" placeholder="55" size="4" value="<? echo $_REQUEST['mintm']; ?>"></td>
					<td>Max T<sub>a</sub>:</td><td><input name="maxtm" placeholder="60" size="4" value="<? echo $_REQUEST['maxtm']; ?>"></td>
		</tr>
		
		<tr style="background-color: #F0F0FF;">
			<td colspan="2"><input id="from" onkeyup="complete(this.value)" name="from" size="33" value="<? echo $_REQUEST['from']; ?>"></td>
			<td colspan="2"><input id="to"    name="to" size="33" value="<? echo $_REQUEST['to']; ?>"></td>
			<td>Min size:</td><td><input name="minsize" placeholder="160" size="4" value="<? echo $_REQUEST['minsize']; ?>"></td>
			<td>Max size:</td><td><input name="maxsize" placeholder="300"size="4" value="<? echo $_REQUEST['maxsize']; ?>"></td>
	
		</tr>
		
		<tr style="background-color: #F0F0FF;">
			<td colspan="2"> </td>
			<td colspan="2"> </td>
			<td>Primer length:</td><td><input name="optsize" placeholder="20" size="4" value="<? echo $_REQUEST['optsize']; ?>"></td>
			<td colspan="2" style="text-align:center;"><input type="submit" value="Pick Primers!"></td>
	
		</tr>

		<tr>
		
		</tr>		
	</table>
	<div id="answer">
	</div>
</form>
<!--
$mintm      = param('mintm')            || 55;
$maxtm      = param('maxtm')            || 60;
$minproduct = param('minproduct')   || 150;
$maxproduct = param('maxproduct')   || 300;
$optsize    = param('optsize')      || 18;
-->
<br>
<?
if ($_REQUEST['action']) {
	
	if (preg_match('/[CU]$/', $_REQUEST['from']) and preg_match('/[CU]$/', $_REQUEST['to'])) {
		print '<!-- Run -->';
		print shell_exec("perl ./inc/plugins/pick.pl contig1=$_REQUEST[from] contig2=$_REQUEST[to] mintm=$_REQUEST[mintm] maxtm=$_REQUEST[maxtm] minproduct=$_REQUEST[minsize] maxproduct=$_REQUEST[maxsize] silence=0 2>&1");
	} else {
		
		print "<h2>Error in contigs</h2><p>You have to specify the orientation in the <em>contig0123C</em> format (i.e. append U or C to contig name)</p>\n";
	}
}
?>