
import pyglet
import sample_state

window = pyglet.window.Window(width=1000, height=600)

# Set where we'll be loading assets from
pyglet.resource.path.append('../assets/')
pyglet.resource.reindex()

if __name__ == '__main__':
    print("Main is running!")
    state = sample_state.AState(window)
    state.start_state()
    pyglet.app.run()