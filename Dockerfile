FROM ubuntu:focal-20210416

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

ENV GOPATH /go
ENV HELM_HOME /helm
ENV AZURE_CONFIG_DIR=/root/.azure
ENV HOME=/root

RUN apt-get update

RUN apt-get --assume-yes install software-properties-common dos2unix curl git jq bash-completion

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
RUN mkdir -p $GOPATH/src/go.mozilla.org/sops/v3
RUN git clone https://github.com/mozilla/sops $GOPATH/src/go.mozilla.org/sops/v3  \
  && cd $GOPATH/src/go.mozilla.org/sops/v3/cmd/sops \
  && git checkout v3.7.1 \
  && go install go.mozilla.org/sops/v3/cmd/sops \
  && sops --version

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh
RUN ./get_helm.sh
# @update to latest version: https://github.com/jkroepke/helm-secrets/tags
RUN curl -fsSL -o helm-secrets.tar.gz https://github.com/jkroepke/helm-secrets/releases/download/v3.7.0/helm-secrets.tar.gz \
    && tar -xvf helm-secrets.tar.gz \
    && helm plugin install helm-secrets \
    && rm helm-secrets.tar.gz \
    && rm helm-secrets -R

RUN ln -sf /bin/bash /bin/sh

RUN mkdir -p /work
COPY *.sh /work/scripts/
RUN dos2unix /work/scripts/*.sh
RUN chmod 777 /work
RUN chown -R root:root /work
WORKDIR /work

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
# we cannot use gnupg2 since it does not work to decrypt the secrets
# RUN apt-get install -y gnupg2
RUN apt-get install -y kubectl vim nano uuid-runtime
RUN kubectl completion bash >/etc/bash_completion.d/kubectl

RUN mkdir -p /root/.gnupg

# @update: https://github.com/roboll/helmfile/releases
RUN  curl -fsSL -o helmfile https://github.com/roboll/helmfile/releases/download/v0.139.7/helmfile_linux_amd64 \
  && mv helmfile /bin/helmfile \
  && chmod +x /bin/helmfile

#RUN git clone https://filippo.io/age $GOPATH/src/age \
#  && cd $GOPATH/src/age \
#  && go build filippo.io/age/cmd/age

# We dont use age for now (did not work at the time we tested it, but can be a better replacement for pgp)
#RUN git clone https://filippo.io/age && cd age && go build -o . filippo.io/age/cmd/... && cp age /bin/age && cp age-keygen /bin/age-keygen && cd .. && rm age -R

# required for helmfile and "helm apply" and so on to work
# @update https://github.com/databus23/helm-diff
RUN git clone https://github.com/databus23/helm-diff \
  && cd helm-diff \
  && git checkout v3.1.3 \
  && helm plugin install .

ARG USER_HOME_COPYSOURCE=/data/example_home_files
COPY README.md /data/example_home_files
# all normal files will have 600, all .sh files will have 700 access rights
RUN cp /data/example_home_files /root/ -R -f

# gcloud sdk
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get update && apt-get install -y google-cloud-sdk && apt-get clean

COPY entrypoint.sh /work/entrypoint.sh
RUN chmod +x entrypoint.sh

USER root

ENTRYPOINT ["/work/entrypoint.sh"]
