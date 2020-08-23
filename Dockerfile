FROM ubuntu:focal-20200720

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

ENV GOPATH /go
ENV HELM_HOME /helm
ENV AZURE_CONFIG_DIR=/root/.azure
ENV HOME=/root

RUN apt-get update

RUN apt-get --assume-yes install software-properties-common dos2unix curl git jq

RUN mkdir /helm
RUN mkdir /helm/plugins

RUN add-apt-repository ppa:longsleep/golang-backports
RUN apt-get update

RUN apt-get --assume-yes install ca-certificates

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
# add required extensions
RUN az extension add --name azure-devops

RUN apt-get --assume-yes install golang-go
ENV PATH="/go/bin:${PATH}"
# @update to latest version: https://github.com/mozilla/sops/tags
#RUN go get -u go.mozilla.org/sops/v3 \
RUN mkdir -p $GOPATH/src/go.mozilla.org/sops/v3
RUN git clone https://github.com/jimmycuadra/sops $GOPATH/src/go.mozilla.org/sops/v3  \
  && echo "sops with age support checked out" \
  && cd $GOPATH/src/go.mozilla.org/sops/v3/cmd/sops \
  && git checkout age \
  && go install go.mozilla.org/sops/v3/cmd/sops \
  && sops --version
#  && go install github.com/jimmycuadra/sops/cmd/sops \


RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh
RUN ./get_helm.sh
RUN helm plugin install https://github.com/futuresimple/helm-secrets

RUN ln -sf /bin/bash /bin/sh

#RUN mkdir -p /home/devops
#RUN groupadd -r devops && useradd -d /home/devops --no-log-init -g devops devops
#RUN chown devops:devops /home/devops
#RUN chmod 777 /home/devops

RUN mkdir -p /work
#COPY *.sh /work/scripts/
#RUN dos2unix /work/scripts/*.sh
#RUN chmod 777 /work
#RUN chown -R devops:devops /work
WORKDIR /work

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl vim nano uuid-runtime

# @update: https://github.com/roboll/helmfile/releases
RUN  curl -fsSL -o helmfile https://github.com/roboll/helmfile/releases/download/v0.125.7/helmfile_linux_amd64 \
  && mv helmfile /bin/helmfile \
  && chmod +x /bin/helmfile

#RUN git clone https://filippo.io/age $GOPATH/src/age \
#  && cd $GOPATH/src/age \
#  && go build filippo.io/age/cmd/age

# RUN git clone https://filippo.io/age && cd age && go build -o . filippo.io/age/cmd/... && cp age /bin/age && cp age-keygen /bin/age-keygen && cd .. && rm age -R

# required for helmfile and "helm apply" and so on to work
RUN helm plugin install https://github.com/databus23/helm-diff

ENV USER_HOME_COPYSOURCE=/data/example_home_files
RUN mkdir -p /data/example_home_files
COPY README.md /data/example_home_files

RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu
    
# gcloud sdk
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get update && apt-get install google-cloud-sdk

COPY entrypoint.sh /work/entrypoint.sh
RUN chmod +x entrypoint.sh

#USER devops

ENTRYPOINT ["/work/entrypoint.sh"]
