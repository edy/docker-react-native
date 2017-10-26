FROM library/ubuntu:16.04

# https://github.com/facebook/react-native/blob/8c7b32d5f1da34613628b4b8e0474bc1e185a618/ContainerShip/Dockerfile.android-base

# set default build arguments
ARG ANDROID_VERSION=25.2.3
ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 6.10.1

# set default environment variables
ENV ADB_INSTALL_TIMEOUT=10
ENV PATH=${PATH}:/opt/buck/bin/
ENV ANDROID_HOME=/opt/android
ENV ANDROID_SDK_HOME=${ANDROID_HOME}
ENV PATH=${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

# install system dependencies
RUN apt-get update -y && \
	apt-get install -y \
		autoconf \
		automake \
		expect \
		curl \
		g++ \
		gcc \
		git \
		libqt5widgets5 \
		lib32z1 \
		lib32stdc++6 \
		make \
		maven \
		openjdk-8-jdk \
		python-dev \
		python3-dev \
		qml-module-qtquick-controls \
		qtdeclarative5-dev \
		unzip \
		xz-utils \
	&& \
	rm -rf /var/lib/apt/lists/* && \
	apt-get autoremove -y && \
	apt-get clean

# install nodejs
# https://github.com/nodejs/docker-node/blob/a5141d841167d109bcad542c9fb636607dabc8b1/6.10/Dockerfile
# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
	&& for key in \
		9554F04D7259F04124DE6B476D5A82AC7E37093B \
		94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
		FD3A5288F042B6850C66B31F09FE44734EB7990E \
		71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
		DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
		B9AE9905FFD7803F25714661B63B535A4C206CA9 \
		C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
		56730D5401028683275BD23C23EFEFE93C4CFFFE \
	; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done && \
	curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
	&& curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
	&& gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
	&& grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
	&& tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr --strip-components=1 \
	&& rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
	&& ln -s /usr/bin/node /usr/bin/nodejs

# configure npm
RUN npm config set spin=false
RUN npm config set progress=false

RUN npm install -g react-native-cli

# download and unpack android
RUN mkdir -p /opt/android && mkdir -p /opt/tools
WORKDIR /opt/android
RUN curl --silent https://dl.google.com/android/repository/tools_r$ANDROID_VERSION-linux.zip > android.zip && \
	unzip android.zip && \
	rm android.zip

# copy tools folder
COPY tools/android-accept-licenses.sh /opt/tools/android-accept-licenses.sh
ENV PATH ${PATH}:/opt/tools

RUN mkdir -p $ANDROID_HOME/licenses/ \
	&& echo "d56f5187479451eabf01fb78af6dfcb131a6481e" > $ANDROID_HOME/licenses/android-sdk-license \
	&& echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

# sdk
RUN /opt/tools/android-accept-licenses.sh "$ANDROID_HOME/tools/bin/sdkmanager \
	tools \
	\"platform-tools\" \
	\"build-tools;23.0.1\" \
	\"build-tools;23.0.3\" \
	\"build-tools;25.0.1\" \
	\"build-tools;25.0.2\" \
	\"platforms;android-23\" \
	\"platforms;android-25\" \
	\"extras;android;m2repository\" \
	\"extras;google;m2repository\" \
	\"add-ons;addon-google_apis-google-24\" \
	\"extras;google;google_play_services\"" \
	&& $ANDROID_HOME/tools/bin/sdkmanager --update

VOLUME ["/app"]
WORKDIR /app
