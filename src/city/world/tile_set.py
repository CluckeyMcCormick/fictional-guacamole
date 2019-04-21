
import collections
import enum

class TileEnum(enum.Enum):
    def __new__(cls, index, is_animation):
        obj = object.__new__(cls)
        # Assign an aribitrary value for value
        obj._value_ = len(cls.__members__)
        obj._index_ = index
        obj._is_animation_ = is_animation

        return obj

    @property
    def is_animation(self):
        # Hide the is_animation value behind a property
        return self._is_animation_

    @property
    def index(self):
        # Hide the index value behind a property
        return self._index_

    @property
    def image_path(self):
        message = "Image path not provided for class {0}".format( type(self) )
        raise NotImplementedError(message)

class TileSet(object):
    """
    The TileSet takes in tile assets enumerations and assigns each value an
    aribtrary integer designation. It then loads the appropriate image for each
    tile set.

    Thus, TileSet acts as a bridge/meeting point for three separate but closely
    integrated concepts:
        - The actual renderable image for each tile 
        - The integer designation for parallelization (i.e. in world raw)
        - The enumeration that describes how to access the tile from its image
          and gives each tile a programmable name.

    We title these three concepts as:
        - Image
        - Designate
        - Enum

    * Using an arbitrary designation allows for easy expansion of the tileset
    if we want to add more tiles to a "set" but don't want to change the
    associated image (hopefully this will be ideal for mods).  

    * Assigning arbitrary designations also means we can keep our definition of
    the asset's structure separate from how we track it semantically
    """
    def __init__(self, *load_funcs):
        """
        Each instance of load_funcs should be an assets load function.
        """
        super(TileSet, self).__init__()
        # Contains the full images, if we need them
        self._image_dict = {}
        # Contains the ImageGrids, which we need
        self._grid_dict = {}
        # The enumeration dict, which contains all our enumerated tiles
        self._enum_dict = {}
        # An opposite-mirror dict of _enum_dict;
        # maps arbitrary designations to enumerations, instead of vice versa
        self._designate_dict = {}

        self.add_tiles(*load_funcs)

    def add_tiles(self, *load_funcs):
        for f_load in load_funcs:
            image, grid, enums, path = f_load()

            self._image_dict[path] = image
            self._grid_dict[path] = grid

            # For each enum class we get...
            for e in enums:
                # For each enumeration under that...
                for current in (e):
                    # Assign it the next value
                    next_val = len(self._enum_dict)
                    self._enum_dict[current] = next_val
                    self._designate_dict[next_val] = current

    def __len__(self):
        return len(self._enum_dict)

    def get_image(self, key):
        """
        Get an image slice for the given designate or enum.
        """
        if key in self._designate_dict:
            enum = self._designate_dict[key]
        else:
            enum = key

        return self._grid_dict[enum.image_path][enum.index]
        
    def get_designate(self, enum):
        """
        Get a designate for the given enum.
        """
        return self._enum_dict[enum]

    def get_enum(self, designate):
        """
        Get a enum for the given designate.
        """
        return self._designate_dict[designate]

    #
    # A class within a class - A SEMI-PRIVATE CLASS!
    #
    class TileSetPicklable(object):
        """
        A picklable version of TileSet that excludes image files.
        """
        def __init__(self, _enum_dict, _designate_dict):
            self._enum_dict = _enum_dict
            self._designate_dict = _designate_dict

        def get_designate(self, enum):
            return self._enum_dict[enum]

        def get_enum(self, designate):
            return self._designate_dict[designate]
    #

    def get_picklable(self):
        return self.TileSetPicklable(self._enum_dict, self._designate_dict)
