<?php

        $rss = new DOMDocument();
        $rss->load('http://4ngs.com/scampi/news/feed/');
        $limit = 5;

        $feed = array();
        foreach ($rss->getElementsByTagName('item') as $node) {
                $item = array ( 
                        'title' => $node->getElementsByTagName('title')->item(0)->nodeValue,
                        'desc' => $node->getElementsByTagName('description')->item(0)->nodeValue,
                        'link' => $node->getElementsByTagName('link')->item(0)->nodeValue,
                        'date' => $node->getElementsByTagName('pubDate')->item(0)->nodeValue,
                        );
                array_push($feed, $item);
        }
        for($x=0;$x<$limit;$x++) {
                $title = str_replace(' & ', ' &amp; ', $feed[$x]['title']);
                $link = $feed[$x]['link'];
               	$description = substr($feed[$x]['desc'], 0, 130)."&hellip;";
                $date = date('F d, Y', strtotime($feed[$x]['date']));
                echo '<p><strong><a href="'.$link.'" title="'.$title.'">'."$title</a></strong> $date<br />";
		echo "$description";
}
?>


