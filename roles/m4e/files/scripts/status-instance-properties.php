#!/usr/bin/php
<?php
define('CLI_SCRIPT', true);
define('CACHE_DISABLE_ALL', true);

$MOODLE_COMMIT  = getenv('MOODLE_COMMIT') ?: false;
$MOODLE_APP = getenv('MOODLE_APP') ?: '/var/www/html';
require($MOODLE_APP . '/config.php');

# Convert bytes to gigabytes
function convertBytesToGB($bytes) {
    return $gigabytes = round($bytes / 1024 / 1024 / 1024,1);
}

# get total files in bytes from moodle database
$files_bytes_sql = "SELECT SUM(d.filesize) AS value
                    FROM (SELECT DISTINCT f.contenthash, f.filesize
                    FROM {files} f) d";
$files_bytes = $DB->get_field_sql($files_bytes_sql);

# get database size in bytes
$database_bytes_sql = "SELECT pg_database_size(?)";
$database_bytes = $DB->get_field_sql($database_bytes_sql,['moodle']);

# save storage in array
$storage = array(
    "files" => convertBytesToGB($files_bytes),
    "database" => convertBytesToGB($database_bytes),
    "total" => convertBytesToGB($files_bytes+$database_bytes),
    "unit" => "GB"
);

# get active users (lastaccess 5 minutes ago)
$five_minutes_ago = time() - 300;
$active_users_sql = "SELECT COUNT(id) FROM {user} WHERE lastaccess > ?";
$active_users = $DB->get_field_sql($active_users_sql, [$five_minutes_ago]);

# get registered users (minus delete ones, guest and admin)
$registered_users_sql = "SELECT COUNT(id) FROM {user} WHERE deleted = 0 AND id > 2";
$registered_users = $DB->get_field_sql($registered_users_sql);

# save users in array
$users = array(
    "registered" => $registered_users,
    "active" => $active_users
);

# save version properties in array
$moodle = array(
    "version" => $CFG->version,
    "release" => $CFG->release,
    "allversionshash" => $CFG->allversionshash
);

if ($MOODLE_COMMIT){
    $instance['commit'] = $MOODLE_COMMIT;
}

# use one array
$properties = array(
    "moodle" => $moodle,
    "users" => $users,
    "storage" => $storage
);

# export as json
echo json_encode($properties);
?>
