
from pyglet import gl, graphics

class RepeatingTextureTile(object):
    """
    A very barebones renderable class. Creates a rectangle, puts it in the
    provided batch, and renders it using the provided tex_group for texture.

    This class is meant to give different functionality from the Sprite class
    in a couple of key ways:

    1. It allows for textures to be repeated at set intervals, rather than
    scaling the texture to match the size

    2. It derives it's texture PURELY from the provided TextureGroup. This
    allows us to change the sprite/image/texture of something en masse rather
    than by iterating over everything we need to change. EFFICIENT!
    """
    def __init__(self, pos, sizes, tex_steps, tex_group, batch):
        """
        Creates the RepeatingTextureTile, to the user's specifications.

        Inputs:
        
        pos: a tuple, containing the x,y position of the tile. This is the
        position of the lower left corner.
        
        sizes: a tuple, containing the length on x and the length on y of the
        tile.
        
        tex_steps: a tuple, containing the repeat distance on x and y. Ideally,
        this should match the x and y length of whatever the texture in
        tex_group is. Here's an example - if we pass this value as (16, 16),
        and sizes as (32, 32), the tile will be repeated twice on each axis
        (and four overall).

        tex_group: a pyglet.graphics.Group object. Ideally, this should be a
        pyglet.graphics.TextureGroup object, since this is where we grab our 
        texture from. As long as the appropriate texture is set somewhere in
        the group hierarchy, it should work.

        batch: a pyglet.graphics.Batch object. This will be the object's batch.
        """
        super(RepeatingTextureTile, self).__init__()

        self.x, self.y = pos
        self.x_len, self.y_len = sizes
        self.x_step, self.y_step = tex_steps
        self.tex_group = tex_group

        x_tex_dist = self.x_len / self.x_step
        y_tex_dist = self.y_len / self.y_step

        self._vert_list = batch.add_indexed(
            4, gl.GL_TRIANGLES, tex_group,
            [0, 1, 2, 0, 2, 3],
            ('v2i', (self.x,              self.y,
                     self.x + self.x_len, self.y,
                     self.x + self.x_len, self.y + self.y_len,
                     self.x,              self.y + self.y_len)
            ),
            ("t2f", (0.0,        0.0,
                     x_tex_dist, 0.0,
                     x_tex_dist, y_tex_dist,
                     0.0,        y_tex_dist)
            )
        )

        self.batch = batch

    def update_data(self, pos=None, sizes=None, tex_steps=None, tex_group=None):
        """
        Updates the shape using the given parameters. Any None values are
        ignored.

        Inputs:
        
        pos: a tuple, containing the x,y position of the tile. This is the
        position of the lower left corner.
        
        sizes: a tuple, containing the length on x and the length on y of the
        tile.
        
        tex_steps: a tuple, containing the repeat distance on x and y. Ideally,
        this should match the x and y length of whatever the texture in
        tex_group is. Here's an example - if we pass this value as (16, 16),
        and sizes as (32, 32), the tile will be repeated twice on each axis
        (and four overall).

        tex_group: a pyglet.graphics.Group object. Ideally, this should be a
        pyglet.graphics.TextureGroup object, since this is where we grab our 
        texture from. As long as the appropriate texture is set somewhere in
        the group hierarchy, it should work.
        """
        if pos is not None or sizes is not None:     
            if pos is not None:
                self.x, self.y = pos

            if sizes is not None:
                self.x_len, self.y_len = sizes

            self._vert_list.vertices = [
                self.x,              self.y,
                self.x + self.x_len, self.y,
                self.x + self.x_len, self.y + self.y_len,
                self.x,              self.y + self.y_len
            ]

        if tex_steps is not None:
            self.x_step, self.y_step = tex_steps
            x_tex_dist = self.x_len / self.x_step
            y_tex_dist = self.y_len / self.y_step
            self._vert_list.tex_coords = [
                0.0,        0.0,
                x_tex_dist, 0.0,
                x_tex_dist, y_tex_dist,
                0.0,        y_tex_dist
            ]

        if tex_group is not None:
            self.tex_group = tex_group

            self.batch.migrate(
                self._vert_list, gl.GL_TRIANGLES, self.tex_group, self.batch
            )


    def batch_migrate(self, new_batch):
        """
        Migrates the object to the provided batch.

        Inputs:
        
        batch: a pyglet.graphics.Batch object. This will be the object's batch.
        """
        self.batch.migrate(
            self._vert_list, gl.GL_TRIANGLES, self.tex_group, new_batch
        )
        self.batch = new_batch

class BasicTile(RepeatingTextureTile):
    """
    A derivative of RepeatingTextureTile. Calculates the texture step, so that
    you don't have to.
    """
    def __init__(self, pos, sizes, tex_group, batch):
        """
        Creates the RepeatingTextureTile, to the user's specifications.

        Inputs:
        
        pos: a tuple, containing the x,y position of the tile. This is the
        position of the lower left corner.
        
        sizes: a tuple, containing the length on x and the length on y of the
        tile.

        tex_group: a pyglet.graphics.Group object. Ideally, this should be a
        pyglet.graphics.TextureGroup object, since this is where we grab our 
        texture from. As long as the appropriate texture is set somewhere in
        the group hierarchy, it should work.

        batch: a pyglet.graphics.Batch object. This will be the object's batch.
        """
        super(BasicTile, self).__init__(
            pos, sizes, 
            (tex_group.texture.width, tex_group.texture.height),
            tex_group, batch
        )
        
    def update_data(self, pos=None, sizes=None, tex_group=None):
        """
        Updates the shape using the given parameters. Any None values are
        ignored.

        Inputs:
        
        pos: a tuple, containing the x,y position of the tile. This is the
        position of the lower left corner.
        
        sizes: a tuple, containing the length on x and the length on y of the
        tile.

        tex_group: a pyglet.graphics.Group object. Ideally, this should be a
        pyglet.graphics.TextureGroup object, since this is where we grab our 
        texture from. As long as the appropriate texture is set somewhere in
        the group hierarchy, it should work.
        """
        steps = None
        
        if tex_group is not None:
            steps = (tex_group.texture.width, tex_group.texture.height)

        super(BasicTile, self).update_data(
            pos=pos, sizes=sizes, tex_steps=steps, tex_group=tex_group
        )

