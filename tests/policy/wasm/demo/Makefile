TARGET=wasm32-unknown-unknown
NAME=policy_wasm_demo
OUT=target/$(TARGET)/release/$(NAME).wasm

.PHONY: all build clean

all: build

build:
	command -v rustup >/dev/null
	rustup target add $(TARGET)
	cargo build --release --target $(TARGET)
	@test -f $(OUT)

clean:
	cargo clean
