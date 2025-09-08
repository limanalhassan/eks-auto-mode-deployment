# Hello Net

A basic Go program that responds to requests with an environment variable templated into the response.

# Building and Running

## Locally

1. [Install Go](https://golang.org/doc/install)

1. Build and/or run

   ```
   go build main.go
   ./main
   ```

   or

   ```
   go run main.go
   ```

## With Docker

   ```
   docker build -t hello-world .
   docker run -e "ENV=production" --rm -p 8080:8080 hello-world
   ```

# Interacting

Visit `localhost:8080/hello` to see the response.

For example:
```
Hello! I am running in production
```
