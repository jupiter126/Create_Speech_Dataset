#!/bin/bash
#This script is covered by MIT licence and comes as is, I am not responsible if it burns your pc (and it very well could: check the readme.md from https://github.com/jupiter126/Create_Speech_Dataset).
#############################################################
#Copyright <2017> <Nelson-Jean Gaasch - jupiter126@gmail.com>
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#############################################################
# Options
# pre 0.07 behaviour was that recodir=textdir - if that's what you need, just set the same name in both.
# Warning: avoid spaces, I didn't test but tend to encounter problems with those in my scripts!
recodir="dataset/mfcc" #the directory where the wav wil be saved
textdir="dataset/label" #the directory where the labels will be saved
#End of options
arg1="$1"
export recodir
export textir
directory="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for directo in "$recodir" "$textdir"; do
if [[ ! -d "$directo" ]]; then #We create dataset dir if it doesn't exist, again, I recommend mounting from a separate drive.
    mkdir -p "$directo"
fi
done

function f_purge_dataset_txt {
if [[ -f dataset.txt ]]; then
    rm dataset.txt && sleep 2
fi
touch dataset.txt
}

function f_separate_transcript { # separates dataset.txt into one file per wav, places then according to $recandtext
while IFS='' read -r line || [[ -n "$line" ]]; do
	fname=$(echo "$line"|cut -f 1 -d" ")
	if [[ -f "$recodir/$fname.wav" ]]; then
        echo "$line"|cut -d" " -f2->"$textdir/$fname.txt"
    fi
done < "dataset.txt"
}

function f_librispeech { # aggregates librispeech datasets
for h in dev-clean dev-other test-clean test-other train-clean-100 train-clean-360 train-other-500; do
    if [[ ! -f $h.tar.gz ]]; then
        echo "downloading $h.tar.gz"
        wget http://www.openslr.org/resources/12/$h.tar.gz
    fi
    echo "Uncompressing $h"
    pv $h.tar.gz|tar -xzf -
    if [[ -d temp1 ]]; then
        rm -Rf temp1
    fi
    mkdir temp1
    for i in LibriSpeech/$h/*/*/*; do
        mv "$i" temp1/
    done
    for i in temp1/*.txt; do
        cat "$i" >> dataset.txt && rm "$i"
    done
    echo "Converting $h to wav..."
    ls temp1|grep flac|sed 's/.flac//'|parallel --env recodir -j"$(nproc)" ffmpeg -nostats -loglevel 0 -i temp1/{}.flac -f wav -acodec pcm_s16le -vn -ac 1 -frame_size 100 $recodir/{}.wav
    sleep 5 && rm -Rf temp1 && sleep 5
done
rm -Rf LibriSpeech && sleep 5
}

function f_tedlium { # aggregates librispeech's tedlium
if [[ ! -f TEDLIUM_release1.tar.gz ]]; then
    wget http://www.openslr.org/resources/7/TEDLIUM_release1.tar.gz
fi
echo "Uncompressing TEDLIUM..."
pv TEDLIUM_release1.tar.gz|tar -xzf -
for h in dev test train; do
    cd TEDLIUM_release1/$h/stm
    for i in *; do
    rectitle="$(echo $i|sed 's/\.stm//')"
    cutcounter="0"
        while IFS='' read -r line || [[ -n "$line" ]]; do
            startt="0"
            stopt="0"
            transc="$(echo "$line"|cut -f 2 -d">"|sed -e 's/ //' -e 's/([0-9])//g' -e 's/<sil> //g' -e 's/<sil//g' -e 's/  / /g' )"
            if [ "$transc" != "ignore_time_segment_in_scoring" ] && [ "$transc" != "" ] && [ "$transc" != " " ]; then
                startt="$(echo "$line"|cut -f 4 -d" ")"&&secs=$(echo $startt|cut -f 1 -d.) && secs="$(printf '%d:%d:%d\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)))" && startt="$secs.$(echo $startt|cut -f 2 -d.)"  &&  stopt="$(echo "$line"|cut -f 5 -d" ")"&&secs=$(echo $stopt|cut -f 1 -d.) && secs="$(printf '%d:%d:%d\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)))" && stopt="$secs.$(echo $stopt|cut -f 2 -d.)"  #Replace this with something more elegant...
                ((cutcounter++))
                if [ "$startt" != "0" ] && [ "$stopt" != "0" ]; then
                    sem -j $(nproc) ffmpeg -nostats -loglevel 0 -i ../sph/$rectitle.sph -ss $startt -to $stopt -f wav -acodec pcm_s16le -vn -ac 1 -frame_size 100 ../../../$recodir/$rectitle-$cutcounter.wav & echo "$rectitle-$cutcounter $transc" >> ../../../dataset.txt
                fi
            fi
        done < "$i"
    done
    cd "$directory"
done
echo "waiting 2 minutes before killing all remaining ffmpeg"
sleep 120 && for i in $(pgrep -f ffmpeg);do kill -9 $i && sleep 1;done
rm -Rf TEDLIUM_release1
}

function f_clean_dataset { # deletes samples that did not aggregate well
echo "Cleaning dataset, part 1"
#1: remove dataset records that don't have a wav file
ls $recodir/|grep ".wav"|cut -f 2 -d"/">filelist.txt
while IFS='' read -r line || [[ -n "$line" ]]; do
	identif="$(echo "$line"|cut -f 1 -d" ")"
		if [[ "$(grep "$identif" filelist.txt)" = "" ]]; then
        echo "$identif is bugged" && grep -v "$identif" dataset.txt > dataset2 && mv dataset2 dataset.txt
    fi
done < "dataset.txt"
#2: remove wav files that don't have a dataset record
echo "Cleaning dataset, part 2"
while IFS='' read -r line || [[ -n "$line" ]]; do
    if [[ "$(grep "$(echo $line|sed 's/\.wav//') dataset.txt")" = "" ]]; then
        echo "$recodir/$line is bugged" && rm "$recodir/$line"
    fi
done < "filelist.txt"
sleep 5 && rm filelist.txt
echo "Done cleaning dataset"
}

function f_count_time { # calculates the total amount of recording time in the dataset as of 0.06, complete aggregated dataset time is about 1197 hours.
echo "Counting dataset recording time"
cd "$recodir" || return 1
ls|grep ".wav"|parallel -j"$(nproc)" soxi -D {}|awk '{SUM += $1} END { printf "%d:%d:%d\n",SUM/3600,SUM%3600/60,SUM%60}'
cd "$directory"
}

function f_randomise_sets {  # makes a random training dataset from global metaset -- incomplete
for i in "$(ls train-clean-100-wav|shuf|head -n 500|cut -f 1 -d".")"; do echo $i>>datalist.txt; done && for i in $(cat datalist.txt); do mv train-clean-100-wav/$i.{txt,wav} test-clean-wav/; done
}

function f_nope { # thanks to moo \o/
echo " ___________________________________________________________________"
echo "| Error:                                                       |"
echo "| same player shoot again, wrong choice I guess !!! |"
echo " -------------------------------------------------------------------"
echo "        \   ^__^"
echo "         \  (oo)\_______"
echo "            (__)\       *\/\ "
echo "                ||----w | "
echo "                ||     || "
echo "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
}

function f_script {
if [[ "x$arg1" = "x1" ]]; then
    f_purge_dataset_txt
    f_librispeech
    f_tedlium
    f_clean_dataset
    f_separate_transcript
    f_count_time
elif [[ "x$arg1" = "x2" ]]; then
    f_purge_dataset_txt
    f_librispeech
    f_clean_dataset
    f_separate_transcript
    f_count_time
elif [[ "x$arg1" = "x3" ]]; then
    f_purge_dataset_txt
    f_tedlium
    f_clean_dataset
    f_separate_transcript
    f_count_time
fi
}

function m_main { # Main Menu (displayed if genQL is called without args)
while [ 1 ]
do
	PS3='Choose a number: '
	select choix in "Build_all" "Generate_librispeech" "Generate_TEDLIUM" "Clean_dataset" "Count_time" "Quit"
	do
		break
	done
	case $choix in
        Build_all)                 arg1="1"&&f_script;;
		Generate_librispeech)      f_librispeech;;
		Generate_TEDLIUM)          f_tedlium;;
		Clean_dataset)             f_clean_dataset;;
		Count_time)                f_count_time;;
#		Randomise_sets)            ;;
		Quit)                     echo "bye ;)";exit 0;;
		*)                        f_nope;;
	esac
done
}

# Entry point
if [ "x$arg1" = "x" ]; then # go to main menu if there are no args
    m_main
elif [ "x$arg1" != "x" ]; then #if started with script
	f_script
else
	echo "argument not known, arg can be \"script X\""
fi
