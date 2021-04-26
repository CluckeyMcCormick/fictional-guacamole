# GraphViz Scripts
>Note: These scripts are mostly used for generating documentation; ergo, the documentation isn't as thorough as scripts that are part of our asset pipeline.

[GraphViz](https://graphviz.org/) is a cross-platform program that can quickly and consistently create node-and-edge graphs, like the one below. These graphs are perfect for documenting Godot's scene trees and the pretty complex state machines we use throughout the project.

![Image](./doc_images/sample_graph.png "Sample State Machine")

*GraphViz* works in different ways across different platforms, but these scripts should be acceptable input for any of the latest versions.

In Ubuntu 20.04, these scripts are compiled using a series of commands. So far, all of the scripts are Dot graphs, so we use the following command:

```bash
dot -Tpng [input].dot -o [output].png
```

## KDM Hierarchy and Flow
These two scripts concern a pretty basic AI machine - the *Kinematic Driver Machine*, frequently abbreviated to the *KDM*. Since it's a machine, it has a complex structure and process.

The *Hierarchy* script creates a graph showing the arrangement of states in the *KDM* scene. That's not too radical but it's key to understanding the next graph.

That would be the graph created by the *Flow* script. This depicts how the states relate to each other and the conditions that cause movements between the states. This is something that otherwise can only be discerned via code inspection.

## FBM Hierarchy and Flow
These two scripts document a regression of the *Kinematic Driver Machine*: the *Falling Body Machine*.

Like the *KDM*, we have a hierarchy and flow script. They make really simple charts (since there's only two states).

## REM Hierarchy and Flows (State & Data)
These two scripts document the next AI development stage after the *Kinematic Driver Machine*: the *Rat Emulation Machine*.

This also has a hierarchy script. However, as the first machine to feature *regions*, this machine features multiple flow scripts - one that depicts the flow of control between the different states, and one that depicts the flow of data between the states.

## TCM Hierarchy and Flows (State & Data)
These four scripts document the *Tasking Coward Machine*, an further development of the *Rat Emulation Machine*.

This machine has a hierarchy script. It also features separate flow diagrams for control and data flow. Since this machine is technically composed of two to three separate *XSM* machines, I decided to split the state control flow diagram into two separate diagrams - one covering the *Goal Region*, the other covering the *Physics Travel Region*.

## XSM Tutorial
The Extended State Machine (*XSM*) concept can get pretty complicated pretty quickly, so I thought it would be prudent to generate some documentation for how they work. Of course, that required diagrams. A LOT of diagrams. Those are stored here.
