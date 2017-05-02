# Create_Speech_Dataset

# Purpose:
This scripts fetches open datasets of speech and transcription and aggregates them into a large metaset hopefully suitable for machine learning.

# Requirements:
- ffmpeg<br />
- parallel (O. Tange (2011): GNU Parallel - The Command-Line Power Tool ;login: The USENIX Magazine, February 2011:42-47.) <br />

# Special notes:
1. I've used parallel (and sem) to spawn nproc $(nproc) ffmpeg (the number of cores in the machine).  Machine might be less responsive, and this leads to second note.... the more cores you have, the more it is important that you mount dataset on a separate drive.<br />
2. I mount a partition from another physical hard drive as the dataset folder, and recommend you do the same, in order to avoid having plenty of simultaneous read/write on the same drive.  On the one hand, this makes things much faster, on the other hand if you don't, this is really bad for your drive.

# Usage
Read the source, comment the parts you don't need all at the end, run script.
