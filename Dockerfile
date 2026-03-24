FROM node:18-alpine

# Dépendances système
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-numpy \
    freetype-dev \
    libpng-dev \
    jpeg-dev \
    zlib-dev \
    gcc \
    g++ \
    make \
    musl-dev \
    tzdata

RUN ln -sf /usr/bin/python3 /usr/bin/python

RUN pip3 install --break-system-packages --no-cache-dir \
    matplotlib \
    reportlab \
    tzdata

WORKDIR /app

COPY package*.json ./

# ✅ npm install au lieu de npm ci → pas de problème de lock file
RUN npm cache clean --force && npm install --omit=dev
COPY . .

EXPOSE 3000

# ✅ Production : node (pas nodemon)
CMD ["node", "server.js"]