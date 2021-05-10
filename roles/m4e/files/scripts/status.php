#!/usr/bin/php
<?php
define('CLI_SCRIPT', true);

$MOODLE_COMMIT = getenv('MOODLE_COMMIT') ?: false;
$MOODLE_APP = getenv('MOODLE_APP') ?: '/var/www/html';
require($MOODLE_APP . '/config.php');
require_once($CFG->libdir.'/clilib.php');

list($options, $unrecognized) = cli_get_params([
    'help'    => false,
    'checks' => false,
    'version' => false,
    'usage' => false
], [
    'h' => 'help',
    'c' => 'checks',
    'v' => 'version',
    'u' => 'usage'
]);

if ($unrecognized) {
    $unrecognized = implode(PHP_EOL.'  ', $unrecognized);
    cli_error(get_string('cliunknowoption', 'core_admin', $unrecognized));
}

if ($options['help']) {
    cli_writeln("Get Moodle properties, usage and checks as json
Options:
    -h, --help                      Print out this help
    -c, --checks=critical,error     Include moodle checks
    -u, --usage                     Include moodle usage (storage and registered users)
    -v, --version                   Include moodle properties related with its version
Example:
\$ sudo -u www-data status.php -c -u -v");
    exit(2);
}

# array to export as json
$json = array();

# Convert bytes to gigabytes
function convertBytesToGB($bytes) {
    return $gigabytes = round($bytes / 1024 / 1024 / 1024,1);
}

if($options['version']){
    # save version properties in array
    $version = array(
        "version" => $CFG->version,
        "release" => $CFG->release,
        "allversionshash" => $CFG->allversionshash,
        "branch" => $CFG->branch,
    );

    if ($MOODLE_COMMIT){
        $version['commit'] = $MOODLE_COMMIT;
    }

    $json['version'] = $version;
}

if($options['usage']){
    # get total files in bytes from moodle database
    $files_bytes_sql = "SELECT SUM(d.filesize) AS value
                        FROM (SELECT DISTINCT f.contenthash, f.filesize
                        FROM {files} f) d";
    $files_bytes = $DB->get_field_sql($files_bytes_sql);

    # get total database size in bytes
    $database_bytes_sql = "SELECT pg_database_size(?)";
    $database_bytes = $DB->get_field_sql($database_bytes_sql,['moodle']);

    # get registered users (minus delete ones, guest and admin)
    $registered_users_sql = "SELECT COUNT(id) FROM {user} WHERE deleted = 0 AND id > 2";
    $registered_users = (int) $DB->get_field_sql($registered_users_sql);

    # save total storage of files in array
    $storage_files = array(
        "name" => "storage_files",
        "value" => convertBytesToGB($files_bytes),
        "unit" => "GB",
        "description" => "Total storage used for files"
    );

    # save total storage of database in array
    $storage_database = array(
        "name" => "storage_database",
        "value" => convertBytesToGB($database_bytes),
        "unit" => "GB",
        "description" => "Total storage used for database"
    );

    # save total storage in array
    $storage_total = array(
        "name" => 'storage_total',
        "value" => convertBytesToGB($files_bytes+$database_bytes),
        "unit" => "GB",
        "description" => "Total storage used (database + files)"
    );

    # save total users in array
    $users_total = array(
        "name" => "users_total",
        "value" => $registered_users,
        "unit" => "users",
        "description" => "Total users registered"
    );

    $json['usage'][] = $storage_files;
    $json['usage'][] = $storage_database;
    $json['usage'][] = $storage_total;
    $json['usage'][] = $users_total;
}

if($options['checks']){
    if (is_bool($options['checks'])){
        $filter_status = array('critical','error');
    }else{
        $filter_status = explode( ',', strtolower($options['checks']));
    }

    $types = array('status', 'security', 'performance');
    $all_checks = array();

    foreach ($types as $type){
        $method = 'get_' . $type . '_checks';
        $checks = \core\check\manager::$method();
        foreach ($checks as $check){
            $result = $check->get_result();
            $status = $result->get_status();
            if (empty($filter_status) || in_array("all", $filter_status) || in_array(strtolower($status), $filter_status)) {
                $type_check = array();
                // $action_link = $check->get_action_link();
                $type_check['type'] = $type;
                $type_check['status'] = $status;
                $type_check['ref'] = $check->get_ref();
                $type_check['name'] = $check->get_name();
                $type_check['summary'] = $result->get_summary();
                // $type_check['details'] = $result->get_details();
                // if ($actionlink){
                //     $type_check['action_link']['name'] = $actionlink->name;
                //     $type_check['action_link']['url'] = $actionlink->url;
                // }
                $all_checks[] = $type_check;
            }
        }
    }
    $json['checks'] = $all_checks;
}

# export as json
echo json_encode($json);
?>
