
class GameState(object):
    """
    The GameState represents an isolatable, swappable state in the simulation;
    like a menu or a particular mode of play.

    Pyglet has certain core functions - detecting key presses & releases, 
    drawing the screen - that are tied to the event handling functions
    (@window.event). In addition, Pyglet doesn't have a core loop outside of
    the draw method; instead, we need to schedule our own logic with
    *schedule_interval* and *schedule*.

    The game state architecture (should) fix these issues. Each state will be
    responsible for:

        * scheduling and closing it's own functions

        * managing it's own draw method

        * resolving it's own input

    See:

    https://pyglet.readthedocs.io/en/latest/modules/clock.html

    """
    def __init__(self, window):
        super(GameState, self).__init__()
        self.window = window
        
    def start(self):
        """
        Once the state has been set to **this** GameState, this function is
        called. Ideally, this should be where the various logic functions for
        your GameState are scheduled.
        """
        # Push these event handlers
        # Try and do this last; pushing handlers too early can cause a race
        # condition (far as I can tell) 
        self.window.push_handlers(
            self.on_draw, self.on_key_press, self.on_key_release,
            self.on_mouse_motion, self.on_mouse_press, self.on_mouse_release,
            self.on_mouse_drag
        )

    def on_draw(self):
        """
        This is where the window should be cleared and the batches should be 
        redrawn.
        """
        pass

    def on_key_press(self, symbol, modifiers):
        """
        Event handler for when a key is pressed. *symbol* is the key that was
        pressed; *modifiers* are keys like *ctrl* or *shift*.

        For more information, see:

        https://pyglet.readthedocs.io/en/latest/modules/window_key.html

        https://pyglet.readthedocs.io/en/latest/programming_guide/quickstart.html#handling-mouse-and-keyboard-events
        """
        pass

    def on_key_release(self, symbol, modifiers):
        """
        Event handler for when a key is pressed. *symbol* is the key that was
        released; *modifiers* are keys like *ctrl* or *shift*.

        For more information, see:

        https://pyglet.readthedocs.io/en/latest/modules/window_key.html

        https://pyglet.readthedocs.io/en/latest/programming_guide/quickstart.html#handling-mouse-and-keyboard-events
        """
        pass

    def on_mouse_motion(self, x, y, dx, dy):
        """
        Event handler for the mouse moving. *x* and *y* are the position after
        movement, with (0,0) at the bottom left of the screen. *dx* and *dy* 
        are the change in position.

        For more information, see:

        https://pyglet.readthedocs.io/en/latest/programming_guide/mouse.html?#mouse-events
        """
        pass

    def on_mouse_press(self, x, y, button, modifiers):
        """
        Event handler for when a mouse button is pressed. *x* and *y* are the
        position of the mouse, with (0,0) at the bottom left of the screen.
        *button* is the mouse button that was pressed; *modifiers* are keys
        like *ctrl* or *shift*.

        For more information, see:

        https://pyglet.readthedocs.io/en/latest/programming_guide/mouse.html?#mouse-events
        """
        pass

    def on_mouse_release(self, x, y, button, modifiers):
        """
        Event handler for when a mouse button is released. *x* and *y* are the
        position of the mouse, with (0,0) at the bottom left of the screen.
        *button* is the mouse button that was pressed; modifiers are keys like
        *ctrl* or *shift*.

        For more information, see:

        https://pyglet.readthedocs.io/en/latest/programming_guide/mouse.html?#mouse-events
        """
        pass

    def on_mouse_drag(self, x, y, dx, dy, buttons, modifiers):
        """
        Event handler for a click-and-drag with the mouse. *x* and *y* are the 
        position after movement, with (0,0) at the bottom left of the screen.
        *dx* and *dy* are the change in position. *button* is the mouse button
        that was pressed; modifiers are keys like *ctrl* or *shift*.

        For more information, see:

        https://pyglet.readthedocs.io/en/latest/programming_guide/mouse.html?#mouse-events
        """
        pass

    def stop(self):
        """
        Before the state is changed from **this** state, this function is
        called. Ideally, this is where cleanup from the previous state should
        be performed.
        """
        # Remove the object's event handlers
        # BE CAREFUL - IF YOU PUSHED ADDITIONAL EVENTS, AND DON'T POP THEM,
        # THIS CODE WILL CAUSE PROBLEMS
        self.window.pop_handlers()
        pass

    def issue_switch_state(self, new_state):
        """
        Issues a state switch event, which the engine will then handle.
        Always has to be the same, so I figured we can save time by
        providing this method
        """
        self.window.dispatch_event('switch_state', new_state)
