# Animations

These scripts are used to animation the pawn. They generally consist of a series of pose functions, which are then tied together into an Animation class and animated using our utility function.

## Included Scripts

### `basic_walk.py`
The basic walk cycle. I don't think it's very good but it's BEST quality is its functionality - and it is very functional.

### `righthand_horizontal_sweep.py`
A left-to-right sweep of the right arm. Designed with a sword in mind; but any one handed weapon will suffice (provided it is placed appropriately in the Pawn's hand).

### `righthand_stab.py`
A forward move of the right arm, with the hand rotating so the angle is basically constant. Designed with a sword in mind; but any (pointed) one handed weapon will suffice (provided it is placed appropriately in the Pawn's hand).

### `righthand_chop.py`
A top-to-bottom move of the right arm, with the hand rotating so the angle is basically constant. Designed with a sword in mind; but any one handed weapon will suffice (provided it is placed appropriately in the Pawn's hand).

### `fall.py`
A static pose that's meant to be our fall animation. This is one is incredibly lazy, I'll admit it. Animation is not my strong suit, my passion, or even a passing interest.

### `flee.py`
An animation for whenever the Pawn is fleeing in terror from something. Just the walk animation, but now with the addition of some flailing arms it's a bit different. This is the first one where the Pawn has Pac-man arms, mostly because I'm lazy.