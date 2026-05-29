# Lua ECS Benchmarks

This repository is dedicated to evaluating and comparing various Entity Component System (ECS) implementations in Lua/LuaJIT. Its primary purpose is exploratory: to provide a controlled environment for running benchmarks and observing performance characteristics across different libraries. This project does not include precomputed results, visualizations, or performance summaries. Users are expected to run the benchmarks locally to obtain relevant and current data.

If you need a benchmark that supports LuaJIT libs, here's the [link](https://github.com/napHiwka/lua-ecs-benchmarks).

## Quick Start

```bash
# 1. Download libraries
python bootstrap/main.py

# 2. Run benchmarks
luau bench/init.luau
```

See [`bootstrap/README.md`](bootstrap/README.md) and [`bench/README.md`](bench/README.md) for full details.

### Included libraries

* [ecr](https://github.com/centau/ecr)
* [jecs](https://github.com/Ukendio/jecs)
* [concord](https://github.com/Keyslam-Group/Concord)
* [ecs-lua](https://github.com/nidorx/ecs-lua)
* [evolved](https://github.com/BlackMATov/evolved.lua)
* [lovetoys](https://github.com/lovetoys/lovetoys)
* [rune](https://github.com/jamesstidard/rune)
* [tiny-ecs](https://github.com/bakpakin/tiny-ecs)
* [ecs-lib](https://github.com/liuhaopen/ecs.git)
* [alecs](https://github.com/pcornier/Alecs)

## Interpretation of Results

Benchmark results should be interpreted with caution. Using adapters introduces significant overhead when calling functions and so on, but even so, it’s sufficient for a simple comparison of libraries. Performance outcomes are highly sensitive to usage patterns, architectural decisions, and implementation details. A given ECS framework may perform poorly or exceptionally well depending on how it is applied.

Some libraries don't have a native query API. In such cases, adapters use a simple method of iterating through all entities and components - which negatively impacts performance. Therefore, it is important to consider not only performance results but also the library’s API itself.

## Results Evaluating

- Run benchmarks in your own environment under conditions that resemble your target use case (change in the Lua/Luau version can affect the results).
- Consider code structure, data access patterns, and system design alongside raw benchmark numbers.
- Avoid drawing conclusions from isolated metrics. 
- Treat results as indicative rather than definitive.
- Keep in mind the overhead costs associated with the benchmark and adapters.
