# Getting started


## Introduction

The programming of this course will be done using the [Julia programming language](https://julialang.org). Thus, we start by explaining how to get up and running with Julia. After studying this page, you will be able to:

- Use the Julia REPL,
- Run serial and parallel code,
- Install and manage Julia packages.

## Why Julia?

Courses related with high-performance computing (HPC) often use languages such as C, C++, or Fortran. We use Julia instead to make the course accessible to a wider set of students, including the ones that have no experience with 
C/C++ or Fortran, but are willing to learn parallel programming. Julia is a relatively new programming language specifically designed for scientific computing. It combines a high-level syntax close to interpreted languages like Python with the performance of compiled languages like C, C++, or Fortran. Thus, Julia will allow us to write efficient parallel algorithms with a syntax that is convenient in a teaching setting. In addition, Julia provides easy access to different programming models to write distributed algorithms, which will be useful to learn and experiment with them.

!!! tip
    You can run the code [in this link](https://github.com/JuliaAcademy/JuliaTutorials/blob/724e15a350d150a9773afe51a3830709dbed422f/introductory-tutorials/intro-to-julia/09.%20Julia%20is%20fast.ipynb) to learn how Julia compares to other languages (C and Python) in terms of performance.


## Installing Julia

This is a tutorial-like page. Follow these steps before you continue reading the document.

- Download and install Julia from [julialang.org](https://julialang.org);
- Follow the specific instructions for your operating system: [Windows](https://julialang.org/downloads/platform/#windows), [MacOS](https://julialang.org/downloads/platform/#macos), or [Linux](https://julialang.org/downloads/platform/#linux_and_freebsd)
- Download and install [VSCode and its Julia extension](https://www.julia-vscode.org/docs/dev/gettingstarted/);


## The Julia REPL

### Starting Julia

There are several ways of opening Julia depending on your operating system and your IDE, but it is usually as simple as launching the Julia app. With VSCode, open a folder (File > Open Folder). Then,  press `Ctrl`+`Shift`+`P` to open the command bar, and execute `Julia: Start REPL`. If this does not work, make sure you have the Julia extension for VSCode installed. Independently of the method you use, opening Julia results in a window with some text ending with:

```
julia>
```

You have just opened the Julia *read-evaluate-print loop*, or simply the Julia *REPL*. Congrats! You will spend most of time using the REPL, when working in Julia. The REPL is a console waiting for user input. Just as in other consoles, the string of text right before the input area (`julia>` in the case) is called the *command prompt* or simply the *prompt*.

### Basic usage

The usage of the REPL is as follows:
- You write some input
- press enter
- you get the output

For instance, try this

```julia
julia> 1 + 1
```

A "Hello world" example looks like this in Julia

```julia
julia> println("Hello, world!")
```

Try to run it in the REPL.

### Help mode

Curious about what the function `println` does? Enter into *help* mode to look into the documentation. This is done by typing a question mark (`?`) into the input field:

```julia
julia> ?
```

After typing `?`, the command prompt changes to `help?>`. It means we are in help mode. Now, we can type a function name to see its documentation.

```julia
help?> println
```

### Package and shell modes

The REPL comes with two more modes, namely *package* and *shell* modes. To enter package mode type

```julia
julia> ]
```

Package mode is used to install and manage packages. We are going to discuss the package mode in greater detail later. To return back to normal mode press the backspace key several times.

To enter shell mode type semicolon (`;`)
```julia
julia> ;
```
The prompt should have changed to `shell>` indicating that we are in shell mode. Now you can type commands that you would normally do on your system command line. For instance,

```julia
shell> ls
```
will display the contents of the current folder in Mac or Linux. Using shell mode in Windows is not straightforward, and thus not recommended for beginners.



## Running Julia code

### Running more complex code

Real-world Julia programs are not typed in the REPL in practice. They are written in one or more files and *included* in the REPL. To try this, create a new file called `hello.jl`, write the code of the "Hello world" example above, and save it. If you are using VSCode, you can create the file using File > New File > Julia File. Once the file is saved with the name `hello.jl`, execute it as follows

```julia
julia> include("hello.jl")
```

!!! warning
    Make sure that the file `"hello.jl"` is located in the current working directory of your Julia session. You can query the current directory with function `pwd()`. You can change to another directory with function `cd()` if needed.  Also, make sure that the file extension is `.jl`.

The recommended way of running Julia code is using the REPL as we did. But it is also possible to run code directly from the system command line. To this end, open a terminal and call Julia followed by the path to the file containing the code you want to execute.

```
$ julia hello.jl
```

The previous line assumes that you have Julia properly installed in the system and that it's usable from the terminal. In UNIX systems (Linux and Mac), the Julia binary needs to be in one of the directories listed in the `PATH` environment variable. To check that Julia is properly installed, you can use

```
$ julia --version
```

If this runs without error and you see a version number, you are good to go!

You can also run julia code from the terminal using the `-e` flag:

```
$ julia -e 'println("Hello, world!")'
```

!!! note
    In this tutorial, when a code snipped starts with `$`, it should be run in the terminal. Otherwise, the code is to be run in the Julia REPL.

!!! tip
    Avoid calling Julia code from the terminal, use the Julia REPL instead!
    Each time you call Julia from the terminal, you start a fresh Julia session and Julia will need to compile your code from scratch.
    This can be time consuming for large projects.
    In contrast, if you execute code in the REPL, Julia will compile code incrementally, which is much faster.
    Running code in a cluster (like in DAS-5 for the Julia assignment) is among the few situations you need to run Julia code
    from the terminal. Visit this link ([Julia workflow tips](https://docs.julialang.org/en/v1/manual/workflow-tips/))
    from the official Julia documentation for further information about how to develop Julia code effectivelly.

### Running parallel code


Since we are in a parallel computing course, let's run a parallel "Hello world" example in Julia. Open a Julia REPL and write

```julia
julia> using Distributed
julia> @everywhere println("Hello, world! I am proc $(myid()) from $(nprocs())")
```

Here, we are using the `Distributed` package, which is part of the Julia standard library that provides distributed memory parallel support. The code prints the process id and the number of processes in the current Julia session.

You will probably only see output from 1 process. We need to add more processes to run the example in parallel. This is done with the `addprocs` function.

```julia
julia> addprocs(3)
```
We have added 3 new processes. Plus the old one, we have 4 processes. Run the code again.

```julia
julia> @everywhere println("Hello, world! I am proc $(myid()) from $(nprocs())")
```

Now, you should see output from 4 processes.

It is possible to specify the number of processes when starting Julia from the terminal with the `-p` argument (useful, e.g., when running in a cluster).  If you launch Julia from the terminal as

```
$ julia -p 3
```
and then run

```julia
julia> @everywhere println("Hello, world! I am proc $(myid()) from $(nprocs())")
```

You should get output from 4 processes as before.

### Installing packages

One of the most useful features of Julia is its package manager. It allows one to install Julia packages in a straightforward and platform independent way. To illustrate this, let us consider the following parallel "Hello world" example. This example uses the Message Passing Interface (MPI). We will learn more about MPI later in the course.


Copy the following block of code into a new file named `"hello_mpi.jl"`

```julia
# file hello_mpi.jl
using MPI
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nranks = MPI.Comm_size(comm)
println("Hello world, I am rank $rank of $nranks")
```

As you can see from this example, one can access MPI from Julia in a clean way, without type annotations and other complexities of C/C++ code.

Now, run the file from the REPL
```julia
julia> include("hello_mpi.jl")
```

It probably didn't work, right? Read the error message and note that the MPI package needs to be installed to run this code.

To install a package, we need to enter *package* mode. Remember that we entered into help mode by typing `?`. Package mode is activated by typing `]` : 
```julia
julia> ]
```
At this point, the prompt should have changed to `(@v1.10) pkg>` indicating that we are in package mode. The text between the parentheses indicates which is the active *project*, i.e., where packages are going to be installed. In this case, we are working with the global project associated with our Julia installation (which is Julia 1.10 in this example, but it can be another version in your case).

To install the MPI package, type
```julia
(@v1.10) pkg> add MPI
```
Congrats, you have installed MPI!

!!! note
    Many Julia package names end with `.jl`. This is just a way of signaling that a package is written in Julia. When using such packages, the `.jl` needs to be omitted. In this case, we have installed the `MPI.jl` package even though we have only typed `MPI` in the REPL.

!!! note
    The package you have installed is the Julia interface to MPI, called  `MPI.jl`. Note that it is not a MPI library by itself. It is just a thin wrapper between MPI and Julia. To use this interface, you need an actual MPI library installed in your system such as OpenMPI or MPICH. Julia downloads and installs a MPI library for you, but it is also possible to use a MPI library already available in your system. This is useful, e.g., when running on HPC clusters. See the [documentation](https://juliaparallel.org/MPI.jl/stable/configuration/) of `MPI.jl` for further details.

To check that the package was installed properly, exit package mode by pressing the backspace key several times, and run it again

```julia
julia> include("hello_mpi.jl")
```

Now, it should work, but you probably get output from a single MPI rank only.

### Running MPI code

To run MPI applications in parallel, you need a launcher like `mpiexec`. MPI codes written in Julia are not an exception to this rule. From the system terminal, you can run
```
$ mpiexec -np 4 julia hello_mpi.jl
```
But it will probably not work since the version of `mpiexec` needs to match with the MPI version we are using from Julia. Don't worry if you could not make it work! A more elegant way to run MPI code is from the Julia REPL directly, by using these commands:
```julia
julia> using MPI
julia> run(`$(mpiexec()) -np 4 julia hello_mpi.jl`)
```

Now, you should see output from 4 ranks.

## Package manager

### Installing packages locally

We have installed the `MPI` package globally and it will be available in all Julia sessions. However, in some situations, we want to work with different versions of the same package or to install packages in an isolated way to avoid potential conflicts with other packages. This can be done by using local projects.

A project is simply a folder in your file system. To use a particular folder as your project, you need to *activate* it. This is done by entering package mode and using the `activate` command followed by the path to the folder you want to activate.
```julia
(@v1.10) pkg> activate .
```
 The previous command will activate the current working directory. Note that the dot `.` is indeed the path to the current folder.

The prompt has changed to `(lessons) pkg>` indicating that we are in the project within the `lessons` folder. The particular folder name can be different in your case.

!!! tip
    You can activate a project directly when opening Julia from the terminal using the `--project` flag. The command `$ julia --project=.` will open Julia and activate a project in the current directory. You can also achieve the same effect by setting the environment variable  `JULIA_PROJECT` with the path of the folder you want to activate.

!!! note
    The active project folder and the current working directory are two independent concepts! For instance,  `(@v1.10) pkg> activate folderB` and then `julia> cd("folderA")`, will activate the project in `folderB` and change the current working directory to `folderA`.

At this point all package-related operations will be local to the new project. For instance, install the `DataFrames` package.

```julia
(lessons) pkg> add DataFrames
```
Use the package to check that it is installed

```julia
julia> using DataFrames
julia> DataFrame(a=[1,2],b=[3,4])
```
Now, we can return to the global project to check that `DataFrames` has not been installed there. To return to the global environment, use `activate` without a folder name.

```julia
(lessons) pkg> activate
```
The prompt is again `(@v1.10) pkg>`

Now, try to use `DataFrames`.

```julia
julia> using DataFrames
julia> DataFrame(a=[1,2],b=[3,4])
```
You should get an error or a warning unless you already had `DataFrames` installed globally.

### Project and Manifest files

The information about a project is stored in two files `Project.toml` and `Manifest.toml`.

- `Project.toml` contains the packages explicitly installed (the direct dependencies)

- `Manifest.toml` contains direct and indirect dependencies along with the concrete version of each package.


In other words, `Project.toml` contains the packages relevant for the user, whereas `Manifest.toml` is the detailed snapshot of all dependencies. The `Manifest.toml` can be used to reproduce the same environment in another machine.

You can see the path to the current `Project.toml` file by using the `status` operator (or `st` in its short form) while in package mode

```julia
(@v1.10) pkg> status
```

The information about the `Manifest.toml` can be inspected by passing the `-m` flag.

```julia
(@v1.10) pkg> status -m
```

### Installing packages from a project file

Project files can be used to install lists of packages defined by others. E.g., to install all the dependencies of a Julia application.

Assume that a colleague has sent to you a `Project.toml` file with this content:

```
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"
```

Copy the contents of previous code block into a file called  `Project.toml` and place it in an empty folder named `newproject`. It is important that the file is named `Project.toml`. You can create a new folder from the REPL with

```julia
julia> mkdir("newproject")
```

To install all the packages registered in this file you need to activate the folder containing your `Project.toml` file
```julia
(@v1.10) pkg> activate newproject
```
and then *instantiating* it
```julia
(newproject) pkg> instantiate
```

The instantiate command will download and install all listed packages and their dependencies in just one click.

### Getting help in package mode

You can get help about a particular package operator by writing `help` in front of it

```julia
(@v1.10) pkg> help activate
```

You can get an overview of all package commands by typing `help` alone
```julia
(@v1.10) pkg> help
```

### Package operations in Julia code

In some situations it is required to use package commands in Julia code, e.g., to automatize installation and deployment of Julia applications. This can be done using the `Pkg` package. For instance

```julia
julia> using Pkg
julia> Pkg.status()
```
is equivalent to calling `status` in package mode.
```julia
(@v1.10) pkg> status
```

### Creating you own package

In many situations, it is useful to create your own package, for instance, when working with a large code base, when you want to reduce compilation latency using [`Revise.jl`](https://github.com/timholy/Revise.jl),
or if you want to eventually [register your package](https://github.com/JuliaRegistries/Registrator.jl) and share it with others.

The simplest way of generating a package (called `MyPackage`) is as follows. Open Julia, go to package mode, and type

```julia
(@v1.10) pkg> generate MyPackage
```

This will crate a minimal package consisting of a new folder `MyPackage` with two files:

* `MyPackage/Project.toml`: Project file defining the direct dependencies of your package.
* `MyPackage/src/MyPackage.jl`: Main source file of your package. You can split your code in several files if needed, and include them in the package main file using function `include`.

!!! tip
    This approach only generates a very minimal package. To create a more sophisticated package skeleton (including unit testing, code coverage, readme file, licence, etc.) use
    [`PkgTemplates.jl`](https://github.com/JuliaCI/PkgTemplates.jl) or [`BestieTemplate.jl`](https://github.com/JuliaBesties/BestieTemplate.jl). The later one is developed in Amsterdam at the
    [Netherlands eScience Center](https://www.esciencecenter.nl/).

You can add dependencies to the package by activating the `MyPackage` folder in package mode and adding new dependencies as always:

```julia
(@v1.10) pkg> activate MyPackage
(MyPackage) pkg> add MPI
```

This will add MPI to your package dependencies.

### Using your own package

To use your package you first need to add it to a package environment of your choice. This is done by changing to package mode and typing `develop ` followed by the path to the folder containing the package. For instance:

```julia
(@v1.10) pkg> develop MyPackage
```

!!! note
    You do not need to "develop" your package if you activated the package folder `MyPackage`.

Now, we can go back to standard Julia mode and use it as any other package:

```julia
using MyPackage
MyPackage.greet()
```

Here, we just called the example function defined in `MyPackage/src/MyPackage.jl`.


## Conclusion

We have learned the basics of how to work with Julia, including how to run serial and parallel code, and how to manage, create, and use Julia packages.
This knowledge will allow you to follow the course effectively!
If you want to further dig into the topics we have covered here, you can take a look at the following links:

- [Julia Manual](https://docs.julialang.org/en/v1/manual/getting-started/)
- [Package manager](https://pkgdocs.julialang.org/v1/getting-started/)


