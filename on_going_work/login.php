<?php
	header('Location: vip.php');
	session_start();
	if (isset($_GET['username'])) {
		$_SESSION['username'] = $_SESSION['password'] = $_GET['username'];
	} else { // Default value
  		$_SESSION['username'] = $_SESSION['password'] = 'jorass';
	}
?>