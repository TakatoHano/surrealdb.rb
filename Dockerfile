FROM ruby:3.1.3-buster

RUN apt-get update -qq && \
    apt-get install -y sudo build-essential bash && \
    apt-get clean

ARG host_uid
ARG host_gid
ARG user
ARG group


RUN groupadd -f -r --gid ${host_gid} ${group}  && \
    useradd -m -r --uid ${host_uid} --gid ${host_gid} ${user} && \
    usermod -aG ${group} ${user} && \
    echo "%${user}     ALL=(ALL)    NOPASSWD:ALL" >> /etc/sudoers.d/${group}-group    

RUN mkdir /workspace && chown ${group}:${user} /workspace -R

USER ${host_uid}
WORKDIR /workspace
COPY lib /workspace/lib
COPY surrealdb.gemspec /workspace/surrealdb.gemspec
COPY Gemfile /workspace/Gemfile
COPY Gemfile.lock /workspace/Gemfile.lock

RUN bundle install

SHELL ["/bin/bash", "-c"] 
