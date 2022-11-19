# Agent based IoT Modelling
robert-betschinger@outlook.de
***Disclaimer**: This was built as part of HackaTUM, excuse bad practices and sparse documentation.* 

## Motivation
I was curious to see if it would be possible to recover information on devices like type or owner, given just the MAC address and previous interactions with other devices in a network.
This of course begs the question how to even identify a network, for now we treat it as a connected graph of interactions. 
Unfortunately exploring this idea proved difficult, as public Datasets on the matter are sparce, leading to the decision to create my a synthetic one via simulation.


## Execution
The project is divided into two parts.
1. **Simulation**
   An easily extendable and configurable baseline for simulating interaction. So far includes Phones which move around randomly and interact with everything they encounter and static objects (smart lights(L), printers(P), PCs(C)).
   Each object has the ability to keep track of statistics and react to being interacted with.
2. **Graph Analysis**
   Every interaction is kept track of in the underlying graph. As of now the result is divided into components and the induced subgraphs are plotted to visualize the network. The Graph also enables much deeper analysis like community detection or type prediction leveraging geometric deep learning, especially if the simulation is expanded in complexity.

The work is pure Julia, leveraging Agents.jl for the Simulation and GLMakie for high performance plotting on the GPU.

