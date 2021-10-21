FROM ubuntu:focal
LABEL maintainer="TheSanty <sudhiryadav.igi@gmail.com>"
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /tmp

RUN apt-get -yqq update \
    && apt-get install --no-install-recommends -yqq adb autoconf automake axel bc bison build-essential ccache clang cmake curl expat fastboot flex g++ g++-multilib gawk gcc gcc-multilib git gnupg gperf htop imagemagick locales libncurses5 lib32ncurses5-dev lib32z1-dev libtinfo5 libc6-dev libcap-dev libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev libsdl1.2-dev libssl-dev libtool libxml-simple-perl libxml2 libxml2-utils lsb-core lzip '^lzma.*' lzop maven nano ncftp ncurses-dev openssh-server patch patchelf pkg-config pngcrush pngquant python2.7 python3-apt python-all-dev python re2c rclone rsync schedtool squashfs-tools subversion sudo tar texinfo tmate tzdata unzip w3m wget xsltproc zip zlib1g-dev zram-config zstd \
    && curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo \
    && chmod a+rx /usr/local/bin/repo \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen \
    && TZ=Asia/Kolkata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN axel -a -n 10 https://ftp.gnu.org/gnu/make/make-4.3.tar.gz \
    && tar xvzf make-4.3.tar.gz && cd make-4.3 && ./configure \
    && bash ./build.sh \
    && sudo install ./make /usr/bin/make
    
RUN git clone https://github.com/ninja-build/ninja.git \
    && cd ninja && git reset --hard 8fa4d05 && ./configure.py --bootstrap \
    && sudo install ./ninja /usr/bin/ninja

RUN git clone https://github.com/google/kati.git \
    && cd kati && git reset --hard e1d6ee2 && make ckati \
    && sudo install ./ckati /usr/bin/ckati

RUN axel -a -n 10 https://github.com/facebook/zstd/releases/download/v1.5.0/zstd-1.5.0.tar.gz \
    && tar xvzf zstd-1.5.0.tar.gz && cd zstd-1.5.0 \
    && sudo make install

RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip \
    && unzip rclone-current-linux-amd64.zip && cd rclone-*-linux-amd64 \
    && sudo cp rclone /usr/bin/ && sudo chown root:root /usr/bin/rclone \
    && sudo chmod 755 /usr/bin/rclone

VOLUME ["/tmp/ccache", "/tmp/rom"]
ENTRYPOINT ["/bin/bash"]
