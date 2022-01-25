FROM buildpack-deps:xenial-scm

ENV POSTGIS_VERSION 2.4
ENV PG_MAJOR 10

SHELL ["/bin/bash", "-e", "-c"]

RUN echo 'APT { Get { Assume-Yes "true"; }; };' > /etc/apt/apt.conf.d/99assume-yes

RUN sed -i 's|http://arch|http://us-east-1.ec2.arch|g' /etc/apt/sources.list

# install some apt tools
RUN apt-get update && apt-get install software-properties-common python-software-properties \
    apt-transport-https gosu \
    && apt-get clean autoclean && apt-get autoremove --yes && rm -rf /var/lib/apt/lists/*

# install and configure postgres and postgis
RUN add-apt-repository ppa:ubuntugis/ppa && apt-get update
RUN add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" \
    && wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt update \
    && apt-get install postgresql-10 postgresql-10-postgis-2.4 \
    && apt-get clean autoclean && apt-get autoremove --yes && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
COPY ./update-postgis.sh /usr/local/bin
RUN ln -s /usr/lib/postgresql/10/bin/initdb /usr/local/bin
# these portions are borrowed from


###############################################################################
#  From https://github.com/docker-library/postgres/blob/a83005b407ee6d810413500d8a041c957fb10cf0/13/alpine/Dockerfile
###############################################################################


ENV PGDATA /var/lib/postgresql/data
ENV PATH /usr/lib/postgresql/10/bin:$PATH
ENV LOCALE en_US.UTF-8

# this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"
VOLUME /var/lib/postgresql/data

# make the sample config easier to munge (and "correct by default")
RUN set -eux; \
	dpkg-divert --add --rename --divert "/usr/share/postgresql/postgresql.conf.sample.dpkg" "/usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample"; \
	cp -v /usr/share/postgresql/postgresql.conf.sample.dpkg /usr/share/postgresql/postgresql.conf.sample; \
	ln -sv ../postgresql.conf.sample "/usr/share/postgresql/$PG_MAJOR/"; \
	sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample; \
	grep -F "listen_addresses = '*'" /usr/share/postgresql/postgresql.conf.sample

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# We set the default STOPSIGNAL to SIGINT, which corresponds to what PostgreSQL
# calls "Fast Shutdown mode" wherein new connections are disallowed and any
# in-progress transactions are aborted, allowing PostgreSQL to stop cleanly and
# flush tables to disk, which is the best compromise available to avoid data
# corruption.
#
# Users who know their applications do not keep open long-lived idle connections
# may way to use a value of SIGTERM instead, which corresponds to "Smart
# Shutdown mode" in which any existing sessions are allowed to finish and the
# server stops when all sessions are terminated.
#
# See https://www.postgresql.org/docs/12/server-shutdown.html for more details
# about available PostgreSQL server shutdown signals.
#
# See also https://www.postgresql.org/docs/12/server-start.html for further
# justification of this as the default value, namely that the example (and
# shipped) systemd service files use the "Fast Shutdown mode" for service
# termination.
#
STOPSIGNAL SIGINT
#
# An additional setting that is recommended for all users regardless of this
# value is the runtime "--stop-timeout" (or your orchestrator/runtime's
# equivalent) for controlling how long to wait between sending the defined
# STOPSIGNAL and sending SIGKILL (which is likely to cause data corruption).
#
# The default in most runtimes (such as Docker) is 10 seconds, and the
# documentation at https://www.postgresql.org/docs/12/server-start.html notes
# that even 90 seconds may not be long enough in many instances.

EXPOSE 5432
CMD ["postgres"]
