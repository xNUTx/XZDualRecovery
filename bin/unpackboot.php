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
		
		$this->echoMsg("SIN v3 file found, decrypting now...");
		$infile = fopen($this->path . "/" . $this->filename, "rb");
		
		fseek($infile, 4, SEEK_SET);
		$sinsize_raw = unpack("N", fread($infile, 4));
		$sinsize = $sinsize_raw[1];
		
		$this->echoMsg("SIN Header Size: " . $sinsize);
		
		// MMCF magic
		fseek($infile, $sinsize, SEEK_SET);
		$magic = $this->hexToStr(bin2hex(fread($infile, 4)));
		$this->echoMsg("Found: " . $magic);
		
		// MMCF Size
		fseek($infile, ($sinsize+4), SEEK_SET);
		$mmcf_raw = unpack("N", fread($infile, 4));
		$mmcf = $mmcf_raw[1];
		$this->echoMsg("Size: " . $mmcf);
		
		// GPTP magic
		fseek($infile, $sinsize+8, SEEK_SET);
		$magic = $this->hexToStr(bin2hex(fread($infile, 4)));
		$this->echoMsg("Found: " . $magic);
		
		// GPTP Size
		fseek($infile, $sinsize+12, SEEK_SET);
		$gptp_raw = unpack("N", fread($infile, 4));
		$gptp = $gptp_raw[1];
		$this->echoMsg("Size: " . $gptp);
		
		$elfoffset = ($sinsize+$mmcf+$gptp-16);
		
		$this->echoMsg("Calculated size: " . $elfoffset);
		
		// SIN and ELF magic
		fseek($infile, ($elfoffset+1), SEEK_SET);
		$magic = $this->hexToStr(bin2hex(fread($infile, 3)));
		
		fclose($infile);
		
		if ($magic == "ELF") {
			return $elfoffset;
		}
		return false;
		
	}
	
	private function unpackELFBoot( $sinoffset = 0 ) {
		
		if ($sinoffset == "0") {
			$this->echoMsg("ELF header found, extracting parts...");
		} else {
			$this->echoMsg("Extracting ELF parts from SIN kernel image...");
		}
		$infile = fopen($this->path . "/" . $this->filename, "rb");
		
		// Point to the start of the ELF binary
		fseek($infile, $sinoffset, SEEK_SET);
		
		$elfHeader = new stdClass();
		
		// e_ident
		$elfHeader->e_ident = fread($infile, 16);
		// e_type
		$elfHeader->e_type = bin2hex(fread($infile, 2));
		// e_machine
		$elfHeader->e_machine = bin2hex(fread($infile, 2));
		// e_version
		$elfHeader->e_version = bin2hex(fread($infile, 4));
		// e_entry
		$elfHeader->e_entry = bin2hex(fread($infile, 4));
		// e_phoff
		$data = unpack("I", fread($infile, 4));
		$elfHeader->e_phoff = $data[1];
		// e_shoff
		$data = unpack("I", fread($infile, 4));
		$elfHeader->e_shoff = $data[1];
		// e_flags
		$data = unpack("I", fread($infile, 4));
		$elfHeader->e_flags = $data[1];
		// e_ehsize
		$elfHeader->e_ehsize = base_convert(bin2hex(fread($infile, 2)), 16, 10);
		// e_phentsize
		$elfHeader->e_phentsize = base_convert(bin2hex(fread($infile, 2)), 16, 10);
		// e_phnum
		$elfHeader->e_phnum = base_convert(bin2hex(fread($infile, 2)), 16, 10);
		// e_shentsize
		$elfHeader->e_shentsize = base_convert(bin2hex(fread($infile, 2)), 16, 10);
		// e_shnum
		$elfHeader->e_shnum = base_convert(bin2hex(fread($infile, 2)), 16, 10);
		// e_shstrndx
		$elfHeader->e_shstrndx = base_convert(bin2hex(fread($infile, 2)), 16, 10);
		
		print_r($elfHeader);

		$PT = array(
			"PT_NULL" => "0",
			"PT_LOAD" => "1",
			"PT_NOTE" => "4"
		);
		$elfProgramHeaders = array();

		$offset = ($sinoffset+$elfHeader->e_phoff);
		
		for ($i = 1; $i <= $elfHeader->e_phnum; $i++) {
			
			fseek($infile, $offset, SEEK_SET);
			
			// p_type
			$data = unpack("I", fread($infile, 4));
			$p_type = $data[1];
			
			if (array_search($p_type, $PT) === false) {
				
				fseek($infile, ($offset + $elfHeader->e_phentsize), SEEK_SET);
				continue;
				
			}
			
			$elfProgramHeader = new stdClass();
			
			$elfProgramHeader->p_type = $p_type;
			
			// p_offset
			$data = unpack("I", fread($infile, 4));
			$elfProgramHeader->p_offset = $data[1];
			
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
			
			$elfProgramHeaders[] = $elfProgramHeader;
			unset($elfProgramHeader);
			
			$offset = ($offset + $elfHeader->e_phentsize);
			
		}
		
		print_r($elfProgramHeaders);
		
		/*
		$elfSectionHeaders = array();
		
		$offset = $sinoffset+$elfHeader->e_shoff;
		
		for ($i = 0; $i < $elfHeader->e_shnum; $i++) {
			
			fseek($infile, $offset, SEEK_SET);
		
			$elfSectionHeader = new stdClass();
			
			// sh_name
			$binary = fread($infile, 4);
			$data = @unpack("I", $binary);
			
			if (!is_null($data[1])) {
				
				$elfSectionHeader->sh_name = $data[1];
				
				// sh_type
				$data = @unpack("I", fread($infile, 4));
				$elfSectionHeader->sh_type = $data[1];
				
				if (is_null($elfSectionHeader->sh_type)) {
					unset($elfSectionHeader);
					$offset = $offset+$elfHeader->e_shentsize;
					continue;
				}
				
				// sh_flags
				$data = unpack("I", fread($infile, 4));
				$elfSectionHeader->sh_flags = $data[1];
				
				// sh_addr
				$elfSectionHeader->sh_addr = bin2hex(fread($infile, 4));
				
				// sh_offset
				$data = unpack("I", fread($infile, 4));
				$elfSectionHeader->sh_offset = $data[1];
				
				// sh_size
				$data = unpack("I", fread($infile, 4));
				$elfSectionHeader->sh_size = $data[1];
				
				// sh_link
				$data = unpack("I", fread($infile, 4));
				$elfSectionHeader->sh_link = $data[1];
				
				// sh_info
				$elfSectionHeader->sh_info = bin2hex(fread($infile, 4));
				
				// sh_addralign
				$data = unpack("I", fread($infile, 4));
				$elfSectionHeader->sh_addralign = $data[1];
				
				// sh_entsize
				$data = unpack("I", fread($infile, 4));
				$elfSectionHeader->sh_entsize = $data[1];
				
				$elfSectionHeaders[$i] = $elfSectionHeader;
				unset($elfSectionHeader);
					
				$offset = $offset+$elfHeader->e_shentsize;
				
			}
			
		}
		
		print_r($elfSectionHeaders);
		*/
		
		/*
		$this->echoMsg("Kernel should start here: " . ($sinoffset+$elfSectionHeader->p_offset));
		
		$elfSectionHeader2 = new stdClass();
		
		// p_type
		$data = unpack("I", fread($infile, 4));
		$elfSectionHeader2->p_type = $data[1];
		
		// p_offset
		$data = unpack("I", fread($infile, 4));
		$elfSectionHeader2->p_offset = $data[1];
		
		// p_vaddr
		$elfSectionHeader2->p_vaddr = bin2hex(fread($infile, 4));
		
		// p_paddr
		$elfSectionHeader2->p_paddr = bin2hex(fread($infile, 4));
		
		// p_filesz
		$data = unpack("I", fread($infile, 4));
		$elfSectionHeader2->p_filesz = $data[1];
		
		// p_memsz
		$data = unpack("I", fread($infile, 4));
		$elfSectionHeader2->p_memsz = $data[1];
		
		// p_flags
		$elfSectionHeader2->p_flags = bin2hex(fread($infile, 4));
		
		// p_align
		$data = unpack("I", fread($infile, 4));
		$elfSectionHeader2->p_align = $data[1];
		
		print_r($elfSectionHeader2);
		
		$this->echoMsg("Ramdisk should start here: " . ($sinoffset+$elfSectionHeader2->p_offset));
		*/
		//fseek($infile, ($sinoffset+$elfSectionHeader2->p_offset), SEEK_SET);
		
		//$outfile = fopen("./ramdisk", "wb");
		//fwrite($outfile, fread($infile, $elfSectionHeader2->p_filesz));
		//fclose($outfile);
		
		//$head = $this->hexToStr(bin2hex(fread($infile, 4)));
		//if (strpos($head, "1F8B") !== false) {
		//	$this->echoMsg("gzipped ramdisk!");
		//}
		
		//fseek($infile, ($sinoffset+$elfSectionHeader->p_offset), SEEK_SET);
		//$outfile = fopen("./zImage", "wb");
		//fwrite($outfile, fread($infile, $elfSectionHeader->p_filesz));
		//fclose($outfile);
		
		/*
		fseek($infile, (($sinoffset+$offset)+($parts*$partsize)), SEEK_SET);
		$head = $this->hexToStr(bin2hex(fread($infile, 64)));
		if (strpos($head, "1F9E") !== false) {
			$this->echoMsg("found ramdisk!");
		}
		*/
		//$magic = $this->hexToStr(bin2hex(fread($infile, 4)));
		
		//for ($i = 0; $i < $parts; $i++) {
			//fseek($infile, ($sinoffset+$offset), SEEK_SET);
			//$data = fread($infile, ($sinoffset+$offset+($parts*$partsize)));
			//$this->echoMsg(($sinoffset+$offset+($parts*$partsize)));
			// SIN and ELF magic
			//$magic = $this->hexToStr(bin2hex(fread($infile, 4)));
			
			//$this->echoMsg($magic, true);
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
			//$offset = ($offset+$partsize);
		//}
		
	}
	
	public function unpack() {
		
		$this->echoMsg("Checking " . $this->path . "/" . $this->filename . " image type...");
		
		clearstatcache();
		$file = fopen($this->path . "/" . $this->filename, "rb");
		
		// SIN and ELF magic
		fseek($file, 1, SEEK_SET);
		$magic = $this->hexToStr(bin2hex(fread($file, 3)));
		
		if (strpos($magic, "SIN") !== false) {
			
			fclose($file);
			
			if ( ($offset = $this->decryptSinFile()) !== false ) {
				
				$this->unpackELFBoot( $offset );
				
			} else {
				
				$this->echoMsg("Decrypting the SIN file failed!", true);
				
			}
			
		} elseif (strpos($magic, "ELF") !== false) {
			
			fclose($file);
			
			$this->unpackELFBoot();
			
		} else {
			
			$this->echoMsg("NO SIN/ELF...");
			
			// ANDROID magic
			fseek($file, 0, SEEK_SET);
			$magic = $this->hexToStr(bin2hex(fread($file, 8)));
			
			if ($magic == "ANDROID!") {
				
				$this->echoMsg("ANDROID!...");
				
				fclose($file);
					
				$this->unpackAndroidBoot();
					
			} else {
				
				$this->echoMsg("WTF?...");
				
				$this->echoMsg("EXIT!\n", true);
				
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
		
		$this->errormessage = "Ramdisk doesn't look right...";
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
		$this->echoMsg("Writing " . $this->target_path . "/" . $this->name . ".boot.cmd");
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
		
		$this->echoMsg("Writing " . $this->target_path . "/" . $this->name . ".zImage (" . round(($kernelsize/1024)/1024, 2) . "MiB)");
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
		$this->echoMsg("Writing " . $this->target_path . "/" . $this->name . ".ramdisk.cpio." . $compressed[$magic] . " (" . round(($ramdisksize/1024)/1024, 2) . "MiB)");
		$outfile = fopen($this->target_path . "/" . $this->name . ".ramdisk.cpio." . $compressed[$magic], "wb");
		fwrite($outfile, fread($infile, $ramdisksize));
		fclose($outfile);
		
		// Extracting the second ramdisk (if it exists)
		if ($secondramdisksize != 0) {
			$secondramdiskstart = (((floor($kernelsize / $page_size)+1)*$page_size)+$page_size) + (((floor($ramdisksize / $page_size)+1)*$page_size));
			fseek($infile, $secondramdiskstart, SEEK_SET);
			
			$magic = strtoupper(bin2hex(fread($infile, 2)));
			
			fseek($infile, $secondramdiskstart, SEEK_SET);
			$this->echoMsg("Writing " . $this->target_path . "/" . $this->name . ".secondramdisk.cpio." . $compressed[$magic] . " (" . round(($secondramdisksize/1024)/1024, 2) . "MiB)");
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
			
			$this->echoMsg("Writing " . $this->target_path . "/" . $this->name . ".dt.img (" . round(($qcdtsize/1024)/1024, 2) . "MiB)");
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
			$this->echoMsg("Writing " . $this->target_path . "/" . $this->name . ".boot.cmd");
		} else {
			$part = substr ( $this->file_contents , $start, $this->filesize);
			$this->bootcmd_str = trim($this->hexToStr($part));
			$file = fopen($this->target_path . "/" . $this->name . ".boot.cmd", "wb");
			fwrite($file, $this->bootcmd_str);
			fclose($file);
			$this->echoMsg("Writing " . $this->target_path . "/" . $this->name . ".boot.cmd");
		}
		
	}
	
	private function dumpPart($start = false, $length = false, $what = 'garbage') {
		
		if (is_null($start) || is_null($length) || $start === false || $length === false) {
			throw new Exception ( 'Not enough parameters supplied to dump a filepart, exiting.' );
		}
		
		$this->echoMsg("Writing " . $this->target_path . "/" . $this->name . "." . $this->fileextensions[$what] . "");
		
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
			$this->errormessage = "Unable to determine the type, are you sure this is a boot image or kernel.sin?";
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
