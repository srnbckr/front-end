FROM node:10
ENV NODE_ENV "production"
ENV PORT 8079
ENV STRESS_VERSION=0.09.57                                                                                                                                                                                         
ENV CPULIMIT_VERSION=0.2
EXPOSE 8079
RUN addgroup mygroup && adduser --disabled-password --gecos '' --ingroup mygroup myuser && mkdir -p /usr/src/app && chown -R myuser /usr/src/app

# install fault injection binaries
RUN apt-get update && apt-get install -y \
    make \
    gcc \
    python3 \
    python3-pip \
    iproute \
    iproute2 \
    libcap2-bin \
&& rm -rf /var/lib/apt/lists/*
COPY fault-injection /opt/fault-injection

WORKDIR /opt/fault-injection/cpu
ADD https://github.com/ColinIanKing/stress-ng/archive/V${STRESS_VERSION}.tar.gz .                                                                                                                                  
ADD https://github.com/opsengine/cpulimit/archive/v${CPULIMIT_VERSION}.tar.gz .                                                                                                                                    

RUN tar -xf V${STRESS_VERSION}.tar.gz && mv stress-ng-${STRESS_VERSION} stress-ng && \
    tar -xf v${CPULIMIT_VERSION}.tar.gz && mv cpulimit-${CPULIMIT_VERSION} cpulimit && \
    rm *.tar.gz

# make c projects
WORKDIR /opt/fault-injection/cpu/stress-ng
RUN STATIC=1 make

WORKDIR /opt/fault-injection/cpu/cpulimit
RUN make

# install tcconfig
RUN pip3 install tcconfig

# compile memory alloc anomalies
WORKDIR /opt/fault-injection/mem_alloc
RUN make clean && make

# Prepare app directory
WORKDIR /usr/src/app
COPY package.json /usr/src/app/
COPY yarn.lock /usr/src/app/
RUN chown myuser /usr/src/app/yarn.lock

USER myuser
RUN yarn install

COPY . /usr/src/app

# Start the app
CMD ["/usr/local/bin/npm", "start"]
