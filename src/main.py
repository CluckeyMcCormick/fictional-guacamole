
import pyglet

import load_screens 
import city

window = pyglet.window.Window(width=1000, height=600)

# Set where we'll be loading assets from
pyglet.resource.path.append('@city.world.assets')
pyglet.resource.path.append('@load_screens.assets')
pyglet.resource.reindex()

# Make sure the window is ready to handle switch state events
window.register_event_type('switch_state')

current_state = load_screens.CircleLoadScreen(
    window, city.city_state.CityState(window, 400, 400, use16=False)#1024, 1024) #16, 16)
)

@window.event
def switch_state(new_state):

    # Ensure we are changing the correct state
    global current_state

    # Stop the current state
    current_state.stop()
    current_state._stop()
    # Switch to a new state
    current_state = new_state
    # Start the new state
    current_state._start()
    current_state.start()

if __name__ == '__main__':
    current_state._start()
    current_state.start()
    pyglet.app.run()