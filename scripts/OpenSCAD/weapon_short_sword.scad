/*
    Apparently, there is a great body of work (deemed typology) that covers
    what swords looked like at specific periods and the transitions between
    different styles of sword. Given the technology level we're going for, we
    should really go for a style of sword that reflects the (European) late
    medieval to early renaissance period.
    
    However, I really don't feel like doing that so I'm just going to mix and
    match whatever I feel like until it looks like a sword.
*/
/*
    Our sword has the following components:
        
        - Pommel, the cap at the end of the grip
        
        - Grip, the handle
        
        - Guard, bar to protect the hand
        
        - Blade, the actual content/matter of the sword. We're gonna go with a
          hexagonal cross section, since that's what will be the easiest to
          model. The blade will also feature a fuller, which is a sort of
          groove that slips through the matter of the blade and apparently
          makes it lighter or something; here it will mostly add visual texture
          to the blade. The blade has several subcomponents:
          - The Edge, the honed edges of the blade
          - The Tip, the blade and the edges shaped into a curve
          - The Fuller, a groove in the blade that serves to lighten the
            blade but here will mostly serve to give the blade some sense of 
            texture.
*/
/*
    To help keep things consistent, we'll define a set of constants and re-use
    them throughout.
    
    Here are some constants that AREN'T defined:
        - The length of the blade extends on the X axis.
        - The width of the blade extends up-and-down on the Z axis, meaning
          the sword is effectively mirrored across the X-Y plane.
        - The thickness of the blade is on the Y axis.
        - The model's origin is the middle of the grip. This is done to make
          posing and rotations with another model very easy.
    
    All constants are in world units.
*/
// How long is the grip? Since this is a short sword, it should match the
// hand height/width of the intended user.
GRIP_HEIGHT = 0.1;
// The grip is a cylinder. What's the radius of that cylinder?
GRIP_RADIUS = 0.025;
// We need to specify how many faces the grip has. How many faces does it
// have?
GRIP_FACES = 30;

// The pommel is a flattened disc - in other words, a FAT cylinder. What's
// the thickness of the pommel?
POMMEL_THICKNESS = 0.05;
// What's the radius of the pommel-disc?
POMMEL_RADIUS = 0.05;
// We need to specify how many faces the pommel has. How many faces does
// it have?
POMMEL_FACES = 30;
// We try and position the pommel so it's tangent with the grip. This might
// not actually look good, so this constant allows us to shift the grip
// forward or backward.
POMMEL_Y_SHIFT = 0.01;

// How thick is the hand/cross guard? In other words, length on X.
GUARD_THICKNESS = .065;
// How long is the guard along the length of the sword? In other words, how
// long on Y?
GUARD_LENGTH = .025;
// How wide is the guard? In other words, how long on Z?
GUARD_WIDTH = .2;

// How long is the blade, base to tip? This was based on a kind of complex
// calculation - we currently have a Pawn model thats ~1.57 world units
// tall. World units are 1:1 with meters, so we can convert this to about 62
// inches, or 5'2". The blade enthusiasts of the world (in this case,
// shopwushu.com) have ACTUAL SIZE RECOMMENDATION CHARTS for blade length,
// so we can check against that and get a recommended length of 28 inches,
// which translates to 0.7112 meters.
BLADE_LENGTH = 0.7112;
// How thick is the blade - how long is the length on X?
BLADE_THICKNESS = .0425;
// How wide is the blade - how long is the length on Z?
BLADE_WIDTH = 0.125;

// How wide is the edge of the blade? Keep in mind that the edge appears on
// all sides of the blade, but this value only measures the edge at any one
// given point.
EDGE_WIDTH = .0375;

// Carving a tip with an edge is actually surprisingly complicated, and not
// as precise as we would necessarily want. The technique involves creating
// a complex carving structure, and then using difference to carve said tip.

// The inset controls where the tip is carved - there's some wiggle room
// forward or backward. Negative values move the tip towards the
// guard/grip/pommel.
TIP_INSET = -EDGE_WIDTH * 2 + .013;
// We use a rotation-extrusion to create the carver. How many faces make up
// the rotation-extrusion? More faces will result in a more circular curve.
TIP_CARVER_FACES = 5;

// The width of the fuller
FULLER_WIDTH = EDGE_WIDTH * 0.85;
// The depth of the fuller, on either side of the blade. Too deep and the blade
// will become a two-pronged poker!
FULLER_DEPTH = BLADE_THICKNESS / 6;
// The fuller is carved using a cylinder. How many faces does that cylinder have?
// More faces means a smoother, more circular fuller.
FULLER_FACES = 4;

// The GRIP
module grip(){
    rotate([90, 0, 0])
    cylinder(h=GRIP_HEIGHT, r=GRIP_RADIUS, center=true, $fn=GRIP_FACES);
}
//

// The POMMEL
module pommel(){
    translate([0, (-GRIP_HEIGHT / 2) - POMMEL_RADIUS + POMMEL_Y_SHIFT, 0])
    rotate([0, 90, 0])
    cylinder(h=POMMEL_THICKNESS, r=POMMEL_RADIUS, center=true, $fn=POMMEL_FACES);
}
//

// The GUARD
module guard(){
    translate([0, (GRIP_HEIGHT / 2) + (GUARD_LENGTH / 2), 0])
    cube(size=[GUARD_THICKNESS, GUARD_LENGTH, GUARD_WIDTH], center=true);
}
//

// The BLADE
module edge_shape(){
    
    X_OUTER_POINT = BLADE_WIDTH / 2;
    X_INNER_POINT = (BLADE_WIDTH / 2) - EDGE_WIDTH;
    
    translate([0, GRIP_HEIGHT / 2 + GUARD_LENGTH, 0])
    rotate([0, 90, 90])
    union(){
        // Left (-X) side
        linear_extrude(height = BLADE_LENGTH, center = false)
        polygon(
            points =[
                [-X_OUTER_POINT, 0],
                [-X_INNER_POINT,  BLADE_THICKNESS / 2],
                [-X_INNER_POINT, -BLADE_THICKNESS / 2]
            ],
            paths = [[0, 1, 2]],
            convexity = 10
        );
        // Right (+X) side
        linear_extrude(height = BLADE_LENGTH, center = false)
        polygon(
            points =[
                [X_OUTER_POINT, 0],
                [X_INNER_POINT,  BLADE_THICKNESS / 2],
                [X_INNER_POINT, -BLADE_THICKNESS / 2]
            ],
            paths = [[0, 1, 2]],
            convexity = 10
        );
    }
}
module core_blade(){
    union(){//
        translate([0, (GRIP_HEIGHT / 2) + GUARD_LENGTH + (BLADE_LENGTH / 2), 0])
        cube(
            size=[BLADE_THICKNESS, BLADE_LENGTH, BLADE_WIDTH - (EDGE_WIDTH * 2)],
            center=true
        );
        edge_shape();
    }
   
}
module tip_carver(){
    X_OUTER_POINT = BLADE_WIDTH / 2;
    X_INNER_POINT = (BLADE_WIDTH / 2) - EDGE_WIDTH;
    
    translate([0, TIP_INSET, 0])
    translate([0, (GRIP_HEIGHT / 2) + GUARD_LENGTH + BLADE_LENGTH, 0])
    rotate([0, 90, 0])
    rotate_extrude(angle = 180, $fn=TIP_CARVER_FACES)
    polygon(
        points =[
            // Shape 01: Rectangle that's way too big
            [X_OUTER_POINT * 2,  BLADE_THICKNESS],
            [X_INNER_POINT,  BLADE_THICKNESS],
            [X_INNER_POINT, -BLADE_THICKNESS],
            [X_OUTER_POINT * 2, -BLADE_THICKNESS],
            // Shape 02: Normal triangle points
            [X_OUTER_POINT,  BLADE_THICKNESS / 2], //4
            [X_INNER_POINT,  BLADE_THICKNESS / 2],
            [X_INNER_POINT, -BLADE_THICKNESS / 2],
            [X_OUTER_POINT, -BLADE_THICKNESS / 2],
            [X_OUTER_POINT, 0],
        ],
        // Build out the rectangle and extract the small triangle
        paths = [[0, 1, 2, 3], [5, 6, 8]],
        convexity = 10
    );
}
module fuller_carver(){
    translate([0, (GRIP_HEIGHT / 2) + GUARD_LENGTH, 0])
    rotate([-90, 90, 0])
    union(){
        translate([0, BLADE_THICKNESS / 2, 0])
        scale([FULLER_WIDTH, FULLER_DEPTH * 2, BLADE_LENGTH])
        cylinder(h=1, r=0.5, $fn=FULLER_FACES);
        translate([0, -BLADE_THICKNESS / 2, 0])
        scale([FULLER_WIDTH, FULLER_DEPTH * 2, BLADE_LENGTH])
        cylinder(h=1, r=0.5, $fn=FULLER_FACES);
    }
}
module complete_blade(){
    difference(){
        difference(){
            core_blade();
            tip_carver();
        }
        fuller_carver();
    }
}
//

grip();
pommel();
guard();
complete_blade();
//fuller_carver();
//tip_carver();