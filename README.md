# Nervana's Deep Speech Implementation

With considerable help from the [Nervana's github page implementation of DeepSpeech 2](https://github.com/NervanaSystems/deepspeech), where their inspiration is drawn from the [arXiv paper](https://arxiv.org/abs/1512.02595).

### Install [Neon](https://github.com/NervanaSystems/neon)

I've spent quite a long time getting conda to install for python version 3. However, it appears that neon is only supported for python version 2. So, in the conda below, use Python 2.7.

```
conda create --name neon python=2.7 pip
conda install ipython
source activate neon
git clone https://github.com/NervanaSystems/neon.git
cd neon && make sysinstall
source deactivate && cd ..
```

### Get the weights

- If on a Mac, you may need to use `curl` or install `wget` (which can be done with `brew install wget --with-libressl`)
- Download the weights:

```
mkdir models && cd models
wget https://s3-us-west-1.amazonaws.com/nervana-modelzoo/Deep_Speech/Librispeech/librispeech_16_epochs.prm && cd ..
```

### Installing Deep Speech

- You'll need `cmake`; in order to do that. If you don't have it and you're on a Mac, just type in:
  `brew install cmake`

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

```
python evaluate.py --manifest val:$TOPDIR/librispeech/test-clean/test-manifest.csv --model_file $TOPDIR/model/librispeech_16_epochs.prm
```

Unfortunately, there might be some hiccups. Sometimes aeon is not installed. First, I installed the dependencies

```
brew tap homebrew/science
brew install opencv
brew install sox
```

There appears to be a problem with the aeon.git C++ compilation flags, so you'll need to adjust your `CFLAGS` with `export CFLAGS="-Wno-deprecated-declarations -std=c++11 -stdlib=libc++"`. If you've downloaded the latest release (0.2.7) of aeon, then you can fix `env.sh`, which I got from [this bug fix](https://github.com/NervanaSystems/neon/issues/375). And then, the actual aeon dataloader:

```
git clone https://github.com/NervanaSystems/aeon.git aeon
cd aeon
pip install -r requirements.txt
pip install numpy==1.11.1
mkdir -p build && cd $_ && cmake .. && pip install .
```



