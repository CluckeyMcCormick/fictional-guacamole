import pyglet
import game_state

class AState(game_state.GameState):
    """docstring for AState"""
    def __init__(self, window):
        super(AState, self).__init__(window)
        self.batch = pyglet.graphics.Batch()
        self.fps_display = pyglet.window.FPSDisplay(self.window)

        # Load the image, set the anchor to the middle
        self.image = pyglet.resource.image("A.png")
        self.image.anchor_x = self.image.width // 2
        self.image.anchor_y = self.image.height // 2

        # Place the image anchor in the middle of the image
        x = self.window.width  // 2
        y = self.window.height // 2
        # Create a sprite
        self.sprite = pyglet.sprite.Sprite(self.image, x=x, y=y, batch=self.batch)

    def start(self):
        self.is_spin = True
        pyglet.clock.schedule_interval(self.spin_sprite, 1/60.0)

        # Call the super, to push the handlers 
        super(AState, self).start()

    def on_draw(self):
        self.window.clear()
        self.batch.draw()
        self.fps_display.draw()

    def on_key_press(self, symbol, modifiers):
        if symbol == pyglet.window.key.Z:
            self.is_spin = not self.is_spin 
            
    def spin_sprite(self, dt):
        if self.is_spin:
            self.sprite.rotation = (self.sprite.rotation + (dt * 200)) % 360
