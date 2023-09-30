# Install dependencies and compile to a binary
FROM --platform=linux/arm64 golang:1.19-alpine as builder

WORKDIR /app

COPY go.sum go.mod ./
RUN go mod download

COPY . .

ENV GIN_MODE=release
# Define the target architecture so it can still be deployed to an x86 machine if compiled on an ARM machine
ENV GOOS=linux GOARCH=arm64
RUN go build -o /bin/safety-beacon-api .

# Step 2: build a small image that runs the binary
FROM --platform=linux/arm64 alpine:3.14

####
## To ensure the application doesn't run as root, we
## create a new user and group that it will run as.
####
RUN addgroup safety-beacon-api-user && adduser -D -G safety-beacon-api-user safety-beacon-api-user

# copy static executable and change the owner to be the user that will run the application
COPY --chown=safety-beacon-api-user:safety-beacon-api-user --from=builder /bin/safety-beacon-api /bin/safety-beacon-api

USER safety-beacon-api-user:safety-beacon-api-user

EXPOSE 8080

CMD ["/bin/safety-beacon-api"]
