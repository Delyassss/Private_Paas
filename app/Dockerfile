# Stage 1: Build the application
FROM gcc:latest AS builder
WORKDIR /app
COPY a.cpp .
RUN g++ -o myapp a.cpp

# Stage 2: Run the application
FROM ubuntu:latest
WORKDIR /app
COPY --from=builder /app/myapp .
CMD ["./myapp"]
