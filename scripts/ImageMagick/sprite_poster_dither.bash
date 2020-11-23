
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

# Bash-specific script check - does the second argument exist?
if [ -z "$2" ]; then
    echo Wildcard not provided! Please provide a wildcard to process.
    exit
fi

# Bash-specific script check - does the second argument, when we're in the first
# argument directory, actually give us anything?
if compgen -G "$1/$2" > /dev/null; then
    echo Valid files identified!
else
    echo Nothing found for "$1/$2"!
    exit
fi

# Bash-specific script check - does the third argument exist?
if [ -z "$3" ]; then
    echo Color pallete not provided! Please provide a color pallette image.
    exit
fi

# Bash-specific script check - is the first argument we got passed a directory?
if [ -f $3 ]; then
    echo Valid color pallette image identified!
else
    echo Provided color pallette image \"$3\" does not exist!
    exit
fi

# File (PR)e(F)ix - we create and destroy files as part of this script. To avoid
# collisions with user files, we'll use this elongated prefix for files we make
# and delete (except for the output!)
prf=sprite_poster_dither_staged_image


# ~~~~~~~~~~~~~~~~~~~~~~~
# Step 1: Dither Strategy
# ~~~~~~~~~~~~~~~~~~~~~~~
# We have a lot of potential ways to dither an image - let's prompt the user for
# what THEY think we should use.
dither_choice=$(\
    whiptail \
        --title "Choose a Dither!" \
        --menu "Choose a dithering strategy." 15 35 8 \
            "1"  "None" \
            "2"  "Riemersma" \
	    "3"  "Floyd-Steinberg" \
	    "4"  "Checkerboard 2x1" \
	    "5"  "Ordered 2x2" \
            "6"  "Ordered 3x3" \
            "7"  "Ordered 4x4" \
            "8"  "Ordered 8x8" \
            "9"  "Halftone 4x4 (Angled)" \
            "10" "Halftone 6x6 (Angled)" \
	    "11" "Halftone 8x8 (Angled)" \
            "12" "Halftone 4x4 (Orthogonal)" \
            "13" "Halftone 6x6 (Orthogonal)" \
            "14" "Halftone 8x8 (Orthogonal)" \
            "15" "Halftone 16x16 (Orthogonal)" \
    3>&1 1>&2 2>&3 # This line allows us to get output. Somehow.
)

# Use this "case" statement (basically a switch statement) to resolve the above
# user's choice
case $dither_choice in

  # None
  1)
    dither_choice="-dither None"
    ;;
  # Riemersma
  2)
    dither_choice="-dither Riemersma"
    ;;
  # Floyd-Steinberg
  3)
    dither_choice="-dither FloydSteinberg"
    ;;
  # Checkerboard 2x1
  4)
    dither_choice="-ordered-dither checks"
    ;;
  # Ordered 2x2
  5)
    dither_choice="-ordered-dither o2x2"
    ;;
  # Ordered 3x3
  6)
    dither_choice="-ordered-dither o3x3"
    ;;
  # Ordered 4x4
  7)
    dither_choice="-ordered-dither o4x4"
    ;;
  # Ordered 8x8
  8)
    dither_choice="-ordered-dither o8x8"
    ;;
  # Halftone 4x4 (Angled)
  9)
    dither_choice="-ordered-dither h3x4a"
    ;;
  # Halftone 6x6 (Angled)
  10)
    dither_choice="-ordered-dither h6x6a"
    ;;
  # Halftone 8x8 (Angled)
  11)
    dither_choice="-ordered-dither h8x8a"
    ;;
  # Halftone 4x4 (Orthogonal)
  12)
    dither_choice="-ordered-dither h3x4o"
    ;;
  # Halftone 6x6 (Orthogonal)
  13)
    dither_choice="-ordered-dither h6x6o"
    ;;
  # Halftone 8x8 (Orthogonal)
  14)
    dither_choice="-ordered-dither h8x8o"
    ;;
  # Halftone 16x16 (Orthogonal)
  15)
    dither_choice="-ordered-dither h16x16o"
    ;;
esac

# ~~~~~~~~~~~~~~~~~
# Step 2: "Stage A"
# ~~~~~~~~~~~~~~~~~
# This command takes all the wildcard images in the provided folder and outputs
# an "extract" of the alpha channel. We'll need this later.
magick convert $1/$2 -alpha extract $1/$prf%04d_a.png

# ~~~~~~~~~~~~~~~~~
# Step 2: "Stage B"
# ~~~~~~~~~~~~~~~~~
# This command takes in all the wildcard images and dither-posterizes them, as
# specified by the user
magick convert $1/$2 -alpha off $dither_choice -remap $3 $1/$prf%04d_b.png

# ~~~~~~~~~~~~~~
# Step 3: Output
# ~~~~~~~~~~~~~~
# Now we have some simplified sprites and some sprite outlines, we need to
# overlay those outlines on top of the sprites.
# Get a list of all the files we made. Since they were organized in a very
# particular way, this we'll get a list that alternates "a" file then "b" file.
arr=(`ls $1/$prf*.png`)
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
    out_file=`printf "postdith_%04d.png" ${l}`
    # This command places the first file on top of the second file - in this
    # case, that means placing the edge-only image on top of the
    # anti-transperancy sprite. This gives us a new sprite with more clear
    # edges.
    # magick composite -gravity center ${arr[$k]} ${arr[$j]} $out_file
    magick convert ${arr[$k]} ${arr[$j]} -alpha Off -compose CopyOpacity \
        -composite $1/$out_file
done

# ~~~~~~~~~~~~~~~~~
# Step 4: Clean-up
# ~~~~~~~~~~~~~~~~~
# Remove our WIP images
rm $1/$prf*_a.png
rm $1/$prf*_b.png
