# MP3TAGGER

A small Ruby script to tag mp3 files in the current directory.

Performs the following.

* Prompts for the album, artist, year and genre that will be applied to all the files.
* For each file prompt for the track number and title. Displays sensible defaults if possible.
* Clear existing tags.
* Save new id3v2 tags.
* Rename existing files using the format <track>-<title>.mp3

## Dependencies

Requires the highline and mp3info gems to be installed.
