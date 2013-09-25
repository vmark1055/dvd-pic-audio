#!/bin/bash 

export VIDEO_FORMAT=PAL;

# dir for work
MENU=./menu
PIC=./menu/pic
AUDIO=./menu/audio
TMP=./menu/tmp

# files for work
MENU_BUTT="./menu.txt";
SPUMUX="./spum.xml";

#some variables
DRAW_POLY="";
DRAW_TXT="";
DRAW='-draw ';
MESSAGE_TXT="$(date +%d-%m-%Y\ %H:%M:%S) - $0:";

#size for out dvd ...  720х480 NTSC
SIZE='720x576!'

echo "$MESSAGE_TXT check exists for dir pic:"
if ! [ -d "$PIC" ] ;
then
    echo "$MESSAGE_TXT pics dir don't exists!"
    exit;
  else
    echo "$MESSAGE_TXT pic exists"
fi

echo "$MESSAGE_TXT check exists for dir audio:"
if ! [ -d "$AUDIO" ] ;
then
    echo "$MESSAGE_TXT audio dir don't exists!"
    exit;
else
    echo "$MESSAGE_TXT audio exists"
fi

rm -rf "$TMP";
rm -rf "$MENU/*.mpg";
echo "$MESSAGE_TXT cleaned tmp dir and files ... OK"
mkdir "$TMP";

#resize tmp fon pic
for i in "$PIC/*.*";
do
    mogrify -resize $SIZE "$i";
    convert "$i" -format png "$TMP/00.png";
done;

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
echo "$MESSAGE_TXT count of button: $menuButton";

rm -rf "$SPUMUX";

# create fon pic and template for buttons
convert "$TMP/00.png" +antialias -format ppm -font courier "$TMP/0.png";
convert -size $SIZE xc:none +antialias -fill transparent "$TMP/0s.png";
convert -size $SIZE xc:none +antialias -fill transparent "$TMP/0h.png";

# create header for spumux xml file 
echo "  <subpictures>
    <stream>
      <spu start=\"00:00:00.00\" end=\"00:00:00.0\" 
       select=\"./menu/tmp/0s.png\" 
       highlight=\"./menu/tmp/0h.png\" 
       force=\"yes\">" >> "$SPUMUX";

# draw menu's buttons
i=0;
while read LINE;
do
    echo "$MESSAGE_TXT menu title: $LINE"
    mogrify -font courier -fill white -pointsize 20 -draw "text $x,$(($y + $(($offsetY * $i)))) '$LINE' " "$TMP/0.png";
    mogrify +antialias -pointsize 20 -font courier -strokeWidth 2 -stroke red   -draw "text $x,$(($y + $(($offsetY * $i)))) '$LINE' " -depth 8 -density 81x72 "$TMP/0s.png";
    mogrify +antialias -pointsize 20 -font courier -strokeWidth 2 -stroke green -draw "text $x,$(($y + $(($offsetY * $i)))) '$LINE' " -depth 8 -density 81x72 "$TMP/0h.png";

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
echo "$MESSAGE_TXT created fonPic... OK"

# create trailer for spumux xml file
echo "      </spu>
    </stream>
  </subpictures>" >> "$SPUMUX";

# convert audio for menu
for i in $AUDIO/*.*;
do
ffmpeg -i "$i" -y "$TMP/0.mp2";
done;
echo "$MESSAGE_TXT created audio for menu ... OK"

#  convert video for menu
convert "$TMP/0.png" -format ppm "$TMP/0.ppm";
cat "$TMP/0.ppm" | ppmtoy4m -n 1 -F25:1 -S 420mpeg2 -I t -A 59:54 -L | mpeg2enc --no-constraints -f 8 -n p -F 3 -b 9600 -q 1 -M 4 -a 2 -o "$TMP/0.m2v";
echo "$MESSAGE_TXT created m2v menu ... OK"

# join sound and video
mplex -f 8 -v 0 -o "$TMP/0.mpeg" "$TMP/0.m2v" "$TMP/0.mp2";
echo "$MESSAGE_TXT used mplex for join sound and video .... OK"

# use spumux for create menu
spumux "$SPUMUX" < "$TMP/0.mpeg" > "$MENU/menu.mpg";
echo "$MESSAGE_TXT used spumux ... OK"

rm -rf "$TMP";
echo "$MESSAGE_TXT cleared tmp files ... OK"