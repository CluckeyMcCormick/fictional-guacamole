
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
    echo "$1" is not a directory!
    exit
fi

# Bash-specific script check - does the second argument exist?
if [ -z "$2" ]; then
    echo Wildcard not provided! Please provide a wildcard to process.
    exit
fi

# Bash-specific script check - does the second argument, combined with the
# first, actually give us anything?
if compgen -G "$1/$2" > /dev/null; then
    echo Valid files identified!
else
    echo Nothing found for "$1/$2"!
    exit
fi

# Bash-specific script check - does the third argument actually match a
# specification for a spritesheet matrix?
if [[ $3 =~ [0-9]+x[0-9]+ ]]; then
    echo Valid files size matrix identified!
else
    echo Image matrix \"$3\" has an invalid form!
    echo Must match form CxR...
    echo ----\> Where C is the number of columns \(i.e. frames per animation\)
    echo ----\> and R is the number of rows \(i.e. different angles\)
    exit
fi

# Composite together all of the images the user gave us into a singular
# spritesheet. Neat!
magick montage $1/$2 -tile $3 -geometry +0+0 -background none $1/spritesheet.png
