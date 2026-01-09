FROM ubuntu
ENV TZ=Europe/Kiev
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install python3-pip -y
RUN apt-get update && apt-get install nmap vim apache2 nginx nano openssh-server -y