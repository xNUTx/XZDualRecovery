#!/usr/bin/php
<?php

/*
 * ##########################################################
 * 
 *  XZDualRecovery kernel boot image splitter
 * 
 *  This helper file is to convert the class into a CLI tool
 *  
 *  Author: [NUT] from XDA
 *  
 */

include_once("unpackboot.php");

class unpackBootImage extends unpackBoot {
	
	public function __construct($argv, $blub = false) {
		
		if (!is_array($argv) && ! file_exists ( $argv[1] )) {
			throw new Exception ( 'File "' . $argv[1] . '" does not exist' );
		}
		if (isset($argv[2])) {
			$this->target_path = rtrim($argv[2], "/");
		}
		
		$pathinfo = pathinfo($argv[1]);
		$this->path = $pathinfo['dirname'];
		$this->extension = $pathinfo['extension'];
		$this->name = $pathinfo['filename'];
		$this->filename = $pathinfo['basename'];
		
		$this->unpack();
		
	}
	
	public function echoMsg( $msg = "", $exit = false ) {
	
		echo $msg . "\n";

		if ($exit) {
			die();
		}
		
	}
}

$finder = new unpackBootImage ( $argv );
?>
