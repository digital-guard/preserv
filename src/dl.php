<?php
$json_url = "http://127.0.0.1:3103/redirects?fhash=like.".str_replace("/","",$_SERVER['REQUEST_URI'])."*";
$json     = file_get_contents($json_url);
$data     = json_decode($json,TRUE);

if (isset($data[0]['fhash'])) {
    if (!empty($data[0]['furi'])) {
        header("Location: ".$data[0]['furi']);
    }
    else {
        header("Location: /download/".$data[0]['fhash']);
    }
}
else {
    header("Location: /download".$_SERVER['REQUEST_URI']);
}
?>
