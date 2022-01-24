iFROM buildpack-deps:xenial-scm
ARG KAIROS_APT_AUTH
ARG KAIROS_BUILDLIB_VERSION=1.0.112

SHELL ["/bin/bash", "-e", "-c"]

RUN echo 'APT { Get { Assume-Yes "true"; }; };' > /etc/apt/apt.conf.d/99assume-yes

RUN sed -i 's|http://arch|http://us-east-1.ec2.arch|g' /etc/apt/sources.list

# install some apt tools
RUN apt-get update && apt-get install software-properties-common python-software-properties \
    apt-transport-https \
    && apt-get clean autoclean && apt-get autoremove --yes && rm -rf /var/lib/apt/lists/*
