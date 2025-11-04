TARGET=wasm32-unknown-unknown
NAME=policy_wasm_demo
OUT=target/$(TARGET)/release/$(NAME).wasm

.PHONY: all build clean

all: build

build:
	rustup target add $(TARGET) >/dev/null 2>&1 || true
	cargo build --release --target $(TARGET)

clean:
	cargo clean

