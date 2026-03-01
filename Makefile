CC = gcc
CFLAGS = -O3 -march=native -Wall -Wextra -std=c11
LDFLAGS = -lm

# Detect platform
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Darwin)
    # macOS
    ifeq ($(UNAME_M),arm64)
        PLATFORM = ARM64_MACOS
        SIMD_FLAGS = -DARM_NEON
    else
        PLATFORM = X86_64_MACOS
        SIMD_FLAGS = -mavx2 -DAVX2
    endif
else ifeq ($(UNAME_S),Linux)
    # Linux
    ifeq ($(UNAME_M),aarch64)
        PLATFORM = ARM64_LINUX
        SIMD_FLAGS = -DARM_NEON
    else
        PLATFORM = X86_64_LINUX
        SIMD_FLAGS = -mavx2 -DAVX2
    endif
endif

# Directories
SRC_DIR = src
BUILD_DIR = build
BIN_DIR = bin
TEST_DIR = tests
BENCH_DIR = benchmarks

# Source files
CORE_SRC = $(SRC_DIR)/core/sd_chacha8_core.c
BARRETT_SRC = $(SRC_DIR)/barrett/sd_chacha8_barrett.c
MODULO_SRC = $(SRC_DIR)/modulo/sd_chacha8_modulo.c
SIMD_SRC = $(SRC_DIR)/simd/sd_chacha8_simd.c

# Object files
CORE_OBJ = $(BUILD_DIR)/sd_chacha8_core.o
BARRETT_OBJ = $(BUILD_DIR)/sd_chacha8_barrett.o
MODULO_OBJ = $(BUILD_DIR)/sd_chacha8_modulo.o
SIMD_OBJ = $(BUILD_DIR)/sd_chacha8_simd.o

# Targets
TARGETS = $(BIN_DIR)/sd_chacha8_barrett \
          $(BIN_DIR)/sd_chacha8_modulo \
          $(BIN_DIR)/sd_chacha8_simd \
          $(BIN_DIR)/benchmark \
          $(BIN_DIR)/test_sac \
          $(BIN_DIR)/test_bigcrush

.PHONY: all clean test benchmark validate help platform

all: setup $(TARGETS)
	@echo "Build complete for platform: $(PLATFORM)"
	@echo "Binaries in $(BIN_DIR)/"

setup:
	@mkdir -p $(BUILD_DIR) $(BIN_DIR)

# Barrett variant (recommended)
$(BIN_DIR)/sd_chacha8_barrett: $(BARRETT_SRC) | setup
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)
	@echo "Built: Barrett scalar implementation"

# Modulo variant (portable)
$(BIN_DIR)/sd_chacha8_modulo: $(MODULO_SRC) | setup
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)
	@echo "Built: Modulo-based implementation"

# SIMD variant
$(BIN_DIR)/sd_chacha8_simd: $(SIMD_SRC) | setup
	$(CC) $(CFLAGS) $(SIMD_FLAGS) -o $@ $< $(LDFLAGS)
	@echo "Built: SIMD implementation ($(PLATFORM))"

# Benchmark suite
$(BIN_DIR)/benchmark: $(BENCH_DIR)/benchmark.c $(BARRETT_SRC) $(MODULO_SRC) | setup
	$(CC) $(CFLAGS) -I$(SRC_DIR) -o $@ $^ $(LDFLAGS)
	@echo "Built: Benchmark suite"

# SAC test
$(BIN_DIR)/test_sac: $(TEST_DIR)/test_sac.c $(BARRETT_SRC) | setup
	$(CC) $(CFLAGS) -I$(SRC_DIR) -o $@ $^ $(LDFLAGS)
	@echo "Built: SAC validation test"

# BigCrush interface
$(BIN_DIR)/test_bigcrush: $(TEST_DIR)/test_bigcrush.c $(BARRETT_SRC) | setup
	$(CC) $(CFLAGS) -I$(SRC_DIR) -o $@ $^ $(LDFLAGS) -ltestu01 -lprobdist -lmylib
	@echo "Built: TestU01 BigCrush interface"

# Run benchmarks
benchmark: $(BIN_DIR)/benchmark
	@echo "Running throughput benchmarks..."
	@$(BIN_DIR)/benchmark

# Run validation suite
validate: $(BIN_DIR)/test_sac
	@echo "Running validation tests..."
	@$(BIN_DIR)/test_sac

# Run TestU01 BigCrush (requires TestU01 library)
bigcrush: $(BIN_DIR)/test_bigcrush
	@echo "Running TestU01 BigCrush battery..."
	@echo "WARNING: This will take several hours and generate ~10TB of data"
	@$(BIN_DIR)/test_bigcrush

# Run quick tests
test: validate
	@echo "Quick validation complete"

# Platform info
platform:
	@echo "Platform: $(PLATFORM)"
	@echo "Architecture: $(UNAME_M)"
	@echo "OS: $(UNAME_S)"
	@echo "Compiler: $(CC)"
	@echo "SIMD Flags: $(SIMD_FLAGS)"

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)
	@echo "Cleaned build artifacts"

# Help
help:
	@echo "SD-ARX Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all         - Build all implementations (default)"
	@echo "  benchmark   - Build and run throughput benchmarks"
	@echo "  validate    - Build and run validation tests"
	@echo "  test        - Run quick validation (alias for validate)"
	@echo "  bigcrush    - Run full TestU01 BigCrush battery (requires TestU01)"
	@echo "  platform    - Display platform information"
	@echo "  clean       - Remove build artifacts"
	@echo "  help        - Display this help message"
	@echo ""
	@echo "Individual targets:"
	@echo "  $(BIN_DIR)/sd_chacha8_barrett  - Barrett reduction variant (recommended)"
	@echo "  $(BIN_DIR)/sd_chacha8_modulo   - Direct modulo variant (portable)"
	@echo "  $(BIN_DIR)/sd_chacha8_simd     - SIMD-optimized variant"
	@echo ""
	@echo "Variables:"
	@echo "  CC          - Compiler (default: gcc)"
	@echo "  CFLAGS      - Compiler flags (default: -O3 -march=native -Wall -Wextra)"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Build everything"
	@echo "  make benchmark          # Run benchmarks"
	@echo "  make CC=clang           # Build with Clang"
	@echo "  make CFLAGS='-O2 -g'    # Custom optimization"
```

This Makefile provides:

1. **Cross-platform detection**: Automatically detects ARM64/x86-64 and macOS/Linux
2. **Multiple targets**: Barrett, modulo, SIMD variants plus testing tools
3. **Simple commands**: `make`, `make benchmark`, `make validate`, `make test`
4. **Help system**: `make help` shows all options
5. **Clean builds**: `make clean` removes artifacts
6. **Platform info**: `make platform` shows detected configuration

To use it, you'll need to create this directory structure:
```
SD-ChaCha8/
├── Makefile
├── src/
│   ├── core/
│   ├── barrett/
│   ├── modulo/
│   └── simd/
├── tests/
│   ├── test_sac.c
│   └── test_bigcrush.c
├── benchmarks/
│   └── benchmark.c
├── build/ (created by make)
└── bin/ (created by make)
