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
	private $gzipa_start = null;
	private $gzipb_start = null;
	private $bzip2_start = null;
	private $xz_start = null;
	private $lzma_start = null;
	private $dtimg_start = null;
	private $tail_start = null;
	private $bootcmd_str = null;
	private $parts = array();
	
	private $sin = '53494E';
	private $elf = '454C46';
	private $android = '414E44524F494421';
	private $zImage = '0000A0E10000A0E10000A0E10000A0E10000A0E10000A0E10000A0E10000A0E1';
	private $zImage_offset = '8';
	private $compressed = array(
			"gzipa" => '000000001F8B',
			"gzipa_offset" => '8',
			"gzipa_ext" => 'gz',
			"gzipb" => '000000001F9E',
			"gzipb_offset" => '8',
			"gzipb_ext" => 'gz',
			"bzip2" => '00000000425A',
			"bzip2_offset" => '8',
			"bzip2_ext" => 'bzip2',
			"xz" => '00000000FD37',
			"xz_offset" => '8',
			"xz_ext" => 'xz',
			"lzma" => '000000005D00',
			"lzma_offset" => '8',
			"lzma_ext" => 'lzma'
	);
	private $dtimg = '51434454';
	private $dtimg_offset = '4';
	private $tail = '00000000010000000000E001616E64726F696462';
	private $tail_offset = '8';
	private $bootcmd = array('start' => '616E64726F6964626F6F74', 'end' => '00000000000000000000000000000000000000000000000000');
	private $bootcmd_offset = '4';
	private $fileextensions = array(
			"SIN" => "header.img",
			"ANDROID" => "header.img",
			"ELF" => "header.img",
			"zImage" => "zImage",
			"gzipa" => "ramdisk.cpio.gz",
			"gzipb" => "ramdisk.cpio.gz",
			"lzma" => "ramdisk.cpio.lzma",
			"bzip2" => "ramdisk.cpio.bzip2",
			"xz" => "ramdisk.cpio.xz",
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
		$magic = $this->hexToStr(bin2hex(fread($file, 8)));
				
		if ($magic == "ANDROID!") {
			
			fclose($file);
			
			$this->unpackAndroidBoot();
			
		} else {
			
			fseek($file, 0, SEEK_SET);
			$contents = fread($file, filesize($this->path . "/" . $this->filename));
			fclose($file);
			
			$this->file_contents = bin2hex($contents);
			$this->filesize = strlen($this->file_contents);
				
			$this->splitBootIMG();
			$this->getBootCMD();
			
		}
		
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
	
	private function unpackAndroidBoot() {
		
		$infile = fopen($this->path . "/" . $this->filename, "rb");
		
		// Page Size
		fseek($infile, 36, SEEK_SET);
		$pagesize = unpack("I", fread($infile, 4));
		$page_size = $pagesize[1];
		echo "Bootimage page size: " . $page_size . "\n";
		
		// Kernel commandline Size
		fseek($infile, 64, SEEK_SET);
		$bootcmd = $this->hexToStr(bin2hex(fread($infile, 512)));
		echo "Writing " . $this->target_path . "/" . $this->name . ".boot.cmd\n";
		
		$outfile = fopen($this->target_path . "/" . $this->name . ".boot.cmd", "w");
		fwrite($outfile, $bootcmd);
		fclose($outfile);
		
		// Finding the kernel
		fseek($infile, 8, SEEK_SET);
		$ksize = unpack("I", fread($infile, 4));
		$kernelsize = $ksize[1];
		fseek($infile, 12, SEEK_SET);
		$kaddr = bin2hex(fread($infile, 4));
		$kernelstart = $page_size;
		// Extracting the kernel
		fseek($infile, $kernelstart, SEEK_SET);
		
		echo "Writing " . $this->target_path . "/" . $this->name . ".zImage\n";
		$outfile = fopen($this->target_path . "/" . $this->name . ".zImage", "wb");
		fwrite($outfile, fread($infile, $kernelsize));
		fclose($outfile);
		
		// Finding the ramdisk
		fseek($infile, 16, SEEK_SET);
		$rsize = unpack("I", fread($infile, 4));
		$ramdisksize = $rsize[1];
		fseek($infile, 20, SEEK_SET);
		$raddr = bin2hex(fread($infile, 4));
		$ramdiskstart = ((floor($kernelsize / $page_size)+1)*$page_size)+$page_size;
		// Extracting the ramdisk
		fseek($infile, $ramdiskstart, SEEK_SET);
		
		$magic = strtoupper(bin2hex(fread($infile, 2)));
		$compressed = array(
				"1F8B" => 'gz',
				"1F9E" => 'gz',
				"425A" => 'bzip2',
				"FD37" => 'xz',
				"5D00" => 'lzma'
		);
		
		fseek($infile, $ramdiskstart, SEEK_SET);
		echo "Writing " . $this->target_path . "/" . $this->name . ".ramdisk.cpio." . $compressed[$magic] . "\n";
		$outfile = fopen($this->target_path . "/" . $this->name . ".ramdisk.cpio." . $compressed[$magic], "wb");
		fwrite($outfile, fread($infile, $ramdisksize));
		fclose($outfile);
		
		// Finding the second ramdisk
		fseek($infile, 24, SEEK_SET);
		$srsize = unpack("I", fread($infile, 4));
		$secondramdisksize = $srsize[1];
		fseek($infile, 28, SEEK_SET);
		$sraddr = bin2hex(fread($infile, 4));
		$secondramdiskstart = (((floor($kernelsize / $page_size)+1)*$page_size)+$page_size) + (((floor($ramdisksize / $page_size)+1)*$page_size));
		// Extracting the second ramdisk
		if ($secondramdisksize != 0) {
			fseek($infile, $secondramdiskstart, SEEK_SET);
			
			$magic = strtoupper(bin2hex(fread($infile, 2)));
			$compressed = array(
				"1F8B" => 'gz',
				"1F9E" => 'gz',
				"425A" => 'bzip2',
				"FD37" => 'xz',
				"5D00" => 'lzma'
			);
			
			fseek($infile, $secondramdiskstart, SEEK_SET);
			echo "Writing " . $this->target_path . "/" . $this->name . ".secondramdisk.cpio." . $compressed[$magic] . "\n";
			$outfile = fopen($this->target_path . "/" . $this->name . ".secondramdisk.cpio" . $compressed[$magic], "wb");
			fwrite($outfile, fread($infile, $secondramdisksize));
			fclose($outfile);
		}
		
		// Finding the QCDT
		fseek($infile, 40, SEEK_SET);
		$qcdr = unpack("I", fread($infile, 4));
		$qcdtsize = $qcdr[1];
		fseek($infile, 44, SEEK_SET);
		$qcdraddr = bin2hex(fread($infile, 4));
		if ($secondramdisksize != 0) {
			$qcdtstart = (((floor($kernelsize / $page_size)+1)*$page_size)+$page_size) + (((floor($ramdisksize / $page_size)+1)*$page_size)) + (((floor($secondramdisksize / $page_size)+1)*$page_size));
		} else {
			$qcdtstart = (((floor($kernelsize / $page_size)+1)*$page_size)+$page_size) + (((floor($ramdisksize / $page_size)+1)*$page_size));
		}
		// Extracting the dt
		if ($qcdtsize != 0) {
			fseek($infile, $qcdtstart, SEEK_SET);
			
			echo "Writing " . $this->target_path . "/" . $this->name . ".dt.img\n";
			$outfile = fopen($this->target_path . "/" . $this->name . ".dt.img", "wb");
			fwrite($outfile, fread($infile, $qcdtsize));
			fclose($outfile);
		}
		
		fclose($infile);
		
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
		$this->gzipa_start = $this->findHex($this->compressed["gzipa"]);
		$this->gzipb_start = $this->findHex($this->compressed["gzipb"]);
		$this->bzip2_start = $this->findHex($this->compressed["bzip2"]);
		$this->xz_start = $this->findHex($this->compressed["xz"]);
		$this->lzma_start = $this->findHex($this->compressed["lzma"]);
		$this->dtimg_start = $this->findHex($this->dtimg);
		$this->tail_start = $this->findHex($this->tail);
		
		$each[$this->boot_type] = $this->header_start;
		if (!is_null($this->zImage_start)) {
			$each["zImage"] = ($this->zImage_start + $this->zImage_offset);
		}
		if (!is_null($this->gzipa_start)) {
			$each["gzipa"] = ($this->gzipa_start + $this->compressed["gzipa_offset"]);
		}
		if (!is_null($this->gzipb_start)) {
			$each["gzipb"] = ($this->gzipb_start + $this->compressed["gzipb_offset"]);
		}
		if (!is_null($this->bzip2_start)) {
			$each["bzip2"] = ($this->bzip2_start + $this->compressed["bzip2_offset"]);
		}
		if (!is_null($this->xz_start)) {
			$each["xz"] = ($this->xz_start + $this->compressed["xz_offset"]);
		}
		if (!is_null($this->lzma_start)) {
			$each["lzma"] = ($this->lzma_start + $this->compressed["lzma_offset"]);
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
