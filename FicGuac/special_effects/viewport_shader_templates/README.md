# Viewport Shader Templates
A *Viewport Shader* is any shader that uses a Godot `ViewportTexture` - a `Viewport` in Godot is basically a separate/different screen, so a `ViewportTexture` is a way to draw that different screen on objects in game.

There are pretty exciting possibilities for what we can do with this technique. We currently use this for painting different "Views" of the world, via our *Silhouette* and *Xray* shaders.

## "Templates"
Unlike most shaders or materials, a *Viewport Shader* must be unique to the scene it exists in. This has a few implications.

First, it means that the shaders must be loaded into the scene from these templates, and then "made unqiue". This can be done by right-clicking the material (once it's assigned to a mesh or other such resource) and pressing the "Make Unique" button.

Secondly, each shader needs the *Local to Scene* configurable enabled. This is under the resource's `Resource` category - look it up!

Each one of these shader templates takes in texture in the *Viewport Texture* shader parameter. I suppose any texture could be used, but it's really only designed for `ViewportTexture`. If something is misconfigured in the material, the `ViewportTexture` will tell you what's gone wrong.

## Silhouette
The silhouette shader is meant to show colored-in silhouettes through walls. It was designed to work with the *Silhouettable* visual layer. There are two types of silhouette shader: the *Fill*, and the *Multiply*. Because this shader uses alpha, there may be some conflict with rendering over-or-under sprites. The *Render Priority*, under the shader's `Material` properties, can alleviate this.

### Alpha Color
Both versions of the silhouette shader have a common parameter: the *Alpha Color*. Any color in the *Viewport Texture* that matches this color EXACTLY will be alpha'd out. Defaults to magenta (#ff00ff).

### Fill
The fill silhouette shader colors the silhouette as one single color. This color is provided via the *Fill Color* parameter. The parameter's alpha value is respected, as is alpha value in the *Viewport Texture*.

### Multiply
The multiply silhouette shader colors the silhouette as by multiplying an input color over a grayscale version of the *Viewport Texture*. This creates a colored silhouette where the texture is preserved.

The color is provided via the *Multiply Color* parameter. The parameter's alpha value is respected, as is alpha value in the *Viewport Texture*.

## Xray
The xray shader is meant to show a cut-away through walls by rendering a viewport texture over the world. The idea is, the other viewport shows a world without obstructions - by rendering that world on top of the real one, we effectively get an "xray" through obstacles.

By default, the xray shader doesn't support any alpha. In order to render in front of everything, we rely on placing whatever object is rendering the shader in front of stuff - since we have an orthographic camera, placing the object correctly will allow us to effectively render in front of things.

There are three xray shaders: regular, "no depth", and "alpha texture".

### No Depth
But what if, for whatever reason, we actually want to render the xray object in-place? This shader disables depth testing, so the mesh is always rendered in front of everything. Of course, things get tricky when there are two no-depth shaders layered on top of each other...

### Alpha Texture
All xray shaders fill out the whole mesh with the `ViewportTexture` - that means the visual appearance of the xray shader is determined entirely by the mesh. However, we may wish to use a texture to apply an alpha.

This shader takes in an *Alpha Texture* parameter. The alpha will be extracted from this texture and applied to the mesh. It's recommended to use this with a dedicated mask texture and a `QuadMesh`.

Because this shader uses alpha, there may be some conflict with rendering over-or-under sprites. The *Render Priority*, under the shader's `Material` properties, can alleviate this.