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
n = 1000
x = LinRange(-1.7,0.7,n)
y = LinRange(-1.2,1.2,n)
values = zeros(n,n)
for j in 1:n
    for i in 1:n
        values[i,j] = surprise(x[i],y[j])
    end
end
using GLMakie
heatmap(x,y,values)
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

### Exercise 1

```julia
function matmul_mpi_3!(C,A,B)
    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(comm)
    P = MPI.Comm_size(comm)
    if  rank == 0
        N = size(A,1)
        myB = B
        for dest in 1:(P-1)
            MPI.Send(B,comm;dest)
        end
    else
        source = 0
        status = MPI.Probe(comm,MPI.Status;source)
        count = MPI.Get_count(status,eltype(B))
        N = Int(sqrt(count))
        myB = zeros(N,N)
        MPI.Recv!(myB,comm;source)
    end
    L = div(N,P)
    myA = zeros(L,N)
    if  rank == 0
        lb = L*rank+1
        ub = L*(rank+1)
        myA[:,:] = view(A,lb:ub,:)
        for dest in 1:(P-1)
            lb = L*dest+1
            ub = L*(dest+1)
            MPI.Send(view(A,lb:ub,:),comm;dest)
        end
    else
        source = 0
        MPI.Recv!(myA,comm;source)
    end
    myC = myA*myB
    if rank == 0
        lb = L*rank+1
        ub = L*(rank+1)
        C[lb:ub,:] = myC
        for source in 1:(P-1)
            lb = L*source+1
            ub = L*(source+1)
            MPI.Recv!(view(C,lb:ub,:),comm;source)
        end
    else
        dest = 0
        MPI.Send(myC,comm;dest)
    end
    C
end
```

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
## MPI (collectives)

### Exercise 1

```julia
function matmul_mpi_3!(C,A,B)
    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(comm)
    P = MPI.Comm_size(comm)
    root = 0
    if  rank == root
        N = size(A,1)
        Nref = Ref(N)
    else
        Nref = Ref(0)
    end
    MPI.Bcast!(Nref,comm;root)
    N = Nref[]
    if  rank == root
        myB = B
    else
        myB = zeros(N,N)
    end
    MPI.Bcast!(myB,comm;root)
    L = div(N,P)
    # Tricky part
    # Julia works "col major"
    myAt = zeros(N,L)
    At = collect(transpose(A))
    MPI.Scatter!(At,myAt,comm;root)
    myCt = transpose(myB)*myAt
    Ct = similar(C)
    MPI.Gather!(myCt,Ct,comm;root)
    C .= transpose(Ct)
    C
end
```

This other solution uses a column partition instead of a row partition.
It is more natural to work with column partitions in Julia if possible since matrices are
in "col major" format. Note that we do not need all the auxiliary transposes anymore.

```julia
function matmul_mpi_3!(C,A,B)
    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(comm)
    P = MPI.Comm_size(comm)
    root = 0
    if  rank == root
        N = size(A,1)
        Nref = Ref(N)
    else
        Nref = Ref(0)
    end
    MPI.Bcast!(Nref,comm;root)
    N = Nref[]
    if  rank == root
        myA = A
    else
        myA = zeros(N,N)
    end
    MPI.Bcast!(myA,comm;root)
    L = div(N,P)
    myB = zeros(N,L)
    MPI.Scatter!(B,myB,comm;root)
    myC = myA*myB
    MPI.Gather!(myC,C,comm;root)
    C
end
```

## Jacobi method

### Exercise 1

```julia
function jacobi_mpi(n,niters)
    u, u_new = init(n,comm)
    load = length(u)-2
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    nreqs = 2*((rank != 0) + (rank != (nranks-1)))
    reqs = MPI.MultiRequest(nreqs)
    for t in 1:niters
        ireq = 0
        if rank != 0
            neig_rank = rank-1
            u_snd = view(u,2:2)
            u_rcv = view(u,1:1)
            dest = neig_rank
            source = neig_rank
            ireq += 1
            MPI.Isend(u_snd,comm,reqs[ireq];dest)
            ireq += 1
            MPI.Irecv!(u_rcv,comm,reqs[ireq];source)
        end
        if rank != (nranks-1)
            neig_rank = rank+1
            u_snd = view(u,(load+1):(load+1))
            u_rcv = view(u,(load+2):(load+2))
            dest = neig_rank
            source = neig_rank
            ireq += 1
            MPI.Isend(u_snd,comm,reqs[ireq];dest)
            ireq += 1
            MPI.Irecv!(u_rcv,comm,reqs[ireq];source)
        end
        # Upload interior cells
        for i in 3:load
            u_new[i] = 0.5*(u[i-1]+u[i+1])
        end
        # Wait for the communications to finish
        MPI.Waitall(reqs)
        # Update boundaries
        for i in (2,load+1)
            u_new[i] = 0.5*(u[i-1]+u[i+1])
        end
        u, u_new = u_new, u
    end
    return u
end
```

### Exercise 2

```julia
function jacobi_mpi(n,niters,tol,comm) # new tol arg
    u, u_new = init(n,comm)
    load = length(u)-2
    rank = MPI.Comm_rank(comm)
    nranks = MPI.Comm_size(comm)
    nreqs = 2*((rank != 0) + (rank != (nranks-1)))
    reqs = MPI.MultiRequest(nreqs)
    for t in 1:niters
        ireq = 0
        if rank != 0
            neig_rank = rank-1
            u_snd = view(u,2:2)
            u_rcv = view(u,1:1)
            dest = neig_rank
            source = neig_rank
            ireq += 1
            MPI.Isend(u_snd,comm,reqs[ireq];dest)
            ireq += 1
            MPI.Irecv!(u_rcv,comm,reqs[ireq];source)
        end
        if rank != (nranks-1)
            neig_rank = rank+1
            u_snd = view(u,(load+1):(load+1))
            u_rcv = view(u,(load+2):(load+2))
            dest = neig_rank
            source = neig_rank
            ireq += 1
            MPI.Isend(u_snd,comm,reqs[ireq];dest)
            ireq += 1
            MPI.Irecv!(u_rcv,comm,reqs[ireq];source)
        end
        MPI.Waitall(reqs)
        # Compute the max diff in the current
        # rank while doing the local update
        mydiff = 0.0
        for i in 2:load+1
            u_new[i] = 0.5*(u[i-1]+u[i+1])
            diff_i = abs(u_new[i] - u[i])
            mydiff = max(mydiff,diff_i)
        end
        # Now we need to find the global diff
        diff_ref = Ref(mydiff)
        MPI.Allreduce!(diff_ref,max,comm)
        diff = diff_ref[]
        # If global diff below tol, stop!
        if diff < tol
            return u_new
        end
        u, u_new = u_new, u
    end
    return u
end
```

## All pairs of shortest paths

### Exercise 1

```julia
function floyd_iterations!(myC,comm)
    L = size(myC,1)
    N = size(myC,2)
    rank = MPI.Comm_rank(comm)
    P = MPI.Comm_size(comm)
    lb = L*rank+1
    ub = L*(rank+1)
    C_k = similar(myC,N)
    for k in 1:N
        if (lb<=k) && (k<=ub)
            # If I have the row, fill in the buffer
            myk = (k-lb)+1
            C_k[:] = view(myC,myk,:)
        end
        # We need to find out the owner of row k.
        # Easy since N is a multiple of P
        root = div(k-1,L)
        MPI.Bcast!(C_k,comm;root)
        # Now, we have the data dependencies and
        # we can do the updates locally
        for j in 1:N
            for i in 1:L
                myC[i,j] = min(myC[i,j],myC[i,k]+C_k[j])
            end
        end
    end
    myC
end
```





