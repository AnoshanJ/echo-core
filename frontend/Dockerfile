FROM node:20-alpine AS build
WORKDIR /src
RUN corepack enable && corepack prepare pnpm@9.12.3 --activate
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
ARG CORE_COMMIT=unknown
ENV CORE_COMMIT=$CORE_COMMIT
RUN pnpm build && pnpm build:demo

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/demo-dist /usr/share/nginx/html
