#!/usr/bin/php
<?php

/*
 * ##########################################################
 * 
 *  XZDualRecovery kernel boot image splitter
 * 
 *  Author: [NUT] from XDA
 *  
 */

class unpackBoot {
	private $filename = null;
	private $path = null;
	private $extension = null;
	private $name = null;
	private $filesize = null;
	private $file_contents = null;
	private $target_path = '.';
	
	private $boot_type = null;
	private $header_start = null;
	private $zImage_start = null;
	private $gzip_start = null;
	private $dtimg_start = null;
	private $tail_start = null;
	private $bootcmd_str = null;
	private $parts = array();
	
	private $sin = '0353494E';
	private $elf = '7F454C46';
	private $android = '414E44524F494421';
	private $zImage = '000000000000A0E10000A0E10000A0E10000A0E10000A0E10000A0E10000A0E10000A0E1020000EA18286F';
	private $zImage_offset = '8';
	private $gzip = '000000001F8B';
	private $gzip_offset = '8';
	private $dtimg = '0051434454';
	private $dtimg_offset = '2';
	private $tail = '00000000010000000000E001616E64726F696462';
	private $tail_offset = '8';
	private $bootcmd = array('start' => '616E64726F6964626F6F74', 'end' => '00000000000000000000000000000000000000000000000000');
	private $bootcmd_offset = '4';
	private $fileextensions = array(
			"SIN" => "header.img",
			"ANDROID" => "header.img",
			"ELF" => "header.img",
			"zImage" => "zImage",
			"ramdisk" => "ramdisk.cpio.gz",
			"dtimg" => "dt.img",
			"tail" => "tail.img"
	);
	
	public function __construct($argv) {
		
		if (!is_array($argv) && ! file_exists ( $argv[1] )) {
			throw new Exception ( 'File "' . $argv[1] . '" does not exists' );
		}
		if (isset($argv[2])) {
			$this->target_path = rtrim($argv[2], "/");
		}
		$pathinfo = pathinfo($argv[1]);
		$this->path = $pathinfo['dirname'];
		$this->extension = $pathinfo['extension'];
		$this->name = $pathinfo['filename'];
		$this->filename = $pathinfo['basename'];
		
		clearstatcache();
		$file = fopen($this->path . "/" . $this->filename, "rb");
		$contents = fread($file, filesize($this->path . "/" . $this->filename));
		fclose($file);
		
		$this->file_contents = bin2hex($contents);
		$this->filesize = strlen($this->file_contents);
		
		$this->splitBootIMG();
		$this->getBootCMD();
	}
	
	private function splitBootIMG() {
		
		$this->findParts();
		
		end($this->parts);
		$last = key($this->parts);
		for ($i = 0; $i < count($this->parts); $i++) {
			
			if (@is_array($this->parts[($i+1)]) && $i != $last) {
				$this->parts[$i]["length"] = ($this->parts[($i+1)]["location"] - $this->parts[$i]["location"]);
			} elseif (!@is_array($this->parts[($i+1)]) && $i == $last) {
				$this->parts[$i]["length"] = (strlen($this->file_contents) - $this->parts[$i]["location"]);
			}
			
			$this->dumpPart($this->parts[$i]["location"], $this->parts[$i]["length"], $this->parts[$i]["type"]);
			
		}
		
	}
	
	private function getBootCMD() {
	
		$start = $this->findHex($this->bootcmd["start"]);
		$length = (($this->findHex($this->bootcmd["end"], $start) - $start) + $this->bootcmd_offset);
		
		$part = substr ( $this->file_contents , $start, $length);
		$this->bootcmd_str = trim($this->hexToStr($part));
		
		if ($this->bootcmd_str != "") {
			$file = fopen($this->target_path . "/" . $this->name . ".boot.cmd", "wb");
			fwrite($file, $this->bootcmd_str);
			fclose($file);
			echo "Writing " . $this->target_path . "/" . $this->name . ".boot.cmd\n";
		} else {
			$part = substr ( $this->file_contents , $start, $this->filesize);
			$this->bootcmd_str = trim($this->hexToStr($part));
			$file = fopen($this->target_path . "/" . $this->name . ".boot.cmd", "wb");
			fwrite($file, $this->bootcmd_str);
			fclose($file);
			echo "Writing " . $this->target_path . "/" . $this->name . ".boot.cmd\n";
		}
		
	}
	
	private function dumpPart($start = false, $length = false, $what = 'garbage') {
		
		if (is_null($start) || is_null($length) || $start === false || $length === false) {
			throw new Exception ( 'Not enough parameters supplied to dump a filepart, exiting.' );
		}
		
		echo "Writing " . $this->target_path . "/" . $this->name . "." . $this->fileextensions[$what] . "\n";
		
		$part = trim(substr ( $this->file_contents , $start, $length));
		
		$file = fopen($this->target_path . "/" . $this->name . "." . $this->fileextensions[$what], "wb");
		fwrite($file, hex2bin($part));
		fclose($file);
		
	}
	
	private function findParts() {
		
		$position = $this->findHex($this->sin);
		$type = "SIN";
		if (is_null($position)) {
			$position = $this->findHex($this->android);
			$type = "ANDROID";
			if (is_null($position)) {
				$position = $this->findHex($this->elf);
				$type = "ELF";
			}
		}
		if (is_null($position)) {
			throw new Exception ( 'Unable to determine the type, are you sure this is a boot image or kernel.sin?' );
		} else {
			$this->header_start = $position;
			$this->boot_type = $type;
		}
		
		$this->zImage_start = $this->findHex($this->zImage);
		$this->gzip_start = $this->findHex($this->gzip);
		$this->dtimg_start = $this->findHex($this->dtimg);
		$this->tail_start = $this->findHex($this->tail);
		
		$each[$this->boot_type] = $this->header_start;
		if (!is_null($this->zImage_start)) {
			$each["zImage"] = ($this->zImage_start + $this->zImage_offset);
		}
		if (!is_null($this->gzip_start)) {
			$each["ramdisk"] = ($this->gzip_start + $this->gzip_offset);
		}
		if (!is_null($this->dtimg_start)) {
			$each["dtimg"] = ($this->dtimg_start + $this->dtimg_offset);
		}
		if (!is_null($this->tail_start)) {
			$each["tail"] = ($this->tail_start + $this->tail_offset);
		}
		
		asort($each, SORT_NUMERIC);
		
		if (count($each) < 2) {
			throw new Exception ( 'Malformed boot partition, exitting.' );
		}
		
		foreach ($each as $name => $position) {
			
			$this->parts[] = array("type" => $name, "location" => $position);
			
		}
		
	}
	
	private function findHex($hexString = false, $offset = 0) {
		
		if ($hexString == "" || $hexString === false) {
			throw new Exception ( 'Empty or invalid Hex value!' );
		}
	
		$hexStringLength = strlen ( $hexString );
		$contents = $this->file_contents;
		
		$result = stripos($contents, $hexString, $offset);
		
		if ($result === false) {
			return null;
		} else {
			return $result;
		}
		
	}
	
	private function strToHex($string) {
		$hex = '';
		for($i = 0; $i < strlen ( $string ); $i++) {
			$ord = ord ( $string[$i] );
			$hexCode = dechex ( $ord );
			$hex .= substr ( '0' . $hexCode, - 2 );
		}
		return strToUpper ( $hex );
	}
	
	private function hexToStr($hex){
		$string='';
		for ($i=0; $i < strlen($hex)-1; $i+=2){
			$string .= chr(hexdec($hex[$i].$hex[$i+1]));
		}
		return $string;
	}
	
}

$finder = new unpackBoot ( $argv );
?>
