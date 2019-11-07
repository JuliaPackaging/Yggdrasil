FROM ubuntu:16.04

# Install necessary tools
RUN apt update -y && apt install -y \
        ca-certificates \
        curl \
        jq \
        git \
        iputils-ping \
        libcurl3 \
        libicu55 \
        libunwind8 \
        netcat

# We'll be doing all our work inside `/azp`
WORKDIR /azp

# Download and install docker frontend
RUN curl -L 'https://download.docker.com/linux/static/stable/x86_64/docker-19.03.4.tgz' | tar zxv && \
    mv docker/docker /usr/bin/docker && \
    rm -rf docker

# Copy in our default start script
COPY ./start.sh .
RUN chmod +x start.sh
CMD ["./start.sh"]
