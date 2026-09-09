FROM golang:1.26-alpine AS build
ARG VERSION=dev
ARG COMMIT=none
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build \
      -ldflags "-s -w -X github.com/AnoshanJ/echo-core/backend/app.Version=${VERSION} -X github.com/AnoshanJ/echo-core/backend/app.Commit=${COMMIT}" \
      -o /out/echo-core .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/echo-core /echo-core
EXPOSE 8080
ENTRYPOINT ["/echo-core"]
