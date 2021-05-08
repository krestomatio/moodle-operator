#!/usr/bin/php
<?php
define('CLI_SCRIPT', true);
define('CACHE_DISABLE_ALL', true);

$MOODLE_COMMIT  = getenv('MOODLE_COMMIT') ?: false;
$MOODLE_APP = getenv('MOODLE_APP') ?: '/var/www/html';
require($MOODLE_APP . '/config.php');


$files_total_sql = "SELECT SUM(d.filesize) AS value
                    FROM (SELECT DISTINCT f.contenthash, f.filesize
                    FROM {files} f) d";

$files_total = $DB->get_field_sql($files_total_sql);
$five_minutes_ago = time() - 300;
$active_users = $DB->get_field_sql('SELECT COUNT(id) FROM {user} WHERE lastaccess > ?', [$five_minutes_ago]);
$registered_users = $DB->get_field_sql('SELECT COUNT(id) FROM {user} WHERE deleted = 0 AND id > 2', [$five_minutes_ago]);
$database_size = $DB->get_field_sql('SELECT pg_database_size(?)',['moodle']);
// $active_users = $DB->get_record_sql('SELECT lastaccess FROM {user} WHERE id = 2');

$instance = array(
    "version" => "$CFG->version",
    "release" => "$CFG->release",
    "allversionshash" => "$CFG->allversionshash"
);

$instance['registered_users'] = $registered_users;
$instance['active_users'] = $active_users;
$instance['files_total'] = $files_total;
$instance['database_size'] = $database_size;

if ($MOODLE_COMMIT){
    $instance['commit'] = $MOODLE_COMMIT;
}

echo json_encode($instance);
?>
