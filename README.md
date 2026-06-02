# Lua ECS Benchmarks

This repository is dedicated to evaluating and comparing various Entity Component System (ECS) implementations in Luau. Its primary purpose is exploratory: to provide a controlled environment for running benchmarks and observing performance characteristics across different libraries. This project does not include precomputed results, visualizations, or performance summaries. Users are expected to run the benchmarks locally to obtain relevant and current data.

If you need a benchmark that supports LuaJIT libs, here's the [link](https://github.com/napHiwka/lua-ecs-benchmarks).

## Quick Start

> [!NOTE]
> It’s worth noting that Luau includes the `--codegen` and `-O2` optimization flags, which can significantly alter test results. They're worth a try.

```bash
# 1. Download libraries
python bootstrap/main.py

# 2. Run benchmarks:
# luau bench/init.luau -O2
# luau bench/init.luau -O2 --codegen
luau bench/init.luau
```

See [`bootstrap/README.md`](bootstrap/README.md) and [`bench/README.md`](bench/README.md) for full details.

## A Note on Performance in ECS

Chasing raw performance in Lua/Luau is largely the wrong goal when evaluating ECS. What is worth pursuing is ease of use and a genuine shift in how you reason about your code - thinking in terms of systems and components rather than objects and methods.

If performance is your primary concern, a straightforward AoS (Array of Structures) approach - plain tables, direct field access, no metatable inheritance chains - will typically outperform an ECS implementation in this environment. ECS frameworks in Lua add dispatch overhead and per-entity table indirection without gaining the memory layout benefit that makes the pattern worthwhile in lower-level languages. In C++ or Rust, component arrays are contiguous in memory, giving you cache-friendly iteration and SIMD-friendly data. In Lua, every component is still a heap-allocated table referenced by pointer, so you pay the framework's bookkeeping cost with none of the hardware payoff.

LuaJIT narrows this gap. Its trace compiler handles tight numeric loops over flat tables well, and the relative cost of an ECS framework shrinks - but it does not disappear, because the indirection and per-entity closure calls create call sites that are harder to trace through. The ordering stays the same; the penalty just gets much smaller.

For comparison, you can run this command from the project workspace:
```bash
luau ./scripts/ecs_vs_oop/
```

One cost the benchmarks above don't capture is entity lifecycle management. The closed-world test spawns everything upfront and toggles an `alive` flag. In a real game with frequent spawning and despawning, the AoS approach requires you to either compact the array, maintain a free-list, or iterate dead slots every frame - none of which are free. ECS frameworks handle this filtering automatically.

ECS earns its place when the architectural properties - decoupled systems, flexible composition, iteration over filtered entity sets - are what you genuinely need, not when performance is the justification.

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

Benchmark results should be interpreted with caution. Using adapters introduces significant overhead when calling functions and so on, but even so, it's sufficient for a simple comparison of libraries. Performance outcomes are highly sensitive to usage patterns, architectural decisions, and implementation details. A given ECS framework may perform poorly or exceptionally well depending on how it is applied.

Some libraries don't have a native query API. In such cases, adapters use a simple method of iterating through all entities and components - which negatively impacts performance. Therefore, it is important to consider not only performance results but also the library's API itself.

## Results Evaluating

- Run benchmarks in your own environment under conditions that resemble your target use case (change in the Lua/Luau version can affect the results).
- Consider code structure, data access patterns, and system design alongside raw benchmark numbers.
- Avoid drawing conclusions from isolated metrics. 
- Treat results as indicative rather than definitive.
- Keep in mind the overhead costs associated with the benchmark and adapters.
