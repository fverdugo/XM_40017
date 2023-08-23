using Distributed

if procs() == workers()
    addprocs(4)
end

@everywhere function visited(city,hops,path)
    for i = 1:hops
        if path[i] == city
            return true
        end
    end
    return false
end

# solution [1, 4, 5, 2, 3, 6], distance = 222
connections = [
    [(1,0),(4,39),(5,76), (6,78),(3,94),(2,97)],
    [(2,0),(5,25),(4,58),(3,62),(1,97),(6,109)],
    [(3,0),(6,58),(2,62),(4,68),(5,70),(1,94)],
    [(4,0),(5,38),(1,39),(2,58),(3,68),(6,78)],
    [(5,0),(2,25),(4,38),(3,70),(1,76),(6,104)],
    [(6,0),(3,58),(1,78),(4,78),(5,104),(2,109)]
]

# Shortest route with start 1: 1-3-2-4 (distance: 7)
con2 = [
    [(1,0), (2,2), (3,3), (4,4)],
    [(2,0), (4,1), (1,2), (3,3)],
    [(3,0), (1,3), (2,3), (4,10)], 
    [(4,0), (2,1), (1,4), (3,10)]
]


## TSP distributed
@everywhere function tsp_dist_impl(connections,hops,path,current_distance,min_dist_chnl, max_hops,jobs_chnl,ftr_result)
    num_cities = length(connections)
    if hops == num_cities
        min_distance = fetch(min_dist_chnl)
        if current_distance < min_distance
            take!(min_dist_chnl)
            # Wait until results are written to future 
            if ftr_result !== nothing
                @spawnat 1 begin
                    result = fetch(ftr_result)
                    result.path .= path
                    result.min_distance_ref[] = current_distance
                end |> wait
            end
            # Unblock waiting processes
            put!(min_dist_chnl, current_distance)
        end
    elseif hops <= max_hops
        current_city = path[hops]
        next_hops = hops + 1
        for (next_city,distance_increment) in connections[current_city]
            if !visited(next_city,hops,path)
                path[next_hops] = next_city
                next_distance = current_distance + distance_increment
                min_distance = fetch(min_dist_chnl)
                if next_distance < min_distance
                    tsp_dist_impl(connections,next_hops,path,next_distance,min_dist_chnl,max_hops,jobs_chnl,ftr_result)
                end
            end
        end 
    else
        if jobs_chnl !== nothing 
            # Allocate new memory so paths are not overwritten in queue
            path_copy = copy(path) 
            put!(jobs_chnl,(;hops,path=path_copy,current_distance))
        end
    end
end

function tsp_dist(connections,city)
    max_hops = 2
    num_cities = length(connections)
    path=zeros(Int,num_cities)
    result_path=zeros(Int, num_cities)
    hops = 1
    path[hops] = city
    current_distance = 0
    min_distance = typemax(Int)
    jobs_chnl = RemoteChannel(()->Channel{Any}(10))
    # Initialize min distance channel with Intmax
    min_dist_chnl = RemoteChannel(()->Channel{Int}(1))
    put!(min_dist_chnl, min_distance)
    # Future to store overall result
    ftr_result = @spawnat 1 (;path=result_path,min_distance_ref=Ref(min_distance))
    @async begin
        tsp_dist_impl(connections,hops,path,current_distance,min_dist_chnl,max_hops,jobs_chnl,nothing)
        for w in workers()
            put!(jobs_chnl,nothing)
        end
    end
    @sync for w in workers()
        @spawnat w begin
            path = zeros(Int, num_cities)
            max_hops = typemax(Int)
            jobs_channel = nothing
            while true
                job = take!(jobs_chnl)
                if job == nothing
                    break
                end
                hops = job.hops
                path = job.path
                current_distance = job.current_distance
                # Prune this job if current distance exeeds search threshold
                min_distance = fetch(min_dist_chnl)
                if current_distance < min_distance
                    tsp_dist_impl(connections,hops,path,current_distance,min_dist_chnl,max_hops,jobs_channel,ftr_result)
            
                end
            end
        end
    end 
    result = fetch(ftr_result)
    (;path = result.path, distance = result.min_distance_ref[])
end
city = 1
tsp_dist(connections,city)