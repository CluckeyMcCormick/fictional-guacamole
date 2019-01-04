
import pyglet

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
        """
        The __init__ function should only be used for very basic, lightweight
        setup. Ideally, it should just be saving the variables that were passed
        in, and that's it.
        """

        super(GameState, self).__init__()
        self.window = window
    
    ###
    #
    # Required Functions
    #
    ###

    def load(self):
        """
        This is function is called repeatedly by a LoadState until it returns
        True. The idea is that you can use the repeated calls to load the state
        gradually, rather than just loading everything at once and locking up
        the program. Of course, you could also just load everything at once and
        lock up the program.
        """
        return True

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

    ###
    #
    # Event Handlers
    #
    ###

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


class LoadState(object):
    """
    A state to load other states - for loading screens and the like. 

    Try and keep this as lightweight as possible; these loading screens don't
    get loading screens.
    """

    def __init__(self, window, state_to_load):
        super(LoadState, self).__init__()
        self.window = window
        self.state_to_load = state_to_load

    def start(self):
        """
        Once the state has been set to **this** GameState, this function is
        called. Ideally, this should be where the various logic functions for
        your GameState are scheduled.
        """
        # Schedule the load process
        pyglet.clock.schedule_interval(self.interval_load, 1/60.0)
        
        self.window.push_handlers(self.on_draw)

    def stop(self):
        pass

    def interval_load(self, dt):
        # If our state finishes loading
        if self.state_to_load.load():
            # Unschedule this load function
            pyglet.clock.unschedule(self.interval_load)
            # Switch the states
            self.window.dispatch_event('switch_state', self.state_to_load)
        
    ###
    #
    # Event Handlers
    #
    ###

    def on_draw(self):
        """
        This is where the window should be cleared and the batches should be 
        redrawn.
        """
        pass