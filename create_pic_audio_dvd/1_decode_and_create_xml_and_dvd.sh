#!/bin/bash

XML=DVD.xml;
NameVob='';
#clean DVD.xml
cat /dev/null > "$XML";

#check exists for dir audio
if ! [ -d ./audio ] ;
then
    exit;
else 
    echo "audio exists"
fi

#check exists for dir pic
if ! [ -d ./pic ] ;
then
    exit;
else
    echo "pic exists"
fi

#echo " ...... resize pictures."
for i in ./pic/*.*;
do
    mogrify -resize 720x480 "$i";
#echo "resize $i"
done;

#chek exists for dir dvd
if [ -d ./dvd ] ; 
then
    echo "dvd exists"
else
    mkdir ./dvd
fi

#echo " ...... create vob files.";
c=0;
for i in ./audio/*.*;
do
    c=$(($c+1));
    k=0;
    for j in ./pic/*.*;
    do
	k=$(($k+1));
	if [ $c -eq $k ];
	then
#echo " ---------------->  file pic: '$j' for audio file: '$i'"
	    duration=$(ffmpeg -i "$i" 2>&1 | grep Duration)
	    d1=${duration:12:11};
#echo " duration = [$d1]";
	    NameVob=$(printf "./dvd/video_%03d.vob" $c)
	    ffmpeg  -loop 1 -f image2 -i "$j" -i "$i" -threads 4 -target pal-dvd -t $d1 "$NameVob";
    fi
    done;
done;


echo "Last file $NameVob";

#write xmlder for  file for dvd_author
echo "<dvdauthor dest=\"DVD\">
<vmgm>
</vmgm>
<titleset>
  <titles>
    <video  format=\"pal\" />" >> $XML;

#write pgs section for vob files to xml file   
d=1;
for i in ./dvd/*.*;
do
    if [ "$i" == "$NameVob" ];
        then d=1;
    else
        d=$(($d+1));
    fi;
    echo "    <pgc>
      <vob file=\"$i\" chapters=\"00:00:00\" />
      <post>jump title $d;</post>
    </pgc>" >> $XML;
    done;

#write foot to xml file    
echo "</titles>
</titleset>
</dvdauthor>" >> $XML; 
 

# create DVD struct
export VIDEO_FORMAT=PAL;
dvdauthor -x DVD.xml;

