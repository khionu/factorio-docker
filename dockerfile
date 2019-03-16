# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
FROM phusion/baseimage:0.11

#####################
# PERSONAL ENV VARS #
#####################

ENV FACTORIO_PATH /opt/factorio
ENV FACTORIO_UPDATE_PATH /usr/local/bin/update_factorio.py
ENV FACTORIO_BIN_PATH $FACTORIO_PATH/bin/x64/factorio
ENV FACTORIO_INIT_PATH /usr/local/bin/factorio-init
ENV FACTORIO_BASHRC_PATH /root/.bashrc
ENV FACTORIO_INIT_DAEMON_DIR /etc/service/factorio-init

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

########################
# START PERSONAL STEPS #
########################

# System prep
COPY keys/public.key /tmp/public.key
RUN cat /tmp/public.key >> /root/.ssh/authorized_keys && rm -f /tmp/public.key

RUN apt update && apt upgrade -y

RUN apt install -y git wget curl python-pip
RUN pip install request

RUN rm -f /etc/service/sshd/down

# Setup factorio-updater
RUN curl https://raw.githubusercontent.com/narc0tiq/factorio-updater/master/update_factorio.py -o $FACTORIO_UPDATE_PATH
RUN chmod +x $FACTORIO_UPDATE_PATH

# Setup factorio-init
RUN mkdir -p $FACTORIO_INIT_PATH 
WORKDIR $FACTORIO_INIT_PATH
RUN git clone https://github.com/Bisa/factorio-init.git .
RUN chmod +x factorio
ADD config config
RUN sed -i s/SAVELOG=0/SAVELOG=1/ config
RUN sed -i s/UPDATE_EXPERIMENTAL=0/UPDATE_EXPERIMENTAL=1/ config
RUN echo "source /usr/local/bin/factorio-init/bash_autocomplete" >> $FACTORIO_BASHRC_PATH
RUN mkdir ${FACTORIO_INIT_DAEMON_DIR}
COPY service.run ${FACTORIO_INIT_DAEMON_DIR}/run
RUN chmod +x ${FACTORIO_INIT_DAEMON_DIR}/run

# Install Factorio
RUN ./factorio install

######################
# END PERSONAL STEPS #
######################

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
