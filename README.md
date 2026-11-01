# SD-ARX: State-Dependent Addition-Rotation-XOR Networks

A closed-loop architecture for ARX primitives that replaces static rotation constants with state-dependent values, accelerating diffusion convergence.

## v1.0 (Community Edition) — DONE
- Scalar + SIMD reference implementations
- Benchmark harness & diffusion analytics (SAC/SADM)
- TestU01 BigCrush runs and logs
- Apache‑2.0 licensing; citation metadata

> **Status**: Community Edition (Apache‑2.0). Available under commercial terms—see **Enterprise Edition** below.

## Overview

SD-ARX introduces a new architectural principle for Addition-Rotation-XOR (ARX) networks: **entropy-dependent routing**. Rather than applying fixed rotation schedules, SD-ARX derives rotation magnitudes dynamically from the evolving internal state, creating a feedback mechanism that eliminates geometric dead zones and dramatically accelerates diffusion.

This repository contains the reference implementation instantiated as **SD-ChaCha8**, an 8-round PRNG demonstrating the SD-ARX principle.

## The SD-ARX Architecture

### Core Innovation

Traditional ARX designs use static rotation constants:
```
d[i+1] = (d[i] XOR a[i+1]) <<< R_static
```

SD-ARX couples rotation to state entropy:
```
r = R(state)                              // Derive rotation from state
d[i+1] = (d[i] XOR a[i+1]) <<< r         // Apply state-dependent rotation
```

### Architectural Advantages

- **Eliminates dead zones**: Static schedules create geometric isolation; state-dependent rotations eliminate fixed unreachable positions
- **Accelerates diffusion**: ~14.3% improvement in first-pass Hamming weight diffusion
- **Maintains bijectivity**: Proven invertible when R depends only on unchanged state words
- **Generalizable**: Applies to any ARX primitive (ChaCha, Salsa20, NORX, BLAKE)

## Performance (Apple M3, ARM64)

| Generator | Cycles/Byte | vs ChaCha20 | SAC Convergence |
|-----------|-------------|-------------|-----------------|
| **SD-ChaCha8 Barrett** | **1.681** | **1.67x faster** | **2 double-rounds** |
| SD-ChaCha8 (modulo) | 2.649 | 1.06x faster | 2 double-rounds |
| ChaCha20 | 2.810 | 1.00x (baseline) | 2 double-rounds |
| ChaCha12 | 2.077 | 1.35x faster | 3-4 double-rounds |
| ChaCha8 | 1.914 | 1.47x faster | Incomplete |

**Platform**: Apple M3 (ARM64), Clang -O3 -march=native, clock_gettime

## Statistical Validation

### TestU01 BigCrush
- **Status**: All 160 tests passed
- **Data processed**: ~10 TB per variant
- **Variants tested**: Original (modulo) and Barrett (optimized)
- Complete results in `/results`

### Additional Validation
- **Strict Avalanche Criterion**: Achieved by round 2 
- **Topological uniformity**: Vietoris-Rips persistent homology matches true-random baselines
- **Spectral statistics**: Eigenvalue spacing follows Wigner-Dyson GOE distribution

## When to Use SD-ChaCha8

### Use when:
- Pipeline requires ARX non-linearity to eliminate GF(2) hyperplane artifacts
- ChaCha20 is a throughput bottleneck
- Naively truncating to ChaCha8 degrades statistical quality
- SAC compliance needed at reduced round count

### Do NOT use when:
- Raw throughput is paramount (use xoshiro256++, PCG64 instead)
- Cryptographic security required (SD-ARX has data-dependent timing)
- Linear generators suffice for your application



## Building
```bash
# Scalar implementation
gcc -O3 -march=native sd_chacha8_barrett.c -o sd_chacha8

# With benchmarks
make benchmark

# Run full test suite
make test
```

## Usage Example
```c
#include "sd_chacha8.h"

// Initialize state
sd_chacha8_state state;
sd_chacha8_init(&state, key, nonce);

// Generate random bytes
uint8_t output[64];
sd_chacha8_generate(&state, output, 64);
```

## Repository Structure
```
/src/           - Core implementations (Barrett, original, SIMD)
/tests/         - TestU01, validation scripts, statistical tests
/benchmarks/    - Performance measurement tools
/analysis/      - Diffusion analysis, TDA, spectral statistics
/docs/          - Paper, supplementary materials
```

## Citation

If you use SD-ChaCha8 in your research, please cite:
```bibtex
@inproceedings{dsouza2026sdarx,
  author    = {D’Souza, M.},
  title     = {SD-ARX: A Closed-Loop Architecture for Accelerated Diffusion in ARX Networks, with SIMD-Compatible Implementations},
  booktitle = {2026 International Conference on Next-Gen Intelligent Computing and Applications (ICONICA)},
  publisher = {IEEE},
  year      = {2026},
  url       = {https://ieeexplore.ieee.org/document/11736705}
}
```

## Important Disclaimers

**Not for cryptographic use**: Data-dependent timing of dynamic rotations introduces side-channel vulnerabilities. SD-ARX is designed for **non-cryptographic** random number generation in simulation and stochastic optimization.

**Platform-specific performance**: Throughput values are measured on Apple M3 (ARM64). x86-64 performance may differ due to different instruction latencies and SIMD widths.

**Architectural niche**: SD-ChaCha8 targets ARX-committed pipelines. For throughput-critical workloads without ARX requirements, linear generators (xoshiro256++, PCG64) are significantly faster.

## License

## License
This project uses a dual-licensing model.

- **Community Edition** — Apache License 2.0 (see `LICENSE.md`)
- **Enterprise Edition** — commercial license (see `LICENSE-ENTERPRISE.md`)


## For Research Queries, Contact

**Meldon D'Souza**  
Department of Statistics and Data Science  
Christ (Deemed-to-be) University, Bengaluru, India  
Email: meldon.dsouza@mscsai.christuniversity.in

## Acknowledgments

Based on ChaCha20 by D. J. Bernstein. TestU01 validation framework by P. L'Ecuyer and R. Simard.

---

**Last updated**: August 2026  
**Status**: 2026 IEEE International Conference on Next-Gen Intelligent Computing and Applications, https://doi.org/10.1109/ICONICA70605.2026.11736705
