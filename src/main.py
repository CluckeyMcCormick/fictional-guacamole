
import pyglet

window = pyglet.window.Window(width=1000, height=600)
batch = pyglet.graphics.Batch()
fps_display = pyglet.window.FPSDisplay(window)

# Set where we'll be loading assets from
pyglet.resource.path.append('../assets/')
pyglet.resource.reindex()

# Load the image, set the anchor to the middle
image = pyglet.resource.image("A.png")
image.anchor_x = image.width // 2
image.anchor_y = image.height // 2

# Place the image anchor in the middle of the image
x = window.width  // 2
y = window.height // 2
# Create a sprite
sprite = pyglet.sprite.Sprite(image, x=x, y=y, batch=batch)

# Spin the sprite
def spin_sprite(dt):
    sprite.rotation = (sprite.rotation + (dt * 200)) % 360

@window.event
def on_draw():
    window.clear()
    batch.draw()
    fps_display.draw()

if __name__ == '__main__':
    print("Main is running!")
    pyglet.clock.schedule_interval(spin_sprite, 1/60.0)
    pyglet.app.run()