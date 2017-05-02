#!/bin/bash
#This script is covered by MIT licence and comes as is, I am not responsible if it burns your pc (and it very well could... read further).
#############################################################
#Copyright <2017> <Nelson-Jean Gaasch - jupiter126@gmail.com>
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#############################################################

#Versions:
# 0.01 concept test
# 0.02 serialised librispeech - used parallel
# 0.03 added tedlium, added f_separate_transcript
# 0.04 cleaned up a bit and added comments
# 0.05 corrected  bug in f_cleanup

if [[ ! -d dataset ]]; then #We create dataset dir if it doesn't exist, again, I recommend mounting from a separate drive.
    mkdir dataset
fi

function f_separate_transcript { #separates dataset.txt into one text per line with the .wav
while IFS='' read -r line || [[ -n "$line" ]]; do 
	fname=$(echo "$line"|cut -f 1 -d" ")
	if [[ -f dataset/$fname.wav ]]; then
        echo "$line"|cut -d" " -f2->dataset/$fname.txt
    fi
done < "dataset.txt"
}

function f_librispeech { #aggregates librispeech datasets
for h in dev-clean dev-other test-clean test-other train-clean-100 train-clean-360 train-other-500; do 
    if [[ ! -f $h.tar.gz ]]; then
        wget http://www.openslr.org/resources/12/$h.tar.gz
    fi
    echo "Uncompressing $h"
    tar -xzf $h.tar.gz
    if [[ -d temp1 ]]; then
        rm -Rf temp1
    fi
    mkdir temp1
    for i in LibriSpeech/$h/*/*/*; do 
        mv $i temp1/
    done
    for i in temp1/*.txt; do 
        cat "$i" >> dataset.txt && rm "$i"
    done
    ls temp1|grep flac|sed 's/.flac//'|parallel -j$(nproc) ffmpeg -i temp1/{}.flac -f wav -acodec pcm_s16le -vn -ac 1 -frame_size 100 dataset/{}.wav
    sleep 5 && rm -Rf temp1 && sleep 5
done
rm -Rf LibriSpeech && sleep 5
}

function f_tedlium { #aggregates librispeech's tedlium
if [[ ! -f TEDLIUM_release1.tar.gz ]]; then
    wget http://www.openslr.org/resources/7/TEDLIUM_release1.tar.gz
fi
tar -xzf TEDLIUM_release1.tar.gz
for h in dev test train; do
    cd TEDLIUM_release1/$h/stm
    for i in *; do
    rectitle="$(echo $i|sed 's/\.stm//')"
    cutcounter="0"
        while IFS='' read -r line || [[ -n "$line" ]]; do
            startt="$(echo "$line"|cut -f 4 -d" ")"&&secs=$(echo $startt|cut -f 1 -d.) && secs="$(printf '%d:%d:%d\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)))" && startt="$secs.$(echo $startt|cut -f 2 -d.)"
            stopt="$(echo "$line"|cut -f 5 -d" ")"&&secs=$(echo $stopt|cut -f 1 -d.) && secs="$(printf '%d:%d:%d\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)))" && stopt="$secs.$(echo $stopt|cut -f 2 -d.)"
            transc="$(echo "$line"|cut -f 2 -d">"|sed -e 's/ //' -e 's/([0-9])//g' -e 's/<sil> //g' -e 's/  / /g' )"
            if [ "$transc" != "ignore_time_segment_in_scoring" ] && [ "$transc" != "" ] && [ "$transc" != " " ]; then
                ((cutcounter++))
                sem -j $(nproc) ffmpeg -i ../sph/$rectitle.sph -ss $startt -to $stopt -f wav -acodec pcm_s16le -vn -ac 1 -frame_size 100 ../../../dataset/$rectitle-$cutcounter.wav & echo "$rectitle-$cutcounter $transc" >> ../../../dataset.txt
            fi
        done < "$i"
    done
    cd -
done
rm -Rf TEDLIUM_release1
}

function f_cleanup { #deletes samples that did not aggregate well
echo "Cleaning dataset"
#1: remove dataset records that don't have a wav file
ls dataset/|grep ".wav"|cut -f 2 -d"/">filelist.txt
while IFS='' read -r line || [[ -n "$line" ]]; do
	identif="$(echo $line|cut -f 1 -d" ")"
		if [[ "$(cat filelist.txt|grep $identif)" = "" ]]; then
        echo "$identif" && grep -v $identif dataset.txt > dataset2 && mv dataset2 dataset.txt
    fi
done < "dataset.txt"
#2: remove wav files that don't have a dataset record
cd dataset
for i in *.wav; do
    if [[ "$(cat ../dataset.txt|grep $(echo $i|cut -f1 -d"."))" = "" ]]; then
        rm $i
    fi
done
}

function f_randomise_sets {
for i in "$(ls train-clean-100-wav|shuf|head -n 500|cut -f 1 -d".")"; do echo $i>>datalist.txt; done && for i in $(cat datalist.txt); do mv train-clean-100-wav/$i.{txt,wav} test-clean-wav/; done
}


#Entry point: script config: comment the functions that you do not need.
#f_librispeech # get and prepare librispeech
#f_tedlium # get and prepare tedlium
#In future releases, add functions to include other datasets here
f_cleanup # go over the dataset to clean inconsistencies
f_separate_transcript # split the dataset.txt into as many txt as wav files (weither you need this depends on the format the model is expecting)s
#f_randomise_sets # creates random training and test sets
