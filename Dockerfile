FROM node:10
ENV NODE_ENV "production"
ENV PORT 8079
EXPOSE 8079
RUN addgroup mygroup && adduser --disabled-password --gecos '' --ingroup mygroup myuser && mkdir -p /usr/src/app && chown -R myuser /usr/src/app

# install fault injection binaries
RUN apt-get update && apt-get install -y \
    make \
    gcc \
    python3 \
    python3-pip \
&& rm -rf /var/lib/apt/lists/*
COPY fault-injection /opt/fault-injection

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
