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
			"dtimg" => "qcdt.img",
			"tail" => "tail.img"
	);
	
	public $errormessage;
	
	public function __construct($sinfile, $target = false) {
		
		if (!file_exists( $sinfile )) {
			throw new Exception ( 'File "' . $sinfile . '" does not exist' );
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
	
	public function unpack() {
		
		clearstatcache();
		$file = fopen($this->path . "/" . $this->filename, "rb");
		
		// SIN and ELF magic
		fseek($file, 0, SEEK_SET);
		$sinversion = bin2hex(fread($file, 1));
		$magic = $this->hexToStr(bin2hex(fread($file, 3)));
		
		if (strpos($magic, "SIN") !== false) {
			
			fclose($file);
			
			if ( ($offset = $this->decryptSinFile()) !== false ) {
				
				$this->unpackELFBoot( $offset, false );
				
			} else {
				
				$this->echoMsg("Decrypting the SIN file failed!", true);
				
			}
			
		} elseif (strpos($sinversion, "02") !== false && strpos($magic, "SIN") === false) {
			
			fclose($file);
			
			if ( ($offset = $this->decryptSinFile( false )) !== false ) {
				
				$this->unpackELFBoot( $offset, false );
				
			} else {
				
				$this->echoMsg("Decrypting the SIN file failed!", true);
				
			}
			
		} elseif (strpos($magic, "ELF") !== false) {
			
			fclose($file);
			
			$this->unpackELFBoot();
			
		} else {
			
			// ANDROID magic
			fseek($file, 0, SEEK_SET);
			$magic = $this->hexToStr(bin2hex(fread($file, 8)));
			
			if ($magic == "ANDROID!") {
				
				fclose($file);
					
				$this->unpackAndroidBoot();

			} else {
				
				$this->echoMsg("Using fallback method, not sure what kind of file this is...");
				
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
			passthru("/bin/gzip -vt " . $testtarget, $status);
			if ($status == "0" || $status == "2") {
				return "gz";
			}
		}
		$testtarget = $this->target_path . "/" . $this->name . "." . $this->fileextensions["gzipb"];
		if (file_exists($testtarget)) {
			passthru("/bin/gzip -vt " . $testtarget, $status);
			if ($status == "0" || $status == "2") {
				return "gzip";
			}
		}
		$testtarget = $this->target_path . "/" . $this->name . "." . $this->fileextensions["bzip2"];
		if (file_exists($testtarget)) {
			passthru("/bin/bzip2 -vt " . $testtarget, $status);
			if ($status == "0") {
				return "bzip2";
			}
		}
		$testtarget = $this->target_path . "/" . $this->name . "." . $this->fileextensions["xz"];
		if (file_exists($testtarget)) {
			passthru("/usr/bin/xz -vt " . $testtarget, $status);
			if ($status == "0") {
				return "xz";
			}
		}
		$testtarget = $this->target_path . "/" . $this->name . "." . $this->fileextensions["lzma"];
		if (file_exists($testtarget)) {
			passthru("/usr/bin/lzma -vt " . $testtarget, $status);
			if ($status == "0") {
				return "lzma";
			}
		}
		
		$this->errormessage = "Ramdisk doesn't look right...";
		return false;
		
	}
	
	private function decryptSinFile( $version3 = true ) {
		
		if ($version3) {
			$this->echoMsg("SIN v3 file, decrypting now...");
		} else {
			$this->echoMsg("SIN v2 file, decrypting now...");
		}
		$infile = fopen($this->path . "/" . $this->filename, "rb");
		
		fseek($infile, ($version3)?(4):(2), SEEK_SET);
		$sinsize_raw = unpack("N", fread($infile, 4));
		$sinsize = $sinsize_raw[1];
		
		if ($version3) {
			
			// MMCF magic
			fseek($infile, $sinsize, SEEK_SET);
			$magic = $this->hexToStr(bin2hex(fread($infile, 4)));
			
			// MMCF Size
			fseek($infile, ($sinsize+4), SEEK_SET);
			$mmcf_raw = unpack("N", fread($infile, 4));
			$mmcf = $mmcf_raw[1];
			
			// GPTP magic
			fseek($infile, $sinsize+8, SEEK_SET);
			$magic = $this->hexToStr(bin2hex(fread($infile, 4)));
			
			// GPTP Size
			fseek($infile, $sinsize+12, SEEK_SET);
			$gptp_raw = unpack("N", fread($infile, 4));
			$gptp = $gptp_raw[1];
			
			$elfoffset = ($sinsize+$mmcf+$gptp-16);
			
		} else {
			
			$elfoffset = ($sinsize+16);
			
		}
		
		// SIN and ELF magic
		fseek($infile, ($elfoffset+1), SEEK_SET);
		$magic = $this->hexToStr(bin2hex(fread($infile, 3)));
		
		fclose($infile);
		
		if ($magic == "ELF") {
			return $elfoffset;
		}
		return false;
		
	}
	
	private function unpackELFBoot( $sinoffset = 0, $saveELF = false ) {
		
		if ($sinoffset == "0") {
			$this->echoMsg("ELF header found, extracting parts...");
		} else {
			$this->echoMsg("Extracting ELF parts from SIN kernel image...");
		}
		$infile = fopen($this->path . "/" . $this->filename, "rb");
		
		// Point to the start of the ELF binary
		fseek($infile, $sinoffset, SEEK_SET);
		
		if ($saveELF) {
			$outfile = fopen($this->target_path . "/" . $this->name . ".ELF", "wb");
			fwrite($outfile, fread($infile, (filesize($this->path . "/" . $this->filename)-$sinoffset)));
			fclose($outfile);
			
			// Point to the start of the ELF binary (again, to start unpacking)
			fseek($infile, $sinoffset, SEEK_SET);
		}
		
		$elfHeader = new stdClass();
		
		// e_ident
		$identp1 = fread($infile, 4);
		$identp2 = fread($infile, 1);
		$data = unpack("c", $identp2);
		$bits = $data["1"];
		$identp3 = fread($infile, 11);
		$elfHeader->e_ident = $identp1 . $identp2 . $identp3;
		// e_type
		$elfHeader->e_type = base_convert(bin2hex(fread($infile, 2)), 16, 10);
		// e_machine
		$elfHeader->e_machine = base_convert(bin2hex(fread($infile, 2)), 16, 10);
		// e_version
		$elfHeader->e_version = bin2hex(fread($infile, 4));
		if ($bits == "1") {
			$this->echoMsg( "32bit ELF detected." );
			// e_entry
			$elfHeader->e_entry = bin2hex(fread($infile, 4));
			// e_phoff
			$data = unpack("I", fread($infile, 4));
			$elfHeader->e_phoff = $data[1];
			// e_shoff
			$data = unpack("I", fread($infile, 4));
			$elfHeader->e_shoff = $data[1];
		} elseif($bits == "2") {
			$this->echoMsg( "64bit ELF detected." );
			// e_entry
			$elfHeader->e_entry = bin2hex(fread($infile, 8));
			// e_phoff
			$data = unpack("I", fread($infile, 8));
			$elfHeader->e_phoff = $data[1];
			// e_shoff
			$data = unpack("I", fread($infile, 8));
			$elfHeader->e_shoff = $data[1];
		} else {
			$this->echoMsg( "Something is wrong with the ELF header", true );
		}
		// e_flags
		$data = unpack("I", fread($infile, 4));
		$elfHeader->e_flags = $data[1];
		// e_ehsize
		$data = unpack("c", fread($infile, 2));
		$elfHeader->e_ehsize = $data[1];
		// e_phentsize
		$data = unpack("c", fread($infile, 2));
		$elfHeader->e_phentsize = $data[1];
		// e_phnum
		$data = unpack("c", fread($infile, 2));
		$elfHeader->e_phnum = $data[1];
		// e_shentsize
		$data = unpack("c", fread($infile, 2));
		$elfHeader->e_shentsize = $data[1];
		// e_shnum
		$data = unpack("c", fread($infile, 2));
		$elfHeader->e_shnum = $data[1];
		// e_shstrndx
		$data = unpack("c", fread($infile, 2));
		$elfHeader->e_shstrndx = $data[1];
		
		$PT = array(
			"PT_LOAD" => "1",
			"PT_NOTE" => "4"
		);
		$elfProgramHeaders = array();
		
		for ($i = 0; $i < $elfHeader->e_phnum; $i++) {
			
			if ($bits == "1") {
				
				// p_type
				$data = unpack("I", fread($infile, 4));
				$p_type = $data[1];
				
				$elfProgramHeader = new stdClass();
				
				$elfProgramHeader->p_type = $p_type;
				
				// p_offset
				$data = unpack("I", fread($infile, 4));
				$elfProgramHeader->p_offset = $data["1"];
				
				// p_vaddr
				$elfProgramHeader->p_vaddr = bin2hex(fread($infile, 4));
				
				// p_paddr
				$elfProgramHeader->p_paddr = bin2hex(fread($infile, 4));
				
				// p_filesz
				$data = unpack("I", fread($infile, 4));
				$elfProgramHeader->p_filesz = $data[1];
				
				// p_memsz
				$data = unpack("I", fread($infile, 4));
				$elfProgramHeader->p_memsz = $data[1];
				
				// p_flags
				$elfProgramHeader->p_flags = bin2hex(fread($infile, 4));
				
				// p_align
				$data = unpack("I", fread($infile, 4));
				$elfProgramHeader->p_align = $data[1];
				
				fseek($infile, ($elfHeader->e_phentsize-32), SEEK_CUR);
				
			} else {
			
				// p_type
				$data = unpack("I", fread($infile, 4));
				$p_type = $data[1];
				
				$elfProgramHeader = new stdClass();
				
				$elfProgramHeader->p_type = $p_type;
				
				// p_flags
				$elfProgramHeader->p_flags = bin2hex(fread($infile, 4));
				
				// p_offset
				$data = unpack("I", fread($infile, 8));
				$elfProgramHeader->p_offset = $data["1"];
				
				// p_vaddr
				$elfProgramHeader->p_vaddr = bin2hex(fread($infile, 8));
				
				// p_paddr
				$elfProgramHeader->p_paddr = bin2hex(fread($infile, 8));
				
				// p_filesz
				$data = unpack("I", fread($infile, 8));
				
				$elfProgramHeader->p_filesz = $data[1];
				
				// p_memsz
				$data = unpack("I", fread($infile, 8));
				$elfProgramHeader->p_memsz = $data[1];
				
				// p_align
				$data = unpack("I", fread($infile, 8));
				$elfProgramHeader->p_align = $data[1];
				
			}
			
			if (array_search($p_type, $PT) === false) {
			
				unset($elfProgramHeader);
				continue;
			
			} else {
				
				$elfProgramHeaders[] = $elfProgramHeader;
				unset($elfProgramHeader);
				
			}
			
		}
		
		$filetypes = array(
				'1F8B' => ".ramdisk.cpio.gz",
				'1F9E' => ".ramdisk.cpio.gz",
				'425A' => ".ramdisk.cpio.bzip2",
				'FD37' => ".ramdisk.cpio.xz",
				'5D00' => ".ramdisk.cpio.lzma",
				'0000A0E1' => ".zImage",
				'41524D64' => ".zImage",
				'53315F52504D' => ".rpm.img",
				'QCDT' => ".qcdt.img");
		
		$messages = array(
				'1F8B' => "Saving ramdisk to ",
				'1F9E' => "Saving ramdisk to ",
				'425A' => "Saving ramdisk to ",
				'FD37' => "Saving ramdisk to ",
				'5D00' => "Saving ramdisk to ",
				'0000A0E1' => "Saving kernel to ",
				'41524D64' => "Saving kernel to ",
				'53315F52504D' => "Saving RPM to ",
				'QCDT' => "Saving QCDT to ");
		
		foreach ($elfProgramHeaders as $program) {
			
			$offset = ($sinoffset+$program->p_offset);
			
			fseek($infile, $offset, SEEK_SET);
			
			if ($program->p_type == "4") {
				if ($program->p_filesz < 200) {
					$outfile = fopen($this->target_path . "/" . $this->name . ".tmp", "wb");
					fwrite($outfile, fread($infile, $program->p_filesz));
					fclose($outfile);
					
					$this->echoMsg("Saving kernel commandline to " . $this->name . ".boot.cmd");
					rename($this->target_path . "/" . $this->name . ".tmp", $this->target_path . "/" . $this->name . ".boot.cmd");
				}
				continue;
			}
			
			$outfile = fopen($this->target_path . "/" . $this->name . ".tmp", "wb");
			fwrite($outfile, fread($infile, $program->p_filesz));
			fclose($outfile);
			
			$outfile = fopen($this->target_path . "/" . $this->name . ".tmp", "rb");
			
			foreach ($filetypes as $hexstring => $filetype) {
				
				fseek($outfile, 0, SEEK_SET);
				$head = bin2hex(fread($outfile, 352));
				if (stripos($head, $hexstring) !== false || stripos($this->hexToStr($head), $hexstring) !== false) {
					$this->echoMsg($messages[$hexstring] . $this->name . $filetype);
					rename($this->target_path . "/" . $this->name . ".tmp", $this->target_path . "/" . $this->name . $filetype);
					fclose($outfile);
					break;
				}
				
			}
			
		}
		
		if (is_resource($outfile)) {
			fclose($outfile);
		}
		
		fclose($infile);
		
		if (!file_exists($this->target_path . "/" . $this->name . ".boot.cmd")) {
			$this->getBootCMD( true );
		}
		
	}
	
	private function unpackAndroidBoot() {
		
		$this->echoMsg("Android Boot Image, extracting parts now...");
		
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
		$this->echoMsg("Page size: " . $page_size . "");
		// Kernel
		fseek($infile, 12, SEEK_SET);
		$kaddr_raw = unpack("I", fread($infile, 4));
		$kaddr = sprintf("0x%08X", $kaddr_raw[1]);
		$this->echoMsg("Kernel address (" . $kaddr_raw[1] . "): " . $kaddr . "");
		// First Ramdisk
		fseek($infile, 20, SEEK_SET);
		$raddr_raw = unpack("I", fread($infile, 4));
		$raddr = sprintf("0x%08X", $raddr_raw[1]);
		$this->echoMsg("Ramdisk address (" . $raddr_raw[1] . "): " . $raddr . "");
		// Checking the second ramdisk size first, this changes some things.
		fseek($infile, 24, SEEK_SET);
		$srsize = unpack("I", fread($infile, 4));
		$secondramdisksize = $srsize[1];
		if ($secondramdisksize != 0) {
			fseek($infile, 28, SEEK_SET);
			$sraddr_raw = unpack("I", fread($infile, 4));
			$sraddr = sprintf("0x%08X", $sraddr_raw[1]);
			$this->echoMsg("Second ramdisk address (" . $sraddr_raw[1] . "): " . $sraddr . "");
		}
		// Determining the QCDT size and extracting it (if it exists).
		fseek($infile, 40, SEEK_SET);
		$qcdr = unpack("I", fread($infile, 4));
		$qcdtsize = $qcdr[1];
		if ($qcdtsize != 0) {
			fseek($infile, 44, SEEK_SET);
			$qcdtaddr_raw = unpack("I", fread($infile, 4));
			$qcdtaddr = sprintf("0x%08X", $qcdtaddr_raw[1]);
			$this->echoMsg("QCDT address (" . $qcdtaddr_raw[1] . "): " . $qcdtaddr . "");

			fseek($infile, 32, SEEK_SET);
			$tagsaddr_raw = unpack("I", fread($infile, 4));
			$tagsaddr = sprintf("0x%08X", $tagsaddr_raw[1]);
			$this->echoMsg("Tags address (" . $tagsaddr_raw[1] . "): " . $tagsaddr . "");
		}
		
		// Kernel commandline
		fseek($infile, 64, SEEK_SET);
		$bootcmd = $this->hexToStr(rtrim(bin2hex(fread($infile, 512)), "00"));
		$this->echoMsg("Saving kernel commandline to " . $this->name . ".boot.cmd");
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
		
		$this->echoMsg("Saving kernel to " . $this->name . ".zImage (" . round(($kernelsize/1024)/1024, 2) . "MiB)");
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
		$this->echoMsg("Saving ramdisk to " . $this->name . ".ramdisk.cpio." . $compressed[$magic] . " (" . round(($ramdisksize/1024)/1024, 2) . "MiB)");
		$outfile = fopen($this->target_path . "/" . $this->name . ".ramdisk.cpio." . $compressed[$magic], "wb");
		fwrite($outfile, fread($infile, $ramdisksize));
		fclose($outfile);
		
		// Extracting the second ramdisk (if it exists)
		if ($secondramdisksize != 0) {
			$secondramdiskstart = (((floor($kernelsize / $page_size)+1)*$page_size)+$page_size) + (((floor($ramdisksize / $page_size)+1)*$page_size));
			fseek($infile, $secondramdiskstart, SEEK_SET);
			
			$magic = strtoupper(bin2hex(fread($infile, 2)));
			
			fseek($infile, $secondramdiskstart, SEEK_SET);
			$this->echoMsg("Saving second ramdisk to " . $this->name . ".secondramdisk.cpio." . $compressed[$magic] . " (" . round(($secondramdisksize/1024)/1024, 2) . "MiB)");
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
			
			$this->echoMsg("Saving QCDT to " . $this->name . ".qcdt.img (" . round(($qcdtsize/1024)/1024, 2) . "MiB)");
			$outfile = fopen($this->target_path . "/" . $this->name . ".qcdt.img", "wb");
			fwrite($outfile, fread($infile, $qcdtsize));
			fclose($outfile);
		}
		
		fclose($infile);
		
	}
	
	/*
	 * The settings required by the fallback method.
	 */
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
	private $bootcmd = array('start' => 'E001616E64726F6964626F6F74', 'end' => '00000000000000000000000000000000000000000000000000');
	private $bootcmd_offset = '4';
	
	/*
	 * Fallback parts extraction method...
	 */
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
	
	private function getBootCMD( $readsource = false ) {
	
		if ($readsource) {
			clearstatcache();
			$file = fopen($this->path . "/" . $this->filename, "rb");
			fseek($file, 0, SEEK_SET);
			$this->file_contents = $contents = bin2hex(fread($file, filesize($this->path . "/" . $this->filename)));
			$this->filesize = filesize($this->path . "/" . $this->filename);
			fclose($file);
		}
		
		$start = $this->findHex($this->bootcmd["start"]);
		$length = (($this->findHex($this->bootcmd["end"], $start) - $start) + $this->bootcmd_offset);
		
		$part = substr ( $this->file_contents , $start+4, $length);
		$this->bootcmd_str = trim($this->hexToStr($part));
		
		if ($this->bootcmd_str != "") {
			$file = fopen($this->target_path . "/" . $this->name . ".boot.cmd", "wb");
			fwrite($file, $this->bootcmd_str);
			fclose($file);
			$this->echoMsg("Saving kernel commandline to " . $this->name . ".boot.cmd");
		} else {
			$part = substr ( $this->file_contents , $start, $this->filesize);
			$this->bootcmd_str = trim($this->hexToStr($part));
			$file = fopen($this->target_path . "/" . $this->name . ".boot.cmd", "wb");
			fwrite($file, $this->bootcmd_str);
			fclose($file);
			$this->echoMsg("Saving kernel commandline to " . $this->name . ".boot.cmd");
		}
		
	}
	
	private function dumpPart($start = false, $length = false, $what = 'garbage') {
		
		if (is_null($start) || is_null($length) || $start === false || $length === false) {
			throw new Exception ( 'Not enough parameters supplied to dump a filepart, exiting.' );
		}
		
		$this->echoMsg("Saving " . $this->name . "." . $this->fileextensions[$what] . "");
		
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
			$this->errormessage = "Unable to determine the type, are you sure this is a boot image?";
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
	
	public function echoMsg( $msg = "", $exit = false ) {
		
		echo $msg;
		echo str_pad("",6144," ");
		echo "<br>";
		
		if ($exit) {
			die();
		}
		
	}
	
}

?>
