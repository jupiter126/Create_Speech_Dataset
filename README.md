# Create_Speech_Dataset

Note: Last version known to work is 0.11 - currently testing 0.14, but takes a long time!

# Purpose:
This scripts fetches open datasets of speech and transcription and aggregates them into a large metaset hopefully suitable for machine learning. Current script builds a 1089 hour dataset, based on librispeech and TEDLIUM

# Requirements:
- ffmpeg<br />
- pv<br />
- sox<br />
- parallel (O. Tange (2011): GNU Parallel - The Command-Line Power Tool ;login: The USENIX Magazine, February 2011:42-47.) <br />
- bc (if bc is present on system, script will report running time once in a while)

# Special notes:
1. GNU parallel (and sem) are used to spawn $(nproc) ffmpeg (the number of cores in the machine), as side effect, the more cores you have, the more it is IO intensive on the hard drives, leading to point 2<br />
2. It is recommended to mount a partition from another physical hard drive as the "dataset" folder.  This makes things much faster, and will help preventing this script to burn your hard drive (We're talking about read/writes of over 1 million files in total)
3. When needed to regenerate a new dataset from scratch, it goes MUCH faster do fdisk/mkfs the dataset partition than to rm all files
   something like "# umount /dev/sdg1 && fdisk /dev/sdg && mkfs.ext4 /dev/sdg1 && mount /dev/sdg1 && chown -R jupiter:jupiter /home/jupiter/data/_Speech/dataset"

# Usage
Reading the source always helps
## first, set options:

datasetdir="dataset"
recdir="recordings"		#name of the directory used to store recordings
texdir="transcripts"	#name of the directory used to store transcripts, if transcripts are to be saved in the same dir as wav, set this to the same value as var above.
traindir="train"		#name of the dir containing training set
testdir="test"			#name of the dir containing test set
testval="500"			#number of entries in test set (0 if you don't want a test set)
devdir="dev"			#name of the dir containing dev set
devval="200"			#number of entries in the dev set

the defaults options will create the following:
-dataset
	-test
		-recordings: 500 wav files
		-transcripts: 500 corresponding txt files
	-dev
		-recordings: 200 wav files
		-transcripts: 200 corresponding txt files
	-train
		-recordings: The rest of the wav files
		-transcripts: The rest of corresponding text files

## Once options are set,

	- Either the program is started without arguments and will be ran in "intercative" mode, or the program is ran with arguments for script mode.
	So far, the arguments for scripting mode are :
		- 1 to build and aggregate librispeech and TEDLIUM
		- 2 To build librispeech
		- 3 To build TEDLIUM
 
  ==> to build only TEDLIUM --> ./dataset_preparation.sh 3
