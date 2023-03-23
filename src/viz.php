<?php
$json_url = "http://127.0.0.1:3103/rpc/redirects_viz?p_uri=".$_SERVER['REQUEST_URI'];
$json     = file_get_contents($json_url);
$data     = json_decode($json,TRUE);

if (!empty($data[0]['error'])) {
    if (!empty($data[0]['url_layer_visualization'])) {
        header("Location: ".$data[0]['url_layer_visualization']);
    }
    else {
        header("HTTP/1.1 404 Not Found");
    }
}
else {
    header("HTTP/1.1 404 Not Found");
}
?>
