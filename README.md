# Create_Speech_Dataset

# Purpose:
This scripts fetches open datasets of speech and transcription and aggregates them into a large metaset hopefully suitable for machine learning. Current script builds a 1089 hour dataset.

# Requirements:
- ffmpeg<br />
- pv<br />
- sox<br />
- parallel (O. Tange (2011): GNU Parallel - The Command-Line Power Tool ;login: The USENIX Magazine, February 2011:42-47.) <br />

# Special notes:
1. GNU parallel (and sem) are used to spawn $(nproc) ffmpeg (the number of cores in the machine), as side effect, the more cores you have, the more it is IO intensive on the hard drives, leading to point 2<br />
2. It is recommended to mount a partition from another physical hard drive as the "dataset" folder.  This makes things much faster, and will help preventing this script to burn your hard drive (We're talking about read/writes of over 1 million files in total)
3. When needed to regenerate a new dataset from scratch, it goes MUCH faster do fdisk/mkfs the dataset partition than to rm all files
   something like "# umount /dev/sdg1 && fdisk /dev/sdg && mkfs.ext4 /dev/sdg1 && mount /dev/sdg1 && chown -R jupiter:jupiter /home/jupiter/data/_Speech/dataset"

# Usage
Reading the source always helps
- Either the program is started without arguments and will be ran in "intercative" mode
- Or the program is ran with arguments for script mode.
  So far, the arguments for scripting mode are :
  - 1 to build and aggregate librispeech and TEDLIUM
  - 2 To build librispeech
  - 3 To build TEDLIUM
  
  ==> to build only TEDLIUM --> ./dataset_preparation.sh 3
