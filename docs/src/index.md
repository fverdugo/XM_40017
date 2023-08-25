```@meta
CurrentModule = XM_40017
```
# Programming Large-Scale Parallel Systems (XM_40017)

Welcome to the interactive lecture notes of the [Programming Large-Scale Parallel Systems course](https://studiegids.vu.nl/EN/courses/2023-2024/XM_40017#/) at [VU Amsterdam](https://vu.nl)!

## What

This page contains part of the course material of the Programming Large-Scale Parallel Systems course at VU Amsterdam.
We provide several lecture notes in jupyter notebook format, which will help you to learn how to design, analyze, and program parallel algorithms on multi-node computing systems.
Further information about the course is found in the study guide
([click here](https://studiegids.vu.nl/EN/courses/2023-2024/XM_40017#/)) and our Canvas page (for registered students).

!!! note
    Material will be added incrementally to the website as the course advances.

!!! warning
    This page will eventually contain only a part of the course material. The rest will be available on Canvas. In particular, **the material in this public webpage does not fully cover all topics in the final exam**.

## How to use this page

You have two main ways of studying the notebooks:

- Download the notebooks and run them locally on your computer (recommended). At each notebook page you will find a green box with links to download the notebook.
- You also have the static version of the notebooks displayed in this webpage for quick reference.

## How to run the notebooks locally

To run a notebook locally follow these steps:

- Install Julia (if not done already). More information in [Getting started](@ref).
- Download the notebook.
- Launch Julia. More information in [Getting started](@ref).
- Execute these commands in the Julia command line:

```
julia> using Pkg
julia> Pkg.add("IJulia")
julia> using IJulia
julia> notebook()
```
- These commands will open a jupyter in your web browser. Navigate in jupyter to the notebook file you have downloaded and open it.

## Authors

This material is created by [Francesc Verdugo](https://github.com/fverdugo/) with the help of [Gelieza Kötterheinrich](https://www.linkedin.com/in/gelieza/). Part of the notebooks are based on the course slides by [Henri Bal](https://www.vuhpdc.net/henri-bal/).


## License

All material on this page that is original to this course may be used under a [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) license.


## Acknowledgment

This page was created with the support of the Faculty of Science of [Vrije Universiteit Amsterdam](https://vu.nl) in the framework of the project "Interactive lecture notes and exercises for the Programming Large-Scale Parallel Systems course" funded by the "Innovation budget BETA 2023 Studievoorschotmiddelen (SVM) towards Activated Blended Learning".
