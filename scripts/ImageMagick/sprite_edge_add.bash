
# ~~~~~~~~~~~~~~~~~~~~
# Step 0: Script Setup
# ~~~~~~~~~~~~~~~~~~~~

# Bash-specific script check - does the first argument exist?
if [ -z "$1" ]; then
    echo Directory not provided! Please provide a directory to process.
    exit
fi

# Bash-specific script check - is the first argument we got passed a directory?
if [ -d $1 ]; then
    echo Valid directory identified!
else
    exit
fi

# Change directory to the working directory - that's the only place we'll be
# working!
cd $1

# Bash-specific script check - does the second argument exist?
if [ -z "$2" ]; then
    echo Wildcard not provided! Please provide a wildcard to process.
    exit
fi

# Bash-specific script check - does the second argument, when we're in the first
# argument directory, actually give us anything?
if compgen -G "$2" > /dev/null; then
    echo Valid files identified!
else
    echo Nothing found for "$1/$2"!
    exit
fi

# File (PR)e(F)ix - we create and destroy files as part of this script. To avoid
# collisions with user files, we'll use this elongated prefix for files we make
# and delete (except for the output!)
prf=sprite_processing_staged_image

# ~~~~~~~~~~~~~~~~~
# Step 1: "Stage A"
# ~~~~~~~~~~~~~~~~~

# This command takes all the png images in a folder and does a "threshold" (of
# 0) on the alpha channel. Since the threshold is 0, any value above is pushed
# to 255/256, and any value at 0 stays at 0. This ensures we have no
# partial-transperancy pixels.
magick convert $2 -channel a -threshold 0 +channel $prf%04d_a.png

# ~~~~~~~~~~~~~~~~~
# Step 2: "Stage B"
# ~~~~~~~~~~~~~~~~~
# This command takes the output from above and runs it through an edge detection
# algorithm. It then pushes the edge through a threshold to ensure the edge is
# purely black. Output is just the edge pixels from the Stage A images.
magick convert $prf*_a.png -edge 1 -channel RGB -threshold 100% $prf%04d_b.png

# ~~~~~~~~~~~~~~
# Step 3: Output
# ~~~~~~~~~~~~~~
# Now we have some simplified sprites and some sprite outlines, we need to
# overlay those outlines on top of the sprites.
# Get a list of all the files we made. Since they were organized in a very
# particular way, this we'll get a list that alternates "a" file then "b" file.
arr=(`ls $prf*.png`)
# Count the number of entries in the in the array.
img_count=${#arr[*]}
# For every OTHER entry in the array...
for ((i=0; i<img_count; i=i+2)); do
    # The "a" entry is the current entry
    j=$((i))
    # The "b" entry is the next entry
    k=$((i+1))
    # File output count is i / 2
    l=$((i/2))
    # Pre-format the output file name (so we don't have to later)
    out_file=`printf "edge_add_%04d.png" ${l}`
    # This command places the first file on top of the second file - in this
    # case, that means placing the edge-only image on top of the
    # anti-transperancy sprite. This gives us a new sprite with more clear
    # edges.
    magick composite -gravity center ${arr[$k]} ${arr[$j]} $out_file
done

# ~~~~~~~~~~~~~~~~
# Step 4: Clean-up
# ~~~~~~~~~~~~~~~~
# Remove our WIP images
rm $prf*_a.png
rm $prf*_b.png
