# Motion AI
*Motion AI* is my clumsy title for anything that moves and has AI. It is anything that moves about, affects the environment, and is affected environment. I think the proper term for this, in AI terms, is an *Actor*. However, we're gonna run with *Motion AI* because that's more expressive and I thought of it first and I really don't feel like refactoring right now.

The whole *Motion AI* concept is heavily influenced by my memories of LittleBigPlanet 2 - in that game, creating an AI monster of some kind was simply a matter of attaching a monster brain and something that allowed it to move. You could also get more complicated by attaching more components to create a facsimile of AI that followed the player around. It didn't matter what was happening under the hood so much as what the player could observe.

I'd like to take the lightweight approach to AI design for this game. As a short-hand, I like to refer to this idea as *brains-in-jars*, or a singular *brain-in-a-jar*. Each brain serves a particular purpose: moving an object, tracking potential targets, making schemes, etc. Each brain has certain inputs and outputs and the role of the actual AI class is to bind these all together into a cohesive whole. By picking and choosing the "brains" you can quickly build up a new NPC with some defined behavior. We may even begin merging different scenes together to form composite brains. With that, we could easily create new NPCs and characters that behave in a way consistent with other actors - and we could create them in a matter of minutes.

### Bear
The original idea for my prototype was just a unit of NPCs fighting a single bear. The NPCs would be represented as sprites, and the bear would be an animated model. Unfortunately, I REALLY don't want to model the bear. I REALLY don't want to. And I want to animate it even less. I'd honestly have to pay someone to do it for me and that's just not a priority right now. We'll eventually model how some great beast works and moves, just... not now.

I did whip up a model based on the California Bear Flag. Maybe we'll use it. Maybe.

### Common
This directory holds all the common AI scenes and assets - mostly the configuration *Cores* and *Machines*.

### Pawn
The Pawn is meant to be the primary NPC for our game. It's a sprite of a 3D model, the model being based on a small wooden doll/maquette. Since it's such a core part of the game, a lot of our development and experiments are focused on the Pawn.