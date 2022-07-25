FROM ubuntu:focal

# Generic packages
RUN apt update && DEBIAN_FRONTEND="noninteractive" apt install -y \
  cmake \
  curl \
  git \
  libboost-filesystem-dev \
  libboost-program-options-dev \
  libboost-system-dev \
  libboost-test-dev \
  python3-pip \
  software-properties-common \
  unzip \
  wget

# Python dependencies
RUN pip3 install psutil

# CVC4
RUN curl --silent "https://api.github.com/repos/CVC4/CVC4/releases/latest" | grep browser_download_url | grep -E 'linux' | cut -d '"' -f 4 | wget -qi - -O /usr/local/bin/cvc4 \
  && chmod a+x /usr/local/bin/cvc4

# Z3
RUN curl --silent "https://api.github.com/repos/Z3Prover/z3/releases/latest" | grep browser_download_url | grep -E 'glibc' | cut -d '"' -f 4 | wget -qi - -O z3.zip
RUN unzip -p z3.zip '*bin/z3' > /usr/local/bin/z3
RUN chmod a+x /usr/local/bin/z3

# Get .NET
RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
  && dpkg -i packages-microsoft-prod.deb \
  && apt update \
  && apt install -y apt-transport-https \
  && apt update \
  && apt install -y dotnet-sdk-3.1

# Get boogie
RUN dotnet tool install --global boogie --version 2.8.11
ENV PATH="${PATH}:/root/.dotnet/tools"

# Get and compile solc-verify
RUN git clone https://github.com/SRI-CSL/solidity.git \
  && cd solidity \
  && git checkout boogie \
  && mkdir -p build \
  && cd build \
  && cmake .. -DUSE_Z3=Off -DUSE_CVC4=Off \
  && make \
  && make install

# Set entrypoint
ENTRYPOINT ["solc-verify.py"]