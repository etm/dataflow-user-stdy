<?php
  $uuid = $_REQUEST['uuid'];
  file_put_contents("save.list", "https://cpee.org/logs/" . $uuid . ".xes.yaml\n", FILE_APPEND | LOCK_EX);
?>
