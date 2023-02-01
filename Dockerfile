FROM rocker/shiny

RUN apt-get update &&\
    apt-get install -y \
    libssl-dev \
    libxml2-dev \
    libgmp3-dev \
    libmpfr-dev \
    libgit2-dev &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*
RUN install2.r --error --deps TRUE --repos cran.rstudio.com remotes
RUN installGithub.r --deps TRUE --repos cran.rstudio.com \
    SwReliab/gof4srm \
    SwReliab/Rphsrm

COPY app.R /srv/shiny-server/app.R
COPY functions.R /srv/shiny-server/functions.R
