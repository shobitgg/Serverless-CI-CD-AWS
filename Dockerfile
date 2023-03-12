# Use a node 12 base image
FROM node:12-alpine

# Create the app directory
WORKDIR /usr/src/app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Start the app
COPY . .
ENTRYPOINT ["npm", "start"]
