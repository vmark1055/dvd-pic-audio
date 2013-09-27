dvd-pic-audio
=============

set of srcipts for create simply dvd with audio+picture

Scripts for creating DVD with simple structure.
Requirements:
- dvdauthor;
- ffmpeg;
- ImageMagic.

1. create-pic-audio-dvd.
Creating dvd like as slide show  with one picture to one audio for one chapter.
Using: 
- put equals count of audio files and picture files into 'audio' and 'pic' directories;
- run 1_decode_and_create_xml_and_dvd.sh.

2. create-menu-dvd.
Creating menu for dvd (with one picture to one audio for one chapter). 
Using: 
- put audio file (audio for menu) and picture file (menu pic) into 'menu/audio' and 'menu/pic' directories;
- write menu's title to menu.txt(each line - title) , look like:

line1:Title #1
line2:Title #2

- run create_menu.sh.
Titles for menu created with equals count of vob files from total count of  files.

3. dvd_menu_pic_audio.
Creating dvd with menu.
Using:
- put equals count of audio files and picture files into 'audio' and 'pic' directories;
- put audio file (audio for menu) and picture file (menu pic) into 'menu/audio' and 'menu/pic' directories;
- write menu's title to menu.txt, look like:

Title #1
Title #2
Title #3

- run decode_and_menu_and_dvd.sh.
Titles for menu created with equals count of vob files from total count of  files.
Script create_dvd_xml.sh is designed for creating DVD after manual correcting of  jumping to title in menu (as you like :) ).
