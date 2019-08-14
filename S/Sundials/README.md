# SundialsBuilder

[![Build Status](https://travis-ci.org/JuliaDiffEq/SundialsBuilder.svg?branch=master)](https://travis-ci.org/JuliaDiffEq/SundialsBuilder)

This repository builds binary libraries for the [Sundials](https://computation.llnl.gov/projects/sundials) project. Libraries are included in
[this repository's GitHub releases page](https://github.com/tshort/SundialsBuilder/releases).

This repository was created using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).

The latest release is a build for Sundials v3.1.0, and it includes KLU from SuiteSparse v4.5.3. The main use of these binary libraries is the Julia package [Sundials.jl](https://github.com/JuliaDiffEq/Sundials.jl), but there is nothing Julia-specific in the libraries.
