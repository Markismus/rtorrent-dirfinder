#! /bin/perl

use Term::ANSIColor;    #Color display on terminal
use strict;
use warnings;

my $isDebug= 1;
my $isDebugVerbose = 1;
my $isDebugVeryVerbose = 0;

sub Debug { $isDebug and PrintRed( @_, "\n" );	}
sub DebugV { $isDebugVerbose and PrintCyan( @_, "\n" ) ; }
sub DebugVV { $isDebugVeryVerbose and PrintYellow( @_, "\n" ) ;	}

#  black  red  green  yellow  blue  magenta  cyan  white
sub PrintGreen   { print color('green');   print @_; print color('reset'); }
sub PrintBlue    { print color('blue');    print @_; print color('reset'); }
sub PrintRed     { print color('red');     print @_; print color('reset'); }
sub PrintYellow  { print color('yellow');  print @_; print color('reset'); }
sub PrintMagenta { print color('magenta'); print @_; print color('reset'); }
sub PrintCyan    { print color('cyan');    print @_; print color('reset'); }

sub FiletoArray {

    #This subroutine expects a path-and-filename in one and returns an array
    my $FileName = $_[0];
    open( FILE, "$FileName" )
      || warn "Cannot open $FileName: $!\n";
    my @ArrayLines = <FILE>;
    close(FILE);
    $FileName =~ s/.+\/(.+)/$1/;
    return (@ArrayLines);
}

sub ArraytoFile {
    my ( $FileName, @Array ) = @_;
    DebugVV("Array to be written:\n",@Array);
    open( FILE, ">$FileName" )
      || warn "Cannot open $FileName: $!\n";
    print FILE @Array;
    close(FILE);
    $FileName =~ s/.+\/(.+)/$1/;
    return ("File written");
}

# rtorrent install directory
my $homedir="/home/markismus/rtorrent";
# First directory to search down from. Do not use root ('/'), since it'll take forever.
my $firstdir="/mnt/Games";
# Second directory to search down from. Point it at a small useless directory to effectively disable
my $seconddir="/mnt/Comics";

# Standard directories defined in .rtorrent.rc
my $downloaddir="$homedir/download";
my $dir="$homedir/.session";

my @torrents=glob("$dir/*.torrent");
my %torrents;
my %rtorrents;
foreach my $torrent(@torrents){
	DebugV("$torrent");
	my $key;
	my $reggeddir=qr/\Q$dir\E/;
	if( $torrent=~ m~$reggeddir/([A-F0-9]+).torrent~){
		$key=$1;
		DebugVV($key);
		my @Torrentfile = FiletoArray( $torrent ) ;
		DebugVV($Torrentfile[0]);
		$Torrentfile[0]=~ s~(.+pieces\d+).+~$1~;
		my @TorrentInfo = split /:/,$Torrentfile[0];
		my $next=0;
		my $namelength;
		my $name;
		foreach(@TorrentInfo){
			DebugVV($_);
			if(/name(\d+)/){
				$namelength=$1;
				$next=1;
				next;
			}
			if($next){$name = substr($_,0,$namelength) ; $next=0; $torrents{$key}=$name;last;}

			
		}
	}
}

if ( $isDebugVeryVerbose ){ 
	foreach(keys %torrents){DebugVV("$_ is $torrents{$_}");}
}

my @rtorrents=glob("$dir/*.rtorrent");
foreach my $rtorrent(@rtorrents){
	# print("$_\n");
	my $key;
	my $reggeddir=qr/\Q$dir\E/;
	if( $rtorrent=~ m~$reggeddir/([A-F0-9]+).torrent.rtorrent~){
		$key=$1;
		# DebugVV($key);
		my @rTorrentfile = FiletoArray( $rtorrent ) ;
		# foreach(@rTorrentfile){Debug($_);}
		# Debug(scalar(@Torrentfile));
		my @rTorrentInfo = split /:/,$rTorrentfile[0];
		# foreach(@TorrentInfo){Debug($_);}
		my $next=0;
		my $directorylength;
		my $directory;
		foreach(@rTorrentInfo){
			# DebugV($_);
			if(/directory(\d+)/){
				$directorylength=$1;
				$next=1;
				next;
			}
			if($next){
				$directory = substr($_,0,$directorylength) ; 
				$next=0; 
				$rtorrents{$key}=$directory;
				last;
			}
		}
	}
}

foreach my $key(keys %rtorrents){
	if(! defined $torrents{$key}){next;}	
	my $Title="";
	my $Path="";
	my $reggeddownloaddir=qr/\Q$downloaddir\E/;
	if($rtorrents{$key}=~ m~^$reggeddownloaddir/?(.*)~){
		DebugV("torrent key $key is $torrents{$key}");
		DebugV("rtorrent key $key is $rtorrents{$key}");
		DebugV("Still default path");
		if($1 ne ""){
			$Title=$1;
			$Path="/$1";
			DebugVV("Searchpath is $Title");
			# DebugVV("$Title"."$torrents{$key}")
		}
		else{
			$Title=$torrents{$key};
			DebugVV("Searchtitle is $Title");
		}
		# Clean up title to enter as regex in find
		if ( $Title=~s~\[~\\\[~g ){	DebugVV("Cleaned title is $Title");	}
		if ( $Title=~s~\]~\\\]~g ){	DebugVV("Cleaned title is $Title");	}
		

		my $findresult=`find $firstdir -name "$Title" -exec dirname {} \\; -print0 -quit| head -n 1`;
		if ($findresult eq ""){$findresult=`find $seconddir -name "$Title" -exec dirname {} \\; -print0 -quit| head -n 1`;}
		if($findresult eq ""){Debug("Couldn't find path!");next;}
		chomp $findresult;
		DebugV("Find result is $findresult$Path ")		;
		my $DLenght = length ( $findresult.$Path);
		DebugV($DLenght);
		my @rtorrent = FiletoArray("$dir/".$key.".torrent.rtorrent");
		DebugVV(@rtorrent);
		#Example: directory31:/home/markismus/Downloads/Storm7:hashing
		my $Replacestring="directory$DLenght:".$findresult.$Path."7:hashing";
		if($rtorrent[0]=~ s~directory\d+:.+7:hashing~$Replacestring~){
			DebugVV("String replaced");
			DebugVV($rtorrent[0]);
			if(rename "$dir/".$key.".torrent.rtorrent", "$dir/".$key.".torrent.rtorrent.orig"){
				ArraytoFile("$dir/".$key.".torrent.rtorrent",@rtorrent);
			}
			else{
				Debug("Cound't rename the file, saving the new data as corrected-file.");
				ArraytoFile("$dir/".$key.".torrent.rtorrent.corrected",@rtorrent);	
			}


		}
	}
	else{
		DebugV("rtorrent key is $rtorrents{$key}");
	}
}


