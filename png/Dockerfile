FROM ubuntu:16.04

RUN apt-get update \
  && apt-get install -y wget \
  apt-transport-https \ 
  curl \
  && wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb \
  && dpkg -i packages-microsoft-prod.deb \
  # && curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
  # && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
  # && sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-xenial-prod xenial main" > /etc/apt/sources.list.d/dotnetdev.list' \
  && apt-get update \
  && apt-get install -y  \
  dotnet-sdk-2.1 \
  libgdiplus \
  && cd /usr/lib \
  && ln -s libgdiplus.so gdiplus.dll \
  && mkdir /root/dotnet \
  && cd /root/dotnet 
RUN apt-get -y install ttf-mscorefonts-installer \
  fontconfig 

RUN mkdir -p /usr/share/font/winFonts
WORKDIR /root/dotnet
COPY bin/Debug/netcoreapp2.1/publish /root/dotnet
COPY simhei.ttf /usr/share/font/winFonts/simhei.ttf
COPY simkai.ttf /usr/share/font/winFonts/simkai.ttf
COPY simsun.ttc /usr/share/font/winFonts/simsun.ttc
RUN cd /usr/share/font/winFonts \
  && mkfontscale \
  && mkfontdir \
  && fc-cache -fv
EXPOSE 14000/tcp
ENTRYPOINT dotnet /root/dotnet/MyPng.dll