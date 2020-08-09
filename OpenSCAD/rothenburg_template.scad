/*
    We divide the house into four components: the foundation, the lower walls,
    the upper walls, and the roof.
    
    The foundation is a flat layer that serves to define the building's
    footprint, and acts as a testament that the building once stood at all.
    
    The lower walls are the base for the upper walls, and are meant to be
    thicker and hardier. Stone to support the wood.

    The upper walls are moderately thinner than the lower walls, and are
    supposed to be stone, timber, or brick covered in plaster.
*/
/*
    To help keep things consistent, we'll define a set of constants and re-use
    them throughout.
    
    Here are some constants that AREN'T defined:
        - The "open" ends of the house's roof is always on the x-axis (so,
          looking up and down the y-axis, you see no gap)
        - The door is always centered on the X-axis, and sits ON the X-axis
          itself (the y-intercept, if you will)
*/
// What are the lengths of our foundation, per axis?
Y_FOUNDATION_LEN = 5;
X_FOUNDATION_LEN = 10;

// How tall is our foundation?
FOUNDATION_HEIGHT = .1;

// How thick are the lower walls?
LOWER_WALL_THICKNESS = .5;

// How tall are the lower walls? Keep in mind that this will be placed on TOP of
// the foundation
LOWER_WALL_HEIGHT = 1;

// How thick are the upper walls? This thickness will be centered around the
// lower walls, so that half of the thickness is on either half of the
// lower walls
UPPER_WALL_THICKNESS = .5;

// How tall are the upper walls? These walls will be placed on top of the lower
// walls; this height value is just the measure of the height of the components.
UPPER_WALL_HEIGHT = 2;

// The roof is distinctively peaked - what is the height of that peak? Keep in
// mind, this is just a measure of the roof component's height. This will be
// placed on top of the foundation and BOTH sets of walls!
ROOF_PEAK_HEIGHT = 5;

// The roof kinda peaks out on either side of the x and y axes. How far does it
// peak out from? The final roof will be the foundation size PLUS these values,
// where the overhang is doubled.
ROOF_X_OVERHANG = .5;
ROOF_Y_OVERHANG = .5;

// To create a "Divot" either side of the roof's x length, we create
// triangular prisms on either end and 'sink' them, cutting them out from the
// greater triangle. How much do we sink the divot?
ROOF_DIVOT_OFFSET = 1;

// How wide is the door?
DOOR_WIDTH = 2;

// How tall is the door? Remember, the door sits atop the foundation!
DOOR_HEIGHT = 2;

// How tall is each window?
WINDOW_HEIGHT = 1.5;
// How wide is each window?
WINDOW_WIDTH = 1;
// How high up are the windows set from the lower wall?
WINDOW_OFFSET = .25;

assert(UPPER_WALL_THICKNESS <= LOWER_WALL_THICKNESS, "Thickness of the upper walls must be less than or equal the thickness of the lower walls!");

module right_triangular_prism(x_len, y_len, h){
    polyhedron(
        points=[
            [0,0,0], 
            [x_len,0,0],
            [x_len,y_len,0],
            [0,y_len,0], 
            [0,y_len,h],
            [x_len,y_len,h]
        ],
        faces=[
            [0,1,2,3],
            [5,4,3,2],
            [0,4,5,1],
            [0,3,4],
            [5,2,1]
        ]
    );
}
//

module isosceles_triangular_prism(x_len, y_len, height){
    polyhedron(
        points=[
            [    0,     0,      0], 
            [x_len,     0,      0],
            [x_len, y_len,      0],
            [    0, y_len,      0], 
            [    0, y_len / 2, height],
            [x_len, y_len / 2, height]
        ],
        faces=[
            [0,1,2,3],
            [5,4,3,2],
            [0,4,5,1],
            [0,3,4],
            [5,2,1]
        ]
    );
}
//

// Create the foundation, which is really just a blank square
module foundation(){
    cube( [X_FOUNDATION_LEN, Y_FOUNDATION_LEN, FOUNDATION_HEIGHT] );
}
//

// The door isn't a door so much as an empty space carved into the walls. To
// carve out the door, we need a block to carve with - this is that block.
module door_spacing_block(){
    centering_translation = [
        (X_FOUNDATION_LEN / 2) - (DOOR_WIDTH / 2), 
        -LOWER_WALL_THICKNESS / 2,
        FOUNDATION_HEIGHT
    ]; 
    
    translate(centering_translation)
    cube( [DOOR_WIDTH, LOWER_WALL_THICKNESS * 2, DOOR_HEIGHT] );
}
//

module window_carving_block(){
    translate([0, 0, FOUNDATION_HEIGHT + LOWER_WALL_HEIGHT + WINDOW_OFFSET])
    cube( [WINDOW_WIDTH, UPPER_WALL_THICKNESS * 2, WINDOW_HEIGHT] );
}
//

module window_carving_block_NEGY(){
    translate([1, 0, 0])
    window_carving_block();
    translate([2.25, 0, 0])
    window_carving_block();
    translate([6.75, 0, 0])
    window_carving_block();
    translate([8, 0, 0])
    window_carving_block();
}
//
module window_carving_block_POSY(){
    y_move = Y_FOUNDATION_LEN - UPPER_WALL_THICKNESS;
    x_move = 3.25;

    translate([x_move, y_move, 0])
    window_carving_block();
    translate([x_move + 1.25, y_move, 0])
    window_carving_block();
    translate([x_move + 2.5, y_move, 0])
    window_carving_block();
}
//

module window_carving_block_NEGX(){
    y_move = -1;
    x_move = .75;
    rotate([0, 0, 90])
    union(){
        translate([x_move, y_move, 0])
        window_carving_block();
        translate([x_move + 1.25, y_move, 0])
        window_carving_block();
        translate([x_move + 2.5, y_move, 0])
        window_carving_block();
    };
}
//

module window_carving_block_POSX(){
    y_move = -1;
    x_move = .75;
    
    translate([X_FOUNDATION_LEN - UPPER_WALL_THICKNESS, 0, 0])
    rotate([0, 0, 90])
    union(){
        translate([x_move, y_move, 0])
        window_carving_block();
        translate([x_move + 1.25, y_move, 0])
        window_carving_block();
        translate([x_move + 2.5, y_move, 0])
        window_carving_block();
    };
}
//

// Makes the lower walls, without a door. This is important, since we have to
// carve the space for the door out of something
module lower_walls_doorless(){
    /*
        Consider a rectangle, A, that contains a rectangle, B, such that the
        edges of B are at a constant distance from each other (this might break
        down around the edges, because diagonals, but whatever). We'll call this
        constant distance C. We know that the length of A minus the 
        length of B equals 2 * C (since there's a C of difference on either
        side). This allows us to calculate:
    
        A = 2C + B
        B = A - 2C
        C = (A - B) / 2
    
        In this case, A is our foundation length, and C is the lower wall's
        thickness. The size of the room to carve, then, is B!
    */
    // For our initial carve, A is the Foundation length, and B is the Lower
    // Wall thickness.
    carve_factor_x = X_FOUNDATION_LEN - ( 2 * LOWER_WALL_THICKNESS);
    carve_factor_y = Y_FOUNDATION_LEN - ( 2 * LOWER_WALL_THICKNESS);
    
    // The walls are made by carving out a block from the center of a larger
    // block - how do we move that smaller block?
    carver_translation = [
        LOWER_WALL_THICKNESS, // Move by C
        LOWER_WALL_THICKNESS, // Move by C
        -LOWER_WALL_HEIGHT / 2
    ]; 
    
    translate([0, 0, FOUNDATION_HEIGHT])
    difference(){
        cube( [X_FOUNDATION_LEN, Y_FOUNDATION_LEN, LOWER_WALL_HEIGHT] );
        
        translate(carver_translation)
        cube( [carve_factor_x, carve_factor_y, LOWER_WALL_HEIGHT * 2 ]);
    }
}
//

// Makes the lower walls, without a door. This is important, since we have to
// carve the space for the door out of something
module upper_walls_doorless(){
    
    /*
        Now, with the Upper Wall, things get tricky. The wall must be centered
        on the lower wall. So, we have basically FOUR rectangles now instead of
        just two. We have the two rectangles we had for the lower walls, A and
        B, which are separated by a consistent distance, C. However, there are
        now two rectangles between them, that we'll call Q and R. Q and R are
        a new constant distance apart, D. Q is a consistent Distance from A,   
        which we'll call E, and R is the same with B; this shall the same value
        as E.
        
        In this case, our values are:
        A = FOUNDATION_LEN
        B = ???
        C = LOWER_WALL_THICKNESS
        D = UPPER_WALL_THICKNESS
        E = ???
        
        We know how to calculate C, but how about E? Well, we know that D is 
        centered ON C, and E is the leftover distance on either side - ergo,
        there'll be two of them. So, we know that C is:
        
        C = D + E2
        
        Solving for E, this becomes:
        
        E = (C - D) / 2
        
        Of course, we can't forget that E exists on both sides of EACH TRIANGLE!
        So the size of our first rectangle is (A - 2E). The carving rectangle
        will then be (A - 2(E + D)). To carve out the rectangle considering a
        start at origin, we need to shift the carving rectangle by the width of
        D
    */
    // What's the size of E from that giant stupid explanation we just did
    e_factor = (LOWER_WALL_THICKNESS - UPPER_WALL_THICKNESS) / 2;
    
    // A - 2 * E
    base_size_x = X_FOUNDATION_LEN - (2 * e_factor);
    base_size_y = Y_FOUNDATION_LEN - (2 * e_factor);
    
    // A - 2 * (E + D)
    carve_size_x = X_FOUNDATION_LEN - 2 * (e_factor + UPPER_WALL_THICKNESS);
    carve_size_y = Y_FOUNDATION_LEN - 2 * (e_factor + UPPER_WALL_THICKNESS);
    
    carve_shift= [
        UPPER_WALL_THICKNESS, // D
        UPPER_WALL_THICKNESS, // D
        -.1
    ];
    
    translate([e_factor, e_factor, FOUNDATION_HEIGHT + LOWER_WALL_HEIGHT])
    difference(){
        cube( [base_size_x, base_size_y, UPPER_WALL_HEIGHT] );
        
        translate(carve_shift)
        cube( [carve_size_x, carve_size_y, UPPER_WALL_HEIGHT + .2 ])
        ;
    }
}
//

module lower_walls(){   
    difference(){
        lower_walls_doorless();
        door_spacing_block();
    }
}
//

module upper_walls(){   
    difference(){
        upper_walls_doorless();
        door_spacing_block();
    }
}
//

module roof(){
    
    ROOF_BASE_HEIGHT = UPPER_WALL_HEIGHT + LOWER_WALL_HEIGHT + FOUNDATION_HEIGHT;
    
    difference(){
        difference() {
            translate([
                -ROOF_X_OVERHANG, 
                -ROOF_Y_OVERHANG, 
                ROOF_BASE_HEIGHT
            ])
            isosceles_triangular_prism(
                X_FOUNDATION_LEN + (ROOF_X_OVERHANG * 2), 
                Y_FOUNDATION_LEN + (ROOF_Y_OVERHANG * 2), 
                ROOF_PEAK_HEIGHT
            );
            
            translate([
                X_FOUNDATION_LEN,
                -ROOF_Y_OVERHANG,
                ROOF_BASE_HEIGHT - ROOF_DIVOT_OFFSET
            ])
            isosceles_triangular_prism(
                ROOF_X_OVERHANG, 
                Y_FOUNDATION_LEN + (ROOF_Y_OVERHANG * 2), 
                ROOF_PEAK_HEIGHT
            );
        };
        translate([
            -ROOF_X_OVERHANG,
            -ROOF_Y_OVERHANG,
            ROOF_BASE_HEIGHT - ROOF_DIVOT_OFFSET
        ])
        isosceles_triangular_prism(
            ROOF_X_OVERHANG, 
            Y_FOUNDATION_LEN + (ROOF_Y_OVERHANG * 2), 
            ROOF_PEAK_HEIGHT
        );
    };
}
//

// Upper walls, style01: No windows
module upper_walls_style(){   
    difference(){
        upper_walls_doorless();
        door_spacing_block();
        
        // Windows
        window_carving_block_NEGY();
        window_carving_block_POSY();
        window_carving_block_NEGX();
        window_carving_block_POSX();
    }
}
//

//color("#0B2545")
//lower_walls();
//color("#134074")
//upper_walls_style();
//color("#EEF4ED")
//foundation();
//color("#13315C")
roof();
