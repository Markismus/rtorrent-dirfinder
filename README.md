# rtorrent-dirfinder

Quick and dirty script to migrate torrents into rtorrent.

Workflow:
a) Download torrentfiles and place them into a directory.
b) Add them to rtorrent, e.g. press enter>directory/\*.torrent>press enter.
c) Exit rtorrent.
d) Run script rtorrent-dirfinder.
e) Get coffee/play game.
f) run rtorrent and rehash all torrents.


What does the script do?
1) Checks session file for torrents with standard download directory,
2) gets the file and directory names from the torrent file,
3) tries to match directory or else file name to one in $firstdir and else one in $seconddir,
4) if a match occurs, than it changes the session file so that the torrent has new base directory.


Change directory paths to your setup in the scriptlines:
\# rtorrent install directory
my $homedir="/home/markismus/rtorrent";
\# First directory to search down from. Do not use root ('/'), since it'll take forever.
my $firstdir="/mnt/Games";
\# Second directory to search down from. Point it at a small useless directory to effectively disable
my $seconddir="/mnt/Comics";

\# Standard directories defined in .rtorrent.rc
my $downloaddir="$homedir/download";
my $dir="$homedir/.session";
