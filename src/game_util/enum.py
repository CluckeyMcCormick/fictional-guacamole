import enum

class CardinalEnum(enum.Enum):
    """
    Describes the different cardinal directions and provides (x,y) value shifts
    for ease of use. Also provides support for addition and subtraction so that
    a given direction can easily be rotated.
    """
    EAST  = 0, ( 1, 0)
    NORTH = 2, ( 0, 1)
    WEST  = 4, (-1, 0)
    SOUTH = 6, (0, -1)

    NORTH_EAST = 1, ( 1, 1)
    NORTH_WEST = 3, (-1, 1)
    SOUTH_WEST = 5, (-1,-1)
    SOUTH_EAST = 7, ( 1,-1)

    def __new__(cls, value, shift):
        obj = object.__new__(cls)
        obj._value_ = value
        obj.shift = shift

        return obj

    def __sub__(self, other):
        # Get the class
        typed = type(self)
        # Return enum with that value
        return typed( (self.value - other) % len(typed.__members__) ) 

    def __add__(self, other):
        # Get the class
        typed = type(self)
        # Return enum with that value
        # Return enum with that value
        return typed( (self.value + other) % len(typed.__members__) )