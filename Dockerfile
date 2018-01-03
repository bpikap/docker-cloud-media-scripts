####################
# BASE IMAGE
####################
FROM ubuntu:16.04

MAINTAINER prc2k10@googlemail.com <prc2k10@googlemail.com>


####################
# INSTALLATIONS
####################
RUN apt-get update && apt-get install -y \
    curl \
    fuse \
    unionfs-fuse \
    bc \
    unzip \
    wget

RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates && apt-get install -y openssl
RUN sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf

# S6 overlay
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_KEEP_ENV=1

RUN \
    OVERLAY_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]') && \
    curl -o \
    /tmp/s6-overlay.tar.gz -L \
    "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" && \
    tar xfz \
    /tmp/s6-overlay.tar.gz -C /


####################
# ENVIRONMENT VARIABLES
####################
# Encryption
ENV ENCRYPT_MEDIA "1"

ENV READ_ONLY "1"

# Rclone
ENV BUFFER_SIZE "512M"
ENV CHECKERS "16"
ENV RCLONE_CLOUD_ENDPOINT "gd-crypt:"
ENV RCLONE_LOCAL_ENDPOINT "local-crypt:"
ENC RCLONE_CACHE_ENDPOINT "gd-cache:"

# Rclone Cache Settings
ENV CACHE_CHUNK_SIZE "5M"
ENV CACHE_TOTAL_CHUNK_SIZE "10G"
ENV CACHE_INFO_AGE "6h"
ENV CACHE_WORKERS "4"

# Time format
ENV DATE_FORMAT "+%F@%T"

# Local files removal
ENV REMOVE_LOCAL_FILES_BASED_ON "space"
ENV REMOVE_LOCAL_FILES_WHEN_SPACE_EXCEEDS_GB "100"
ENV FREEUP_ATLEAST_GB "80"
ENV REMOVE_LOCAL_FILES_AFTER_DAYS "30"

####################
# SCRIPTS
####################
COPY setup/* /usr/bin/

COPY install.sh /

COPY scripts/* /usr/bin/

RUN chmod a+x /install.sh
RUN sh /install.sh
RUN chmod a+x /usr/bin/*

COPY root /

# Create abc user
RUN groupmod -g 1000 users && \
	useradd -u 911 -U -d / -s /bin/false abc && \
	usermod -G users abc

####################
# VOLUMES
####################
# Define mountable directories.
VOLUME /config /cloud-encrypt /cloud-decrypt /local-decrypt /local-media /chunks /log

RUN chmod -R 777 /log

####################
# WORKING DIRECTORY
####################
WORKDIR /


####################
# ENTRYPOINT
####################
ENTRYPOINT ["/init"]
