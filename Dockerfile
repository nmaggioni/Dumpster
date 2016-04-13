FROM node:5.10.1

# Create app directory
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Install app dependencies
COPY package.json /usr/src/app/
COPY bower.json /usr/src/app/
COPY .bowerrc /usr/src/app/
RUN echo '{ "allow_root": true }' > /root/.bowerrc
RUN npm install
RUN npm run-script bower

# Bundle app source
COPY . /usr/src/app

EXPOSE 9980

CMD [ "npm", "start" ]
