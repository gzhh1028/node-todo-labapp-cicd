FROM docker.mirrors.ustc.edu.cn/library/node:12-alpine
WORKDIR app
COPY . .
RUN npm install
RUN npm run test
EXPOSE 8000
CMD ["node","app.js"]
