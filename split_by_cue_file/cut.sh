#!/bin/bash

# 
# must remove first TITLE & PERFORMER in cue file
#
#
#


MESSAGE_TXT="$(date +%d-%m-%Y\ %H:%M:%S) - $0:";


IN_PATH="/run/media/vmark/FreeAgent GoFlex Drive/My/Unsorted/Armin van Buuren - A State Of Trance 637 (31.10.2013) 256 kbps";
FILE="Armin van Buuren - A State Of Trance 637 (256 Kbps) baby967.mp3";
CUE="Armin van Buuren - A State Of Trance 637 (256 Kbps) baby967.cue";
START="01:59:30.06";
LONG="05:01.40";

PERFORMER="";
TITLE="";
INDEX="";

#ffmpeg  -i "$IN_PATH/$FILE"  -acodec copy -ss $START -t $LONG  "$IN_PATH/ttt-$FILE";
#exit 0;

##declare array:
declare -a performer;
declare -a title;
declare -a start;
declare -a lenght;


## read from file by line:
echo "$MESSAGE_TXT read cue file.";
i=0;
while read LINE;
do
long=${#LINE};

#fill array
echo "$MESSAGE_TXT filling performer's array.";
if [ "PERFORMER" == "${LINE:0:9}"  ]; then
    performer[i]=${LINE:10:$long};
    i=$(($i+1));
fi

#fill array
echo "$MESSAGE_TXT filling title's array.";
if [ "TITLE" == "${LINE:0:5}"  ]; then
title[i]=${LINE:6:$long};
fi

#fill array
echo "$MESSAGE_TXT filling start interval array.";
if [ "INDEX 01" == "${LINE:0:8}" ]; then
start[i]=${LINE:9:$long};
fi 

done < "$IN_PATH/$CUE";
##end read
echo "$MESSAGE_TXT end reading from cue file.";

##--------------------------------------------
echo "$MESSAGE_TXT take full time.";
duration=$(ffmpeg -i "$IN_PATH/$FILE" 2>&1 | grep Duration)
d1=${duration:12:11};
#02:02:49.94
dh=${d1:0:2}
dm=${d1:3:2}
let dm=60*$dh+$dm
ds=${d1:6:2}
dms=${d1:9:2}
                        

#fill array lenght
echo "$MESSAGE_TXT filling lenght's array using start's array.";
index=2;
while [ "$index" -lt "${#start[@]}" ]
do    # selecting all elements in array
    #select case if lehgth of duration in 8 or 9
    #current values
    tm=${start[$index]};
    case ${#tm} in
    8 )
        m=${tm:0:2}
        s=${tm:3:2}
        ms=${tm:6:2}
        ;;
    9 )
        m=${tm:0:3}
        s=${tm:4:2}
        ms=${tm:7:2}
        ;;
    esac
    echo "$MESSAGE_TXT current time  $tm - min=$m,  sec=$s, msec=$ms";
 
    #next values
    tm1=${start[$index+1]};
    case ${#tm1} in
    8 )
        m1=${tm1:0:2}
        s1=${tm1:3:2}
        ms1=${tm1:6:2}
    ;;
    9 )
        m1=${tm1:0:3}
        s1=${tm1:4:2}
        ms1=${tm1:7:2}
    ;;
    esac
   echo "$MESSAGE_TXT next value of time  $tm1 - min=$m1,  sec=$s1, msec=$ms1";

    if [ $m1 -lt $m ]; then 
        let M=60+$m1-$m
    else
	let M=$m1-$m
    fi
        
    if [ $s1 -lt $s ]; then 
        let S=60+$s1-$s
    else
	let S=$s1-$s
    fi
 
    if [ $ms1 -lt $ms ]; then 
        let MS=100+$ms1-$ms
    else
	let MS=$ms1-$ms
    fi
   
#    echo $M $S $MS;
    ttt=$(printf "%02d:%02d.%02d" $M $S $MS)
#    echo $ttt
    lenght[index]=$ttt;
#    echo " diff $[$m1-$m]"
    let "index = $index + 1";
done

#echo "--------- - min=$m1,  sec=$s1, msec=$ms1";
#echo "--------- - Dmin=$dm,  Dsec=$ds, Dmsec=$dms";
#echo "all: $d1"

echo "$MESSAGE_TXT add last value to lenght's array using start's array and full time.";
     if [ $dm -lt $m ]; then 
        let M=60+$dm-$m
    else
	let M=$dm-$m
    fi

    if [ $ds -lt $s ]; then 
        let S=60+$ds-$s
    else
	let S=$ds-$s
    fi
 
    if [ $dms -lt $ms ]; then 
        let MS=100+$dms-$ms
    else
	let MS=$dms-$ms
    fi 

ttt=$(printf "%02d:%02d.%02d" $M $S $MS)
lenght[index]=$ttt;
echo "$MESSAGE_TXT end filling lenght's array using start's array.";


echo "$MESSAGE_TXT start correcting start's array to format hh:mm:ss.msec";
index=0;
while [ "$index" -lt "${#start[@]}" ]
do    # selecting all elements in array
    
    #select case if lehgth of duration in 8 or 9
    #current values
    tm=${start[$index]};
    case ${#tm} in
    8 )
        m=${tm:0:2}
        s=${tm:3:2}
        ms=${tm:6:2}
        ;;
    9 )
        m=${tm:0:3}
        s=${tm:4:2}
        ms=${tm:7:2}
        ;;
    esac
    
#    if [ $m -gt 60 ]; then  
        let h=$m/60;
        let m=$m-$h*60;
        ttt=$(printf "%02d:%02d:%02d.%02d" $h $m $s $ms);
        start[index]=$ttt;
#    fi
    
    let "index = $index + 1";
done  


echo "$MESSAGE_TXT start cutting original file.";
index=2;
while [ "$index" -lt "${#title[@] + 1}" ]
do    # selecting all elements in array
    echo "$MESSAGE_TXT create file " ${title[index]} ", start pos:" ${start[index]} ", lenght:" ${lenght[index]}

  ffmpeg  -i "$IN_PATH/$FILE"  -acodec copy -ss ${start[index]} -t ${lenght[index]}  "$IN_PATH/TRANCE-${title[index]}.mp3";

    let "index = $index + 1";
done

#print arrays
#echo "$MESSAGE_TXT print arrays.";
#echo " ----------performer ";
#echo ${performer[@]};
# 
#echo " ----------title ";
#echo ${title[@]};
#  
#echo " ---------start";
#echo ${start[@]};
#
#echo " ---------lenght";
#echo ${lenght[@]};
