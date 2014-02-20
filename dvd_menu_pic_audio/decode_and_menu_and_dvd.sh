#!/bin/bash 

export VIDEO_FORMAT=PAL;
MESSAGE_TXT="$(date +%d-%m-%Y\ %H:%M:%S) - $0:";  

#------------------------------------------------------------------------------
# for creating DVD: 
#- put equal count of audio & pis files to AUDIO & PIC dir 
#For menu:
#- put fon picture to MENU_PIC & audio file to MENU_AUDIO
#- write in menu.txt name of menu titles


#----------------------VARS----------------------------------------------------
#dirs for work
# for dvd
DVD_DIR="./DVD";
PIC="./pic";
AUDIO="./audio";
VIDEO="./dvd";
DVD_XML="./DVD.xml";
NameVob="";
# for menu
MENU="./menu";
MENU_PIC="$MENU/pic";
MENU_AUDIO="$MENU/audio";
MENU_TMP="$MENU/tmp";

# menu's files for work
MENU_BUTT="./menu.txt";
SPUMUX="./spum.xml";

#some variables
DRAW_POLY="";
DRAW_TXT="";
DRAW='-draw ';
# start param and point for menu
# x must be x-SpumOffsetX > 0
# y must be y-SpumOffsetY > 0
x=50;
y=35;
offsetY=40;
SpumOffsetX=40;
SpumOffsetYM=25;
SpumOffsetYP=10;
menuButton=$(cat $MENU_BUTT | wc -l);

#size for out dvd ...  720х480 NTSC
SIZE='720x576!'
STEP="";
#-----------------------CHECKs for DECODE--------------------------------------
STEP="CHECKs for DECODE:";
#check exists for dir audio
if ! [ -d "$AUDIO" ] ;
then
    echo "$MESSAGE_TXT $STEP audio's dir don't exists!";
    exit;
else 
    echo "$MESSAGE_TXT $STEP audio's dir exists.";
fi

#check exists for dir pic
if ! [ -d "$PIC" ] ;
then
    echo "$MESSAGE_TXT $STEP pic's dir don't exists!";
    exit;
else
    echo "$MESSAGE_TXT $STEP pic's dir exists.";
fi 

#chek exists for dir dvd
if [ -d "$VIDEO" ] ; 
then
    echo "$MESSAGE_TXT $STEP tmp video's dir exists.";
    rm -rf "$VIDEO/*.*";
else
    mkdir "$VIDEO";
fi 

rm -rf "$DVD_DIR";

#------------------------------------------------------------------------------
#clean DVD.xml
cat /dev/null > "$DVD_XML"; 

#--------------------CHECKs for MENU-------------------------------------------
STEP="CHECKs for MENU:";
echo "$MESSAGE_TXT $STEP checking exists for dir menu's pic:"
if ! [ -d "$MENU_PIC" ] ;
then
    echo "$MESSAGE_TXT $STEP pics dir for menu don't exists!"
    exit;
  else
    echo "$MESSAGE_TXT $STEP menu's pic for menu exists"
fi

echo "$MESSAGE_TXT checking exists for dir menu's audio:"
if ! [ -d "$MENU_AUDIO" ] ;
then
    echo "$MESSAGE_TXT $STEP menu's audio dir for menu don't exists!"
    exit;
else
    echo "$MESSAGE_TXT $STEP menu's audio dir for menu exists"
fi

rm -rf "$SPUMUX";
rm -rf "$MENU_TMP";
rm -rf "$MENU/*.mpg";
echo "$MESSAGE_TXT $STEP cleaned menu's tmp dir and files ... OK"
mkdir "$MENU_TMP";

#-----------------------DECODE-------------------------------------------------
STEP="DECODE:";
echo "$MESSAGE_TXT $STEP ...... resizing pictures."
for i in "$PIC/*.*";
do
    mogrify -resize $SIZE "$i";
#echo "resize $i"
done; 

echo "$MESSAGE_TXT $STEP ...... creating vob files.";
c=0;
for i in $AUDIO/*.*;
do
    c=$(($c+1));
    k=0;
    for j in $PIC/*.*;
    do
	k=$(($k+1));
	if [ $c -eq $k ];
	then
#echo " ---------------->  file pic: '$j' for audio file: '$i'"
	    duration=$(ffmpeg -i "$i" 2>&1 | grep Duration)
	    d1=${duration:12:11};
#echo " duration = [$d1]";
	    NameVob=$(printf "$VIDEO/video_%03d.vob" $c)
	    ffmpeg  -loop 1 -f image2 -i "$j" -i "$i" -threads 4 -target pal-dvd -t $d1 "$NameVob";
    fi
    done;
done; 
vobFiles=$c;

echo "$MESSAGE_TXT $STEP last file in tmp video: $NameVob, count of files: $vobFiles";
#--------------------CREATE MENU-----------------------------------------------
STEP="CREATE MENU:";
echo "$MESSAGE_TXT $STEP resizing menu's tmp fon menu's pic."
for i in "$MENU_PIC/*.*";
do
    mogrify -resize $SIZE "$i";
    convert "$i" -format png "$MENU_TMP/00.png";
done;

echo "$MESSAGE_TXT $STEP creating fon menu's pic and template for buttons."
convert "$MENU_TMP/00.png" +antialias -format ppm -font courier "$MENU_TMP/0.png";
convert -size $SIZE xc:none +antialias -fill transparent "$MENU_TMP/0s.png";
convert -size $SIZE xc:none +antialias -fill transparent "$MENU_TMP/0h.png";

echo "$MESSAGE_TXT $STEP create header for spumux xml file." 
echo "  <subpictures>
    <stream>
      <spu start=\"00:00:00.00\" end=\"00:00:00.0\" 
       select=\"$MENU_TMP/0s.png\" 
       highlight=\"$MENU_TMP/0h.png\" 
       force=\"yes\">" >> "$SPUMUX";

echo "$MESSAGE_TXT $STEP drawing menu's buttons."
i=0;
while read LINE;
do
    echo "$MESSAGE_TXT $STEP menu title: $LINE"
    mogrify -font courier -fill white -pointsize 20 -draw "text $x,$(($y + $(($offsetY * $i)))) '$LINE' " "$MENU_TMP/0.png";
    mogrify +antialias -pointsize 20 -font courier -strokeWidth 2 -stroke red   -draw "text $x,$(($y + $(($offsetY * $i)))) '$LINE' " -depth 8 -density 81x72 "$MENU_TMP/0s.png";
    mogrify +antialias -pointsize 20 -font courier -strokeWidth 2 -stroke green -draw "text $x,$(($y + $(($offsetY * $i)))) '$LINE' " -depth 8 -density 81x72 "$MENU_TMP/0h.png";

# create button for spumux xml file
    prevButt=$(($i));
    nextButt=$(($i+2));
    if [ $i -eq 0 ]; then
            prevButt=$menuButton
    	elif [ $(($i + 1)) -eq $menuButton ]; then
            nextButt='1'
    fi;
    echo "        <button name=\"b$(($i+1))\" x0=\"$(($x-$SpumOffsetX))\" y0=\"$(($y + $(($offsetY * $i)) - $SpumOffsetYM))\"  x1=\"710\" y1=\"$(($y + $(($offsetY * $i)) + $SpumOffsetYP))\" up=\"b$prevButt\" down=\"b$nextButt\" left=\"b$prevButt\"  right=\"b$nextButt\" /> " >> "$SPUMUX";

    i=$(($i+1));
done < "$MENU_BUTT"

echo "$MESSAGE_TXT $STEP created fonPic... OK"

# create trailer for spumux xml file
echo "      </spu>
    </stream>
  </subpictures>" >> "$SPUMUX";

# convert menu's audio for menu
for i in $MENU_AUDIO/*.*;
do
ffmpeg -i "$i" -y "$MENU_TMP/0.mp2";
done;
echo "$MESSAGE_TXT $STEP created menu's audio for menu ... OK"

#  convert video for menu
convert "$MENU_TMP/0.png" -format ppm "$MENU_TMP/0.ppm";
cat "$MENU_TMP/0.ppm" | ppmtoy4m -n 1 -F25:1 -S 420mpeg2 -I t -A 59:54 -L | mpeg2enc --no-constraints -f 8 -n p -F 3 -b 9600 -q 1 -M 4 -a 2 -o "$MENU_TMP/0.m2v";
echo "$MESSAGE_TXT $STEP created m2v menu ... OK"

# join sound and video
mplex -f 8 -v 0 -o "$MENU_TMP/0.mpeg" "$MENU_TMP/0.m2v" "$MENU_TMP/0.mp2";
echo "$MESSAGE_TXT $STEP used mplex for join sound and video .... OK"

# use spumux for create menu
spumux "$SPUMUX" < "$MENU_TMP/0.mpeg" > "$MENU/menu.mpg";
echo "$MESSAGE_TXT $STEP used spumux ... OK"

rm -rf "$MENU_TMP";
echo "$MESSAGE_TXT $STEP cleared menu's tmp files ... OK"


#--------------------CREATE dvd xml -------------------------------------------
STEP="CREATE dvd xml:";
echo "$MESSAGE_TXT $STEP creating xml file."

#vobFiles=

#write xml header for dvd_author's file
echo "<dvdauthor dest=\""$DVD_DIR"\">
<vmgm>
</vmgm>
<titleset>" >>  $DVD_XML;

#write menu for dvd_author's file
echo "   <menus>
    <video  format=\"pal\"/>
    <pgc entry=\"root\">
      <vob file=\"$MENU/menu.mpg\" />" >> $DVD_XML;

it=$[$vobFiles/$menuButton];
for (( c=1; c<=$menuButton; c++ ))
do
k=$[1 + $[$c-1]*$it];
if [ $k -gt $vobFiles ]; then break; fi;
echo "     <button name=\"b$c\">g$c=$c;jump title $k;</button>" >> $DVD_XML;
done;

echo "    </pgc>
  </menus>" >> $DVD_XML;

#write pgs section for vob files to xml file   
echo "   <titles>
    <video  format=\"pal\" />" >> $DVD_XML;

d=1;
for i in $VIDEO/*.*;
do
    if [ "$i" == "$NameVob" ];
        then d=1;
    else
        d=$(($d+1));
    fi;
    echo "    <pgc>
      <vob file=\"$i\" chapters=\"00:00:00\" />
      <post>jump title $d;</post>
    </pgc>" >> $DVD_XML;
    done;

#write foot to xml file    
echo "</titles>
</titleset>
</dvdauthor>" >> $DVD_XML; 
 
#--------------------CREATE dvd -----------------------------------------------
STEP="CREATE DVD:"; 
echo "$MESSAGE_TXT $STEP creating DVD struct.";
export VIDEO_FORMAT=PAL;
dvdauthor -x $DVD_XML;

#------------------------------------------------------------------------------ 
