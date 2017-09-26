FROM ubuntu:16.04
MAINTAINER Karl Ni <karl1980@gmail.com>

# Install Python (Taken from https://hub.docker.com/r/sgoblin/python3.5/)
RUN sed -i 's/archive.ubuntu.com/mirror.us.leaseweb.net/' /etc/apt/sources.list \
    && sed -i 's/deb-src/#deb-src/' /etc/apt/sources.list \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    build-essential \
    ca-certificates \
    gcc \
    git \
    libpq-dev \
    make \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    aria2 \
    && apt-get autoremove -y \
    && apt-get clean

# If you want to use Python 2.7, you're going to have to install older versions of iPython.
RUN pip3 install --upgrade pip && pip install ipython && \
    apt-get install -y python-pip && \
    pip install --upgrade pip && pip install ipython==5.0 && \
    pip3 install virtualenv && pip install virtualenv 

# Install Neon
RUN cd /root/ && apt-get install -y cmake && \
    git clone https://github.com/NervanaSystems/neon.git && \
    cd neon && make sysinstall && cd ..
    

# Install Aeon
RUN cd /root && apt-get install -y wget zip && \
    wget https://github.com/NervanaSystems/aeon/archive/v0.2.7.zip && \
    unzip v0.2.7.zip && \
    cd aeon-0.2.7 && \
    pip install -r requirements.txt && \
    apt-get install -y clang libsox-dev && \
    apt-get install -y libopencv-dev python-opencv && \
    apt-get install -y libcurl4-openssl-dev && \
    python setup.py install && \
    mv ../v0.2.7.zip .

# Install Deep Speech
RUN cd /root && git clone https://github.com/NervanaSystems/deepspeech.git && \
    cd deepspeech && pip install -r requirements.txt && \
    make

