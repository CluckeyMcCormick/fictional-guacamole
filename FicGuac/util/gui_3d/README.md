# GUI 3D
The *GUI 3D* scenes allow us to create GUI elements that exist in 3D space. Currently, they only exist in *Util* because they're kind of buggy and they don't work all that well. But this is functionality that we'll need eventually, especially for health bars and names (and the like).

## QuadLabel
Currently the lone *GUI 3D* scene. This scene allows you to create dynamic text on a simple quad. 

Note that there are a lot of issues with the text not being centered on the quad. Also, the quad itself updating to match the user's text sometimes lags, or requires the user to close the scene and reopen it to trigger the update. Those seem to happen after duplication, but closing and reopening fixes it. Most of the time.

Also, this currently relies on distinct materials for each *QuadLabel* (since each one requires a `Viewport`). This can negatively impact performance - VERY BADLY! In addition, there's currently no alpha support. There's just no real alternative right now...

### Configurables

##### Label Text
The label text. Supports multiple lines - good luck trying to fit them!

##### Quad Size
The size of the quad mesh. As this expands or shrinks, the label will *attempt* to stay in the middle. However, it tends to go wrong when the *Quad Size* shrinks below the size of the displayed text. Be wary!

##### GUI Scale
To help control the size of the *Label Text*, the *GUI Scale* configurable is provided. This allows for separate scaling of the text up and down, independent of *Quad Size*. 

This scale metric is actually opposite of what you might expect - the higher the scale, the smaller the text. That's just a quirk of implementation and I really can't be bothered to fix it.