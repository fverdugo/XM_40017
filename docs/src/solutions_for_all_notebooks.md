# Solutions

## Julia Basics

### Exercise 1

```julia
function ex1(a)
    j = 1
    m = a[j]
    for (i,ai) in enumerate(a)
        if m < ai
            m = ai
            j = i
        end
    end
    (m,j)
end
```

### Exercise 2

```julia
ex2(f,g) = x -> f(x) + g(x)
```

### Exercise 3

```julia
using GLMakie
max_iters = 100
n = 1000
x = LinRange(-1.7,0.7,n)
y = LinRange(-1.2,1.2,n)
heatmap(x,y,(i,j)->mandel(i,j,max_iters))
```

## Asynchronous programming in Julia

## Distributed computing in Julia

### Exercise 1

```julia
f = () -> Channel{Int}(1)
chnls = [ RemoteChannel(f,w) for w in workers() ]
@sync for (iw,w) in enumerate(workers())
    @spawnat w begin
        chnl_snd = chnls[iw]
        if w == 2
            chnl_rcv = chnls[end]
            msg = 2
            println("msg = $msg")
            put!(chnl_snd,msg)
            msg = take!(chnl_rcv)
            println("msg = $msg")
        else
           chnl_rcv = chnls[iw-1]
           msg = take!(chnl_rcv)
           msg += 1
           println("msg = $msg")
           put!(chnl_snd,msg)
        end
    end
end
```

This is another possible solution.

```julia
@everywhere function work(msg)
    println("msg = $msg")
    if myid() != nprocs()
        next = myid() + 1
        @fetchfrom next work(msg+1)
    else
        @fetchfrom 2 println("msg = $msg")
    end
end
msg = 2
@fetchfrom 2 work(msg)
```


## Matrix-matrix multiplication

### Exercise 1

```julia
function matmul_dist_3!(C,A,B)
    m = size(C,1)
    n = size(C,2)
    l = size(A,2)
    @assert size(A,1) == m
    @assert size(B,2) == n
    @assert size(B,1) == l
    @assert mod(m,nworkers()) == 0
    nrows_w = div(m,nworkers())
    @sync for (iw,w) in enumerate(workers())
        lb = 1 + (iw-1)*nrows_w
        ub = iw*nrows_w
        A_w = A[lb:ub,:]
        ftr = @spawnat w begin
             C_w = similar(A_w)
             matmul_seq!(C_w,A_w,B)
             C_w
        end
        @async C[lb:ub,:] = fetch(ftr)
    end
    C
end

@everywhere function matmul_seq!(C,A,B)
    m = size(C,1)
    n = size(C,2)
    l = size(A,2)
    @assert size(A,1) == m
    @assert size(B,2) == n
    @assert size(B,1) == l
    z = zero(eltype(C))
    for j in 1:n
        for i in 1:m
            Cij = z
            for k in 1:l
                @inbounds Cij = Cij + A[i,k]*B[k,j]
            end
            C[i,j] = Cij
        end
    end
    C
end
```

## MPI (Point-to-point)

### Exercise 2

```julia
using MPI
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nranks = MPI.Comm_size(comm)
buffer = Ref(0)
if rank == 0
    msg = 2
    buffer[] = msg
    println("msg = $(buffer[])")
    MPI.Send(buffer,comm;dest=rank+1,tag=0)
    MPI.Recv!(buffer,comm;source=nranks-1,tag=0)
    println("msg = $(buffer[])")
else
    dest = if (rank != nranks-1)
        rank+1
    else
        0
    end
    MPI.Recv!(buffer,comm;source=rank-1,tag=0)
    buffer[] += 1
    println("msg = $(buffer[])")
    MPI.Send(buffer,comm;dest,tag=0)
end
```

## Jacobi method

### Exercise 1

```julia
function jacobi_mpi(n,niters)
    comm = MPI.COMM_WORLD
    nranks = MPI.Comm_size(comm)
    rank = MPI.Comm_rank(comm)
    if mod(n,nranks) != 0
        println("n must be a multiple of nranks")
        MPI.Abort(comm,1)
    end
    load = div(n,nranks)
    u = zeros(load+2)
    u[1] = -1
    u[end] = 1
    u_new = copy(u)
    for t in 1:niters
        reqs = MPI.Request[]
        if rank != 0
            neig_rank = rank-1
            req = MPI.Isend(view(u,2:2),comm,dest=neig_rank,tag=0)
            push!(reqs,req)
            req = MPI.Irecv!(view(u,1:1),comm,source=neig_rank,tag=0)
            push!(reqs,req)
        end
        if rank != (nranks-1)
            neig_rank = rank+1
            s = load+1
            r = load+2
            req = MPI.Isend(view(u,s:s),comm,dest=neig_rank,tag=0)
            push!(reqs,req)
            req = MPI.Irecv!(view(u,r:r),comm,source=neig_rank,tag=0)
            push!(reqs,req)
        end
        for i in 3:load
            u_new[i] = 0.5*(u[i-1]+u[i+1])
        end
        MPI.Waitall(reqs)
        for i in (2,load+1)
            u_new[i] = 0.5*(u[i-1]+u[i+1])
        end
        u, u_new = u_new, u

    end
    # Gather the results
    if rank !=0
        lb = 2
        ub = load+1
        MPI.Send(view(u,lb:ub),comm,dest=0)
        u_all = zeros(0) # This will nevel be used
    else
        u_all = zeros(n+2)
        # Set boundary
        u_all[1] = -1
        u_all[end] = 1
        # Set data for rank 0
        lb = 2
        ub = load+1
        u_all[lb:ub] = view(u,lb:ub)
        # Set data for other ranks
        for other_rank in 1:(nranks-1)
            lb += load
            ub += load
            MPI.Recv!(view(u_all,lb:ub),comm;source=other_rank)
        end
    end
    return u_all
end
```




