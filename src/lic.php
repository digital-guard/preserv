<?php
$string1 = $_SERVER['REQUEST_URI'];
$pattern1 = '/^\/(.+)/i';
$replacement1 = '${1}';

$json_url = "http://127.0.0.1:3105/rpc/plicenses?p_string=".preg_replace($pattern1, $replacement1, $string1);
$json     = file_get_contents($json_url);
$data     = json_decode($json,TRUE);

if (empty($data['error'])) {
    if (!empty($data['url'])) {
        header("Location: ".$data['url']);
    }
    else {
        http_response_code(404);
    }
}
else {
    http_response_code(404);
}
?>
