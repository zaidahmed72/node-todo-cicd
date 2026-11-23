FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY app.js ./
COPY views ./views
USER node
EXPOSE 8000
CMD ["node", "app.js"]
