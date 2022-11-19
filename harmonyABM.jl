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
marker_dict = DefaultDict('*')
color_dict = DefaultDict(:black)
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
marker_dict[Printer] = 'P'
color_dict[Printer] = :grey
isstatic(agent::Printer) = true
acts(agent::Printer) = false
function is_interacted_with(agent::Printer)
    agent.paperstacks += rand(1:5)
end

@agent Lights GridAgent{2} DeviceAgent begin    
    macaddr::String
    on::Bool
end
device_args[Lights]=Dict(
    "on"=>false
)

marker_dict[Lights] = 'L'
color_dict[Lights] = :orange
isstatic(agent::Lights) = true
acts(agent::Lights) = false
function is_interacted_with(agent::Lights)
    agent.on = !agent.on
end

@agent Phone GridAgent{2} DeviceAgent begin
    macaddr::String
    sms_received::Int
    jobs_sent::Int
end
device_args[Phone]=Dict(
    "sms_received"=>0,
    "jobs_sent"=>0
)
marker_dict[Phone] = '☎'
color_dict[Phone] = :green
isstatic(agent::Phone) = false
acts(agent::Phone) = true
function interacts(agent::Phone)
    agent.jobs_sent += 1
end
function interacted_with(agent::Phone)
    agent.sms_received += 1
end

@agent DesktopPC GridAgent{2} DeviceAgent begin
    macaddr::String
end
marker_dict[DesktopPC] = 'C'
isstatic(agent::DesktopPC) = true
acts(agent::DesktopPC) = true

agenttypes = [Printer, Lights, Phone, DesktopPC]

function initialize(;num_agents=20, griddims=(15,15), plot=false, acting_chance=0.5)
    global act_chance = acting_chance
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
        getmarker(x) = marker_dict[typeof(x)]
        getcolor(x) = color_dict[typeof(x)]
        fig, ax, abmops = abmplot(model; ac=getcolor, as=20, am=getmarker, agent_step!)
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
            rand() < act_chance ? interact(agent, partner) : nothing
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

model[63]