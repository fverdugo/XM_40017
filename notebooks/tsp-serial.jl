using Distributed

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

@everywhere function visited(city,hops,path)
    for i = 1:hops
        if path[i] == city
            return true
        end
    end
    return false
end

## TSP serial 
function tsp_serial_impl(connections,hops,path,current_distance, min_path, min_distance)
    num_cities = length(connections)
    if hops == num_cities
        if current_distance < min_distance
            min_path .= path
            return min_path, current_distance
        end
    else
        current_city = path[hops]
        next_hops = hops + 1
        for (next_city,distance_increment) in connections[current_city]
            if !visited(next_city,hops,path)
                path[next_hops] = next_city
                next_distance = current_distance + distance_increment
                if next_distance < min_distance
                    min_path, min_distance = tsp_serial_impl(connections,next_hops,path,next_distance,min_path,min_distance)
                end
            end
        end        
    end
    return min_path, min_distance
end

function tsp_serial(connections,city)
    num_cities = length(connections)
    path=zeros(Int,num_cities)
    hops = 1
    path[hops] = city
    min_path = zeros(Int, num_cities)
    current_distance = 0
    min_distance = typemax(Int)
    min_path, min_distance = tsp_serial_impl(connections,hops,path,current_distance, min_path, min_distance)
    (;path=min_path,distance=min_distance)
end

city = 1
tsp_serial(connections,city)
