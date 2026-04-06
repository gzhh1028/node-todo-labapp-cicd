FROM node:12-alpine

WORKDIR /app
COPY . .
RUN npm install --registry=https://registry.npmmirror.com
RUN npm run test
EXPOSE 8000
CMD ["node","app.js"]
