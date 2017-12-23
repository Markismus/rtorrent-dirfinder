# rtorrent-dirfinder

Quick and dirty script to migrate torrents into rtorrent.

Workflow:
 1) Download torrentfiles and place them into a directory.
 2) Add them to rtorrent, e.g. press enter>directory/\*.torrent>press enter.
 3) Exit rtorrent.
 4) Run script rtorrent-dirfinder.
 5) Get coffee/play game.
 6) run rtorrent and rehash all torrents.


What does the script do?
1) Checks session file for torrents with standard download directory,
2) gets the file and directory names from the torrent file,
3) tries to match directory or else file name to one in $firstdir and else one in $seconddir,
4) if a match occurs, than it changes the session file so that the torrent has new base directory.


Change directory paths to your setup in the scriptlines:
```
# rtorrent install directory
my $homedir="/home/markismus/rtorrent";
# First directory to search down from. Do not use root ('/'), since it'll take forever.
my $firstdir="/mnt/Games";
# Second directory to search down from. Point it at a small useless directory to effectively disable
my $seconddir="/mnt/Comics";

# Standard directories defined in .rtorrent.rc
my $downloaddir="$homedir/download";
my $dir="$homedir/.session";
```

[licence-badge]:http://img.shields.io/badge/licence-AGPL-brightgreen.svg
