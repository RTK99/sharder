FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y ca-certificates gcc openssl libssl-dev libc6-dev curl pkg-config

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --verbose --default-toolchain nightly

RUN USER=root $HOME/.cargo/bin/cargo new --bin sharder
WORKDIR /sharder

COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

RUN RUST_LOG=error $HOME/.cargo/bin/cargo build --release
RUN rm ./target/release/dabbot-sharder
RUN rm ./src/*.rs

COPY ./src ./src

# **IMPORTANT**: Delete one of the dependencies' built artifacts. This will
# trigger a re-compilation. Otherwise, it will use a cached Hello, World!
# binary as our production binary.
RUN rm -rf target/release/build/regex-*

RUN RUST_LOG=error $HOME/.cargo/bin/cargo build --release

FROM ubuntu:latest

WORKDIR /

RUN apt-get update
RUN apt-get install ca-certificates openssl libssl-dev -y

COPY --from=0 /sharder/target/release/dabbot-sharder .

RUN touch /.env

ENTRYPOINT /dabbot-sharder
