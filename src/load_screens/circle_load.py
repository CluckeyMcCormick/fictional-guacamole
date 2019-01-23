import pyglet
import game_state

class CircleLoadScreen(game_state.LoadState):

    def __init__(self, window, state_to_load):
        super(CircleLoadScreen, self).__init__(window, state_to_load)
        self.batch = pyglet.graphics.Batch()

        # Load the image, set the anchor to the middle
        self.image = pyglet.resource.image("circle.png")
        self.image.anchor_x = self.image.width // 2
        self.image.anchor_y = self.image.height // 2

        # Place the image anchor in the middle of the image
        x = self.window.width  // 2
        y = self.window.height // 2
        # Create a sprite
        self.sprite = pyglet.sprite.Sprite(self.image, x=x, y=y, batch=self.batch)
        self.text = pyglet.text.Label(
        	text="Loading, please wait...", x=x, y=y // 4, 
        	anchor_x="center", anchor_y="center",
        	font_size=25, color=(255, 0, 25, 255), batch=self.batch
        )

    def start(self):
        self.is_spin = True
        pyglet.clock.schedule_interval(self.spin_sprite, 1/60.0)

    def stop(self):
        pyglet.clock.unschedule(self.spin_sprite)

    def spin_sprite(self, dt):
        if self.is_spin:
            self.sprite.rotation = (self.sprite.rotation + (dt * 200)) % 360

    def on_draw(self):
        self.window.clear()
        self.batch.draw()