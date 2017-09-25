# Nervana's Deep Speech Implementation

With considerable help from the [Nervana's github page implementation of DeepSpeech 2](https://github.com/NervanaSystems/deepspeech), where their inspiration is drawn from the [arXiv paper](https://arxiv.org/abs/1512.02595).

### Install [Neon](https://github.com/NervanaSystems/neon)

I've spent quite a long time getting conda to install for python version 3. However, it appears that the aeon version that neon uses is best supported for python version 2 (though they do have a more universal one on `rc1`). So, in the conda below, use Python 2.7.

```
conda create --name neon python=2.7 pip
source activate neon
conda install ipython
git clone https://github.com/NervanaSystems/neon.git
cd neon && make sysinstall
source deactivate && cd ..
```

If you carefully scour through the logs, you'll notice that aeon may *not* get installed, perhaps due to some C libraries. In this case, you may have to go back and manually install aeon. This is a headache, but I step through at the bottomo of this README.

### Get the weights

- If on a Mac, you may need to use `curl` or install `wget` (which can be done with `brew install wget --with-libressl`)
- If you're on Ubuntu and you don't have `wget`, then update your apt-get and install it via `apt-get update && apt-get install wget`.
- Download the weights:

```
mkdir models && cd models
wget https://s3-us-west-1.amazonaws.com/nervana-modelzoo/Deep_Speech/Librispeech/librispeech_16_epochs.prm && cd ..
```

### Installing Deep Speech

- You'll need `cmake`; in order to do that. If you don't have it, just type in:
  - `brew install cmake` for macs
  - `sudo apt-get install cmake` for ubuntu

Get the source code from Nervana's github page:

```
git clone https://github.com/NervanaSystems/deepspeech.git 
cd deepspeech
pip install -r requirements.txt
make
```

### Data ingestion

You'll need to download from Povey's openSLR.org:

```bash
mkdir librispeech && cd librispeech
wget http://www.openslr.org/resources/12/test-clean.tar.gz
tar xvzf test-clean.tar.gz --strip-components=1 && cd ..
```

In order to ingest the data, it's necessary to make a *manifest*. This is a file that tells you where all the files are. There's a python script in the `deepspeech` repository that creates the manifest, and it can be called from inside the `speech` folder. For example, if we want to create a manifest for the test data in librispeech, we would type in:

```shell
TOPDIR=$PWD
cd deepspeech/speech
python data/ingest_librispeech.py  $TOPDIR/librispeech/test-clean $TOPDIR/librispeech/test-clean/transcripts_dir  $TOPDIR/librispeech/test-clean/test-manifest.csv
```

The manifest is organized as follows:

| Audio file (e.g., `*.flac`) | Corresponding text transcript |
|---|---|
| `1089/134686/1089-134686-0000.flac` | `1089-134686-0000.txt` |
| `1089/134686/1089-134686-0001.flac` | `1089-134686-0001.txt` |
| `1089/134686/1089-134686-0002.flac` | `1089-134686-0002.txt` |

### Evaluate the manifest created

Now we can evaluate our manifest. If all goes well, the below command should work. 

`
python evaluate.py --manifest val:$TOPDIR/librispeech/test-clean/test-manifest.csv --model_file $TOPDIR/model/librispeech_16_epochs.prm
`

### Didn't Work?

Unfortunately, there might be some hiccups. I mentioned above that sometimes aeon is not installed with the version of neon. It just poops out, and you'd have to sift through the logs to notice. Or, in my case, it breaks down when I issue the evaluate command above. 

For aeon, you have to install the dependencies. On Mac, that's done by issuing the below:

```
brew tap homebrew/science
brew install opencv
brew install sox
```

On Linux, you need `clang`, `opencv`, `openssl`, and `sox`:

```
sudo apt-get install clang libsox-dev
sudo apt-get install libopencv-dev python-opencv
sudo apt-get install libcurl4-openssl-dev
```

Afterward, I tried cloning the most up to date version on the website. That didn't really end up working. If you parse through the error logs, you'll notice that aeon release version 0.2.7 is what you're looking for.  Download that release (0.2.7) of aeon, but since you're starting from scratch, you might not have the right standard libraries. You should fix `env.sh`, which I got from [this bug fix](https://github.com/NervanaSystems/neon/issues/375). 

```
wget https://github.com/NervanaSystems/aeon/archive/v0.2.7.zip
unzip v0.2.7.zip
cd aeon
pip install -r requirements.txt
pip install numpy==1.11.1
mkdir -p build && cd $_ && cmake .. 
```

The above is more of a manual way to install aeon. After install dependencies, you can really just do it by typing in:

`pip install git+https://github.com/NervanaSystems/aeon.git@v0.2.7`

If you're going from more recent versions of aeon, this amounts a problem with the aeon.git C++ compilation flags. The most recent repositories don't have an `env.sh` file, so you'll just need to adjust your `CFLAGS` with `export CFLAGS="-Wno-deprecated-declarations -std=c++11 -stdlib=libc++"`. Don't do this before your `cmake`, though. Do it when you're installing the actual package itself. 

Now, you can do:

`python setup.py install && cd ../..`

### Current Status

On Linux, I'd gotten this work on CPU only. Not bad, but it's very slow, and I'm evaluating on CER (character error rate). You should get something that looks like:

```
(neon) kni@44b9618b0ac4:/data/fs4/home/kni/magnolia/deepspeech/deepspeech/speech$ ./eval.sh
DISPLAY:neon:mklEngine.so not found; falling back to cpu backend
DISPLAY:neon:mklEngine.so not found; falling back to cpu backend
2017-09-25 21:07:56,789 - neon.backends - WARNING - deterministic_update and deterministic args are deprecated in favor of specifyin
g random seed
libdc1394 error: Failed to initialize libdc1394
2017-09-25 21:07:57,544 - neon.models.model - WARNING - Problems restoring existing RNG state: algorithm must be 'MT19937'
CER: 0.119200082566:   4%|██▌                                                                 | 3/81 [02:53<1:15:23, 58.00s/batches]
```

On Mac OSX, I'm facing a problem when I run my evaluation. I've submitted an issue ([number 56](https://github.com/NervanaSystems/deepspeech/issues/56) on Nervana's DeepSpeech git page.) The error message looks like:

```
python evalrun.py --manifest val:$TOPDIR/librispeech/test-clean/test-manifest.csv --model_file $TOPDIR/model/librispeech_16_epochs.prm
```

(The paths are correct; I checked.) The error message looks like:

```
DISPLAY:neon:mklEngine.so not found; falling back to cpu backend
DISPLAY:neon:mklEngine.so not found; falling back to cpu backend
2017-09-22 19:42:54,373 - neon.backends.nervanacpu - WARNING - Problems inferring BLAS info, CPU performance may be suboptimal
2017-09-22 19:42:54,374 - neon.backends - WARNING - deterministic_update and deterministic args are deprecated in favor of specifying random seed
2017-09-22 19:42:54,379 - neon.backends.nervanacpu - WARNING - Problems inferring BLAS info, CPU performance may be suboptimal
Loading model file: /Users/l41admin/Magnolia/deepspeech/model/librispeech_16_epochs.prm
formats: formats: formats: can't open input file `': No such file or directoryformats: can't open input file `': No such file or directorycan't open input file `': No such file or directory
Unable to readdecode_thread_pool exception: number of frames is negative
can't open input file `': No such file or directory


Unable to readUnable to readUnable to readdecode_thread_pool exception: number of frames is negative
decode_thread_pool exception: number of frames is negative
decode_thread_pool exception: number of frames is negative
```





