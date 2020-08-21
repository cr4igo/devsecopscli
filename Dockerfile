FROM ubuntu:focal-20200720

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

ENV GOPATH /go
ENV HELM_HOME /helm
ENV AZURE_CONFIG_DIR=/home/devops/.azure
ENV HOME=/home/devops

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

RUN mkdir -p /home/devops
RUN groupadd -r devops && useradd -d /home/devops --no-log-init -g devops devops
RUN chown devops:devops /home/devops
RUN chmod 777 /home/devops

RUN mkdir -p /work
COPY *.sh /work/scripts/
RUN dos2unix /work/scripts/*.sh
RUN chmod 777 /work
RUN chown -R devops:devops /work
WORKDIR /work

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl vim nano uuid-runtime

RUN mkdir -p /home/devops/.gnupg
RUN chown -R devops:devops /home/devops/

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

USER devops

