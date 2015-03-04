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
	public $filename = null;
	public $path = null;
	public $extension = null;
	public $name = null;
	public $filesize = null;
	public $file_contents = null;
	public $target_path = '.';
	
	public $boot_type = null;
	public $header_start = null;
	public $zImage_start = null;
	public $gzipa_start = null;
	public $gzipb_start = null;
	public $bzip2_start = null;
	public $xz_start = null;
	public $lzma_start = null;
	public $dtimg_start = null;
	public $tail_start = null;
	public $bootcmd_str = null;
	public $parts = array();
	
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
	public $errormessage;
	
	public function __construct($sinfile, $target = false) {
		
		if (!file_exists( $sinfile )) {
			throw new Exception ( 'File "' . $sinfile . '" does not exists' );
		}
		if ($target !== false) {
			$this->target_path = rtrim($target, "/");
		}
		
		$pathinfo = pathinfo($sinfile);
		$this->path = $pathinfo['dirname'];
		$this->extension = $pathinfo['extension'];
		$this->name = $pathinfo['filename'];
		$this->filename = $pathinfo['basename'];
		
	}
	
	private function decryptSinFile() {
		
		echo "SIN v3 file found, decrypting now...\n";
		$infile = fopen($this->path . "/" . $this->filename, "rb");
		
		fseek($infile, 4, SEEK_SET);
		$sinsize_raw = unpack("N", fread($infile, 4));
		$sinsize = $sinsize_raw[1];
		
		echo "Header Size: " . $sinsize . "\n";
		
		$elfoffset = ($sinsize+209);
		
		// SIN and ELF magic
		fseek($infile, $elfoffset, SEEK_SET);
		$magic = $this->hexToStr(bin2hex(fread($infile, 3)));
		
		echo $magic . "\n";
		
		fclose($infile);
		
		//if ($magic == "ELF") {
		//	return $elfoffset;
		//}
		return false;
		
	}
	
	private function unpackELFBoot( $sinoffset = 0 ) {
		
		if ($sinoffset == "0") {
			echo "ELF header found, extracting parts...\n";
		} else {
			echo "Extracting ELF parts from SIN kernel image...\n";
		}
		$infile = fopen($this->path . "/" . $this->filename, "rb");
		
		// Find offset (e_phoff)
		fseek($infile, ($sinoffset+28), SEEK_SET);
		$offset_raw = unpack("I", fread($infile, 4));
		$offset = $offset_raw[1];
		
		echo $offset . "\n";
		
		// Find part size (e_phentsize)
		fseek($infile, ($sinoffset+42), SEEK_SET);
		$partsize_raw = bin2hex(fread($infile, 2));
		$partsize = base_convert($partsize_raw, 16, 10);
		
		echo $partsize . "\n";
		
		// Find number of parts (e_phnum)
		fseek($infile, ($sinoffset+44), SEEK_SET);
		$parts_raw = bin2hex(fread($infile, 2));
		$parts = base_convert($parts_raw, 16, 10);
		
		echo $parts . "\n";
		
		for ($i = 0; $i < $parts; $i++) {
			fseek($infile, ($sinoffset+$offset), SEEK_SET);
			//fread($infile, 352);
			
/*
  			fin.seek(offset);
			fin.read(programHeaderData, 0, this.e_phentsize);
			this.phEntries[i] = new ElfProgram(this, programHeaderData,i+1);
			fin.seek(phEntries[i].getOffset());
			byte[] ident = new byte[phEntries[i].getProgramSize()<352?(int)phEntries[i].getProgramSize():352];
			fin.read(ident);
			String identHex = HexDump.toHex(ident);
			if (identHex.contains("[1F, 8B"))
				this.phEntries[i].setContentType("ramdisk.gz");
			else if (identHex.contains("[00, 00, A0, E1"))
				this.phEntries[i].setContentType("Image");
			else if (identHex.contains("53, 31, 5F, 52, 50, 4D"))
				this.phEntries[i].setContentType("rpm.bin");
			else if (new String(ident).contains("S1_Root") || new String(ident).contains("S1_SW_Root"))
				this.phEntries[i].setContentType("cert");
			else if (ident.length<200) this.phEntries[i].setContentType("bootcmd");
			else this.phEntries[i].setContentType("");
			offset += this.e_phentsize;
*/
			$offset = ($offset+$partsize);
		}
		
	}
	
	public function unpack() {
		
		echo "Checking " . $this->path . "/" . $this->filename . " image type...\n";
		
		clearstatcache();
		$file = fopen($this->path . "/" . $this->filename, "rb");
		
		// SIN and ELF magic
		fseek($file, 1, SEEK_SET);
		$magic = $this->hexToStr(bin2hex(fread($file, 3)));
		
		if (strpos($magic, "SIN") !== false) {
			
			fclose($file);
			
			if ( ($offset = $this->decryptSinFile()) !== false ) {
				
				$this->unpackELFBoot( $offset );
				
			}
			
		} elseif (strpos($magic, "ELF") !== false) {
			
			fclose($file);
			
			$this->unpackELFBoot();
			
		} else {
			
			echo "NO SIN/ELF...\n";
			
			// ANDROID magic
			fseek($file, 0, SEEK_SET);
			$magic = $this->hexToStr(bin2hex(fread($file, 8)));
			
			if ($magic == "ANDROID!") {
				
				echo "ANDROID!...\n";
				
				fclose($file);
					
				$this->unpackAndroidBoot();
					
			} else {
				
				echo "WTF?...\n";
				
				die("EXIT!\n");
				
				# Fallback to the old (insecure) method
				fseek($file, 0, SEEK_SET);
				$contents = fread($file, filesize($this->path . "/" . $this->filename));
				fclose($file);
					
				$this->file_contents = bin2hex($contents);
				$this->filesize = strlen($this->file_contents);
			
				if (!$this->splitBootIMG()) {
					return false;
				}
			
				$this->getBootCMD();
					
			}
		
		}
		
		$testtarget = $this->target_path . "/" . $this->name . "." . $this->fileextensions["gzipa"];
		if (file_exists($testtarget)) {
			passthru("/bin/gzip -t " . $testtarget, $status);
			if ($status == "0" || $status == "2") {
				return "gz";
			}
		}
		$testtarget = $this->target_path . "/" . $this->name . "." . $this->fileextensions["gzipb"];
		if (file_exists($testtarget)) {
			passthru("/bin/gzip -t " . $testtarget, $status);
			if ($status == "0" || $status == "2") {
				return "gzip";
			}
		}
		$testtarget = $this->target_path . "/" . $this->name . "." . $this->fileextensions["bzip2"];
		if (file_exists($testtarget)) {
			passthru("/bin/bzip2 -t " . $testtarget, $status);
			if ($status == "0") {
				return "bzip2";
			}
		}
		$testtarget = $this->target_path . "/" . $this->name . "." . $this->fileextensions["xz"];
		if (file_exists($testtarget)) {
			passthru("/usr/bin/xz -t " . $testtarget, $status);
			if ($status == "0") {
				return "xz";
			}
		}
		$testtarget = $this->target_path . "/" . $this->name . "." . $this->fileextensions["lzma"];
		if (file_exists($testtarget)) {
			passthru("/usr/bin/lzma -t " . $testtarget, $status);
			if ($status == "0") {
				return "lzma";
			}
		}
		
		$this->errormessage = "Ramdisk doesn't look right...\n";
		return false;
		
	}
	
	private function splitBootIMG() {
		
		if (!$this->findParts()) {
			return false;
		}
		
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
		
		return true;
		
	}
	
	private function unpackAndroidBoot() {
		
		// Used to determine the ramdisk compression format
		$compressed = array(
				"1F8B" => 'gz',
				"1F9E" => 'gz',
				"425A" => 'bzip2',
				"FD37" => 'xz',
				"5D00" => 'lzma'
		);
		
		$infile = fopen($this->path . "/" . $this->filename, "rb");
		
		// Page Size and RAM storage addresses
		fseek($infile, 36, SEEK_SET);
		$pagesize = unpack("I", fread($infile, 4));
		$page_size = $pagesize[1];
		echo "Page size: " . $page_size . "\n";
		echo "<br>";
		// Kernel
		fseek($infile, 12, SEEK_SET);
		$kaddr_raw = unpack("I", fread($infile, 4));
		$kaddr = sprintf("0x%08X", $kaddr_raw[1]);
		echo "Kernel address (" . $kaddr_raw[1] . "): " . $kaddr . "\n";
		echo "<br>";
		// First Ramdisk
		fseek($infile, 20, SEEK_SET);
		$raddr_raw = unpack("I", fread($infile, 4));
		$raddr = sprintf("0x%08X", $raddr_raw[1]);
		echo "Ramdisk address (" . $raddr_raw[1] . "): " . $raddr . "\n";
		echo "<br>";
		// Checking the second ramdisk size first, this changes some things.
		fseek($infile, 24, SEEK_SET);
		$srsize = unpack("I", fread($infile, 4));
		$secondramdisksize = $srsize[1];
		if ($secondramdisksize != 0) {
			fseek($infile, 28, SEEK_SET);
			$sraddr_raw = unpack("I", fread($infile, 4));
			$sraddr = sprintf("0x%08X", $sraddr_raw[1]);
			echo "Second ramdisk address (" . $sraddr_raw[1] . "): " . $sraddr . "\n";
			echo "<br>";
		}
		// Determining the QCDT size and extracting it (if it exists).
		fseek($infile, 40, SEEK_SET);
		$qcdr = unpack("I", fread($infile, 4));
		$qcdtsize = $qcdr[1];
		if ($qcdtsize != 0) {
			fseek($infile, 44, SEEK_SET);
			$qcdtaddr_raw = unpack("I", fread($infile, 4));
			$qcdtaddr = sprintf("0x%08X", $qcdtaddr_raw[1]);
			echo "QCDT address (" . $qcdtaddr_raw[1] . "): " . $qcdtaddr . "\n";
			echo "<br>";

			fseek($infile, 32, SEEK_SET);
			$tagsaddr_raw = unpack("I", fread($infile, 4));
			$tagsaddr = sprintf("0x%08X", $tagsaddr_raw[1]);
			echo "Tags address (" . $tagsaddr_raw[1] . "): " . $tagsaddr . "\n";
			echo "<br>";
		}
		
		echo str_pad("",6144," ");
		
		// Kernel commandline
		fseek($infile, 64, SEEK_SET);
		$bootcmd = $this->hexToStr(rtrim(bin2hex(fread($infile, 512)), "00"));
		echo "Writing " . $this->target_path . "/" . $this->name . ".boot.cmd\n";
		echo str_pad("",6144," ");
		echo "<br>";
		$outfile = fopen($this->target_path . "/" . $this->name . ".boot.cmd", "wb");
		fwrite($outfile, $bootcmd);
		fclose($outfile);
		
		// Determining the kernel size
		fseek($infile, 8, SEEK_SET);
		$ksize = unpack("I", fread($infile, 4));
		$kernelsize = $ksize[1];
		// Extracting the kernel
		$kernelstart = $page_size;
		fseek($infile, $kernelstart, SEEK_SET);
		
		echo "Writing " . $this->target_path . "/" . $this->name . ".zImage (" . round(($kernelsize/1024)/1024, 2) . "MiB)\n";
		echo str_pad("",6144," ");
		echo "<br>";
		$outfile = fopen($this->target_path . "/" . $this->name . ".zImage", "wb");
		fwrite($outfile, fread($infile, $kernelsize));
		fclose($outfile);
		
		// Determining the ramdisk size
		fseek($infile, 16, SEEK_SET);
		$rsize = unpack("I", fread($infile, 4));
		$ramdisksize = $rsize[1];
		// Extracting the ramdisk
		$ramdiskstart = ((floor($kernelsize / $page_size)+1)*$page_size)+$page_size;
		fseek($infile, $ramdiskstart, SEEK_SET);
		
		$magic = strtoupper(bin2hex(fread($infile, 2)));
		
		fseek($infile, $ramdiskstart, SEEK_SET);
		echo "Writing " . $this->target_path . "/" . $this->name . ".ramdisk.cpio." . $compressed[$magic] . " (" . round(($ramdisksize/1024)/1024, 2) . "MiB)\n";
		echo str_pad("",6144," ");
		echo "<br>";
		$outfile = fopen($this->target_path . "/" . $this->name . ".ramdisk.cpio." . $compressed[$magic], "wb");
		fwrite($outfile, fread($infile, $ramdisksize));
		fclose($outfile);
		
		// Extracting the second ramdisk (if it exists)
		if ($secondramdisksize != 0) {
			$secondramdiskstart = (((floor($kernelsize / $page_size)+1)*$page_size)+$page_size) + (((floor($ramdisksize / $page_size)+1)*$page_size));
			fseek($infile, $secondramdiskstart, SEEK_SET);
			
			$magic = strtoupper(bin2hex(fread($infile, 2)));
			
			fseek($infile, $secondramdiskstart, SEEK_SET);
			echo "Writing " . $this->target_path . "/" . $this->name . ".secondramdisk.cpio." . $compressed[$magic] . " (" . round(($secondramdisksize/1024)/1024, 2) . "MiB)\n";
			echo str_pad("",6144," ");
			echo "<br>";
			$outfile = fopen($this->target_path . "/" . $this->name . ".secondramdisk.cpio" . $compressed[$magic], "wb");
			fwrite($outfile, fread($infile, $secondramdisksize));
			fclose($outfile);
		}
		
		// Extracting the dt
		if ($qcdtsize != 0) {
			if ($secondramdisksize != 0) {
				$qcdtstart = (((floor($kernelsize / $page_size)+1)*$page_size)+$page_size) + (((floor($ramdisksize / $page_size)+1)*$page_size)) + (((floor($secondramdisksize / $page_size)+1)*$page_size));
			} else {
				$qcdtstart = (((floor($kernelsize / $page_size)+1)*$page_size)+$page_size) + (((floor($ramdisksize / $page_size)+1)*$page_size));
			}
			fseek($infile, $qcdtstart, SEEK_SET);
			
			echo "Writing " . $this->target_path . "/" . $this->name . ".dt.img (" . round(($qcdtsize/1024)/1024, 2) . "MiB)\n";
			echo str_pad("",6144," ");
			echo "<br>";
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
			echo str_pad("",6144," ");
			echo "<br>";
		} else {
			$part = substr ( $this->file_contents , $start, $this->filesize);
			$this->bootcmd_str = trim($this->hexToStr($part));
			$file = fopen($this->target_path . "/" . $this->name . ".boot.cmd", "wb");
			fwrite($file, $this->bootcmd_str);
			fclose($file);
			echo "Writing " . $this->target_path . "/" . $this->name . ".boot.cmd\n";
			echo str_pad("",6144," ");
			echo "<br>";
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
			$this->errormessage = "Unable to determine the type, are you sure this is a boot image or kernel.sin?\n";
			return false;
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

		return true;
		
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

?>
