
import pyglet

import sample_state
import pop_in

window = pyglet.window.Window(width=1000, height=600)

# Set where we'll be loading assets from
pyglet.resource.path.append('../assets/')
pyglet.resource.reindex()

# Make sure the window is ready to handle switch state events
window.register_event_type('switch_state')

current_state = pop_in.load_screen.CircleLoadScreen(
    window, sample_state.AState(window)
)

@window.event
def switch_state(new_state):
    
    # Ensure we are changing the correct state
    global current_state

    # Stop the current state
    current_state.stop()
    # Switch to a new state
    current_state = new_state
    # Start the new state
    current_state.start()

if __name__ == '__main__':
    print("Main is running!")
    current_state.start()
    pyglet.app.run()