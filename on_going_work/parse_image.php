<?php
include('simple_html_dom.php');
$html = file_get_html('http://www.systembolaget.se/Sok-dryck/Dryck/?artikelId=335527&varuNr=6697');

foreach($html->find('div#ctl00_FullRegion_LeftCenterRegion_ProductImageDiv') as $div);

foreach($div->find('a') as $img);

echo '<img src="http://www.systembolaget.se/Sok-dryck/Dryck' . $img->href . '">';
?>
