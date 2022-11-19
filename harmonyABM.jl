using Agents
using GLMakie
using Graphs
using Random
using InteractiveDynamics
using GraphMakie
using GraphMakie.NetworkLayout
using DataStructures: DefaultDict
 function get_mac()
    "00:00:00:$(rand(10:99)):$(rand(10:99)):$(rand(10:99))"
end
function dissect_components(g)
    fig = Figure(; resolution=(1200, 900))
    components = filter(x->length(x)>1,connected_components(g))
    nrow = round(length(components)^0.5)
    for (i,c) in enumerate(components)
        ax = Axis(fig[Int(i%nrow), Int(fld(i, nrow))])
        graphplot!(ax,induced_subgraph(g, c)[1]; layout=Stress(dim=2))
    end
    fig
end

space = GridSpaceSingle((10,10); periodic=false)

device_args = DefaultDict(nothing)
abstract type DeviceAgent <: AbstractAgent end
interacts(agent::DeviceAgent) = nothing
is_interacted_with(agent::DeviceAgent) = nothing


@agent Printer GridAgent{2} DeviceAgent begin
    macaddr::String
    paperstacks::Int
end
device_args[Printer]=Dict(
    "paperstacks"=>0
)
isstatic(agent::Printer) = true
acts(agent::Printer) = false
function is_interaced_with(agent::Printer)
    agent.paperstack += rand(1:5)
end

@agent Lights GridAgent{2} DeviceAgent begin    
    macaddr::String
end
isstatic(agent::Lights) = true
acts(agent::Lights) = false

@agent Phone GridAgent{2} DeviceAgent begin
    macaddr::String
end
isstatic(agent::Phone) = false
acts(agent::Phone) = true

@agent DesktopPC GridAgent{2} DeviceAgent begin
    macaddr::String
end
isstatic(agent::DesktopPC) = true
acts(agent::DesktopPC) = true

agenttypes = [Printer, Lights, Phone, DesktopPC]

function initialize(;num_agents=20, griddims=(15,15), plot=false)
    space = GridSpace(griddims, periodic=false)
    model = ABM(Union{agenttypes...}, space; warn=false)
    global g = DiGraph()
    add_vertices!(g, num_agents)
    for i in 1:num_agents
        agenttype = agenttypes[rand(1:end)]
        args = device_args[agenttype]
        agent = args !== nothing ? agenttype(i, (1,1), get_mac(), values(args)...) : agenttype(i, (1,1), get_mac()) 
        add_agent_single!(agent, model)
        move_agent_single!(agent, model)
    end
    fig = nothing
    if plot
        am = '☎'
        fig, ax, abmops = abmplot(model; as=20, am, agent_step!)
    end
    model, fig
end


function interact(a::DeviceAgent, b::DeviceAgent)
    add_edge!(g, a.id, b.id)
    interacts(a)
    is_interacted_with(b)
end


function agent_step!(agent, model)
    if !isstatic(agent)
        walk!(agent, rand, model)
    end
    if acts(agent)
        for partner in nearby_agents(agent, model)
            interact(agent, partner)
        end
    end
end

begin
    model, fig = initialize(; num_agents=200, griddims=(50,50))
    for _ in 1:20
        step!(model,agent_step!)
    end
    dissect_components(g)
end

begin
    model, fig = initialize(; num_agents=200, griddims=(30,30), plot=true )
    fig
end
dissect_components(g)