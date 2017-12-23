	#! /bin/perl
use Term::ANSIColor;    #Color display on terminal
# use Roman qw(arabic Roman roman);              #Conversion between Roman and Arabic numerals
use strict;
use diagnostics;
use warnings;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use Cwd;                # http://www.perlhowto.com/get_the_current_working_directory

use Image::Info qw(image_info dim);
use Image::Size;

use Scalar::Util qw(looks_like_number);

#use Devel::Leak::Object qw{ GLOBAL_bless };
#~ use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
# use utf8;
use Storable;       #To storage the hash %Warning_per_volume.
use LWP::Simple;    # To download the covers.
use Sort::Key::Natural qw(natsort); # This should sort the keys of the pages whether they are roman or arabic.
use Font::TTFMetrics; #To assess the width of a string, so that I can decide how many lines it'll span.we
use Capture::Tiny ':all';
use Time::HiRes qw(  gettimeofday tv_interval  );
use Term::Title qw(set_titlebar);

my $isDebug= 1;
my $isDebugVerbose = 1;
my $isDebugVeryVerbose = 1;

sub Debug { $isDebug and PrintRed( @_, "\n" );	}

sub DebugV { $isDebugVerbose and PrintCyan( @_, "\n" ) ; }

sub DebugVV { $isDebugVeryVerbose and PrintYellow( @_, "\n" ) ;	}

sub DebugFindings {
    DebugV();
    if ( defined $1 )  { DebugV("1 is:\n $1\n"); }
    if ( defined $2 )  { DebugV("2 is:\n $2\n"); }
    if ( defined $3 )  { DebugV("3 is:\n $3\n"); }
    if ( defined $4 )  { DebugV("4 is:\n $4\n"); }
    if ( defined $5 )  { DebugV("5 is:\n $5\n"); }
    if ( defined $6 )  { DebugV("6 is:\n $6\n"); }
    if ( defined $7 )  { DebugV("7 is:\n $7\n"); }
    if ( defined $8 )  { DebugV("8 is:\n $8\n"); }
    if ( defined $9 )  { DebugV("9 is:\n $9\n"); }
    if ( defined $10 ) { DebugV("10 is:\n $10\n"); }
    if ( defined $11 ) { DebugV("11 is:\n $11\n"); }
    if ( defined $12 ) { DebugV("12 is:\n $12\n"); }
    if ( defined $13 ) { DebugV("13 is:\n $13\n"); }
    if ( defined $14 ) { DebugV("14 is:\n $14\n"); }
    if ( defined $15 ) { DebugV("15 is:\n $15\n"); }
    if ( defined $16 ) { DebugV("16 is:\n $16\n"); }
    if ( defined $17 ) { DebugV("17 is:\n $17\n"); }
    if ( defined $18 ) { DebugV("18 is:\n $18\n"); }
}
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
    # Info("Written $FileName. Exiting sub ArraytoFile\n");
    return ("File written");
}

my $homedir="/home/markismus/rtorrent";
my $downloaddir="$homedir/download";
my $dir="$homedir/.session";
my $firstdir="/mnt/Ebooks";
my $seconddir="/mnt/Comics";

my @torrents=glob("$dir/*.torrent");
my %torrents;
my %rtorrents;
foreach my $torrent(@torrents){
	# DebugV("$torrent");
	my $key;
	my $reggeddir=qr/\Q$dir\E/;
	if( $torrent=~ m~$reggeddir/([A-F0-9]+).torrent~){
		$key=$1;
		# DebugVV($key);
		my @Torrentfile = FiletoArray( $torrent ) ;
		# Debug($Torrentfile[0]);
		$Torrentfile[0]=~ s~(.+pieces\d+).+~$1~;
		my @TorrentInfo = split /:/,$Torrentfile[0];
		my $next=0;
		my $namelength;
		my $name;
		foreach(@TorrentInfo){
			# DebugV($_);
			if(/name(\d+)/){
				$namelength=$1;
				$next=1;
				next;
			}
			if($next){$name = substr($_,0,$namelength) ; $next=0; $torrents{$key}=$name;last;}

			
		}
	}
}
# foreach(keys %torrents){DebugV("$_ is $torrents{$_}");}
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
		
		# $Title=~s~\(~\\\(~g;
		# $Title=~s~\)~\\\)~g;
		# $Title=~s~\{~\\\{~g;
		# $Title=~s~\}~\\\}~g;
		
		
		my $findresult=`find $firstdir -name "$Title" -exec dirname {} \\; -print0 -quit| head -n 1`;
		if ($findresult eq ""){$findresult=`find $seconddir -name "$Title" -exec dirname {} \\; -print0 -quit| head -n 1`;}
		if($findresult eq ""){Debug("Couldn't find path!");next;}
		chomp $findresult;
		DebugV("Find result is $findresult$Path ")		;
		my $DLenght = length ( $findresult.$Path);
		DebugV($DLenght);
		my @rtorrent = FiletoArray("$dir/".$key.".torrent.rtorrent");
		# DebugVV(@rtorrent);
		#directory31:/home/markismus/Downloads/Storm7:hashing
		my $Replacestring="directory$DLenght:".$findresult.$Path."7:hashing";
		if($rtorrent[0]=~ s~directory\d+:.+7:hashing~$Replacestring~){
			# Debug("String replaced");
			# Debug($rtorrent[0]);
			if(rename "$dir/".$key.".torrent.rtorrent", "$dir/".$key.".torrent.rtorrent.orig"){
				ArraytoFile("$dir/".$key.".torrent.rtorrent",@rtorrent);
			}
			else{
				Debug("Cound't rename the file, saving the new data as corrected-file.");
				ArraytoFile("$dir/".$key.".torrent.rtorrent.corrected",@rtorrent);	
			}


		}





	}

}

