
import enum

def run():
    class CLSPrinter(enum.Enum):
        def __new__(cls, *args):
            value = len(cls.__members__)
            obj = object.__new__(cls)

            print("in_arg: ", args)

            obj._value_ = value
            obj._args_ = args
            return obj

    class FirstEnum(CLSPrinter):
        RED = 0, 1, 3
        BLU = (2, 3)
        GRN = (4, 5)
    
    for en in FirstEnum:
        print(en.value, en._value_, en._args_)

    class IntPrinter(enum.Enum):
        def __new__(cls, *args):
            value = len(cls.__members__)
            obj = object.__new__(cls)

            obj.a, obj.b, obj.c = args

            obj._value_ = value
            obj._args_ = args
            obj._cls_ = cls

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
            return typed( (self.value + other) % len(typed.__members__) ) 

    class SecondEnum(IntPrinter):
        RED = 0, 1, 3
        BLU = 2, 4, 6
        GRN = 5, 7, 8
    
    en = SecondEnum.RED

    for _ in range( 5 ):
        print(en)
        en += 1

    print("\n~~~~~~~~~~~~~~~~~~~~~~~~\n~~~~~~~~~~~~~~~~~~~~~~\n")

    for _ in range( 5 ):
        print(en)
        en -= 1
   
    print(en.name)
    en._name_ = "JERRU"
    print(en.name)
