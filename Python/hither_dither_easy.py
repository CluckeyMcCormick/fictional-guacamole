#!/usr/bin/python3

# Python stuff we need
import argparse
import sys

# External libraries that we need
from PIL import Image
import hitherdither

parser = argparse.ArgumentParser(
	description='Process an image into a dithered version of itself.'
)
parser.add_argument(
	'palette', help='The index of the pallete you wish to use. [1-3]',
	type=int
)
parser.add_argument(
	'algorithm', help='The index of the algorithm you wish to use. [1-12]',
	type=int
)
parser.add_argument(
	'input', help='The path to the image you wish to modify.', type=str
)

args = parser.parse_args()

# Create the palette variable so it's set after our if statements
palette = None

# Black-And-White
if args.palette == 1:
	print("Black & White!")
	# Create our palettes 
	palette = hitherdither.palette.Palette([0x000000, 0xFFFFFF])
# Links Awakening (SGB) Palette (Anonymous?)
elif args.palette == 2:
	print("Links Awakening!")
	# Create our palettes 
	palette = hitherdither.palette.Palette([
		0x5a3921, 0x6b8c42, 0x7bc67b, 0xffffb5
	])
# Funky Future 8 by Shamaboy
elif args.palette == 3:
	print("Funky Future 8!")
	# Create our palettes 
	palette = hitherdither.palette.Palette([
		0x2b0f54, 0xab1f65, 0xff4f69, 0xfff7f8, 0xff8142, 0xffda45,
		0x3368dc, 0x49e7ec
	])

# Fantasy24 by Gabriel C
elif args.palette == 4:
	print("Fantasy24!")
	# Create our palettes 
	palette = hitherdither.palette.Palette([
		0x1f240a, 0x39571c, 0xa58c27, 0xefac28, 0xefd8a1, 0xab5c1c,
		0x183f39, 0xef692f, 0xefb775, 0xa56243, 0x773421, 0x724113,
		0x2a1d0d, 0x392a1c, 0x684c3c, 0x927e6a, 0x276468, 0xef3a0c,
		0x45230d, 0x3c9f9c, 0x9b1a0a, 0x36170c, 0x550f0a, 0x300f0a
	])
# Resurrect64 by Kerrie Lake
else:
	print("Resurrect64!")
	# Create our palettes 
	palette = hitherdither.palette.Palette([
		0x2e222f, 0x3e3546, 0x625565, 0x966c6c, 0xab947a, 0x694f62,
		0x7f708a, 0x9babb2, 0xc7dcd0, 0xffffff, 0x6e2727, 0xb33831,
		0xea4f36, 0xf57d4a, 0xae2334, 0xe83b3b, 0xfb6b1d, 0xf79617,
		0xf9c22b, 0x7a3045, 0x9e4539, 0xcd683d, 0xe6904e, 0xfbb954,
		0x4c3e24, 0x676633, 0xa2a947, 0xd5e04b, 0xfbff86, 0x165a4c,
		0x239063, 0x1ebc73, 0x91db69, 0xcddf6c, 0x313638, 0x374e4a,
		0x547e64, 0x92a984, 0xb2ba90, 0x0b5e65, 0x0b8a8f, 0x0eaf9b,
		0x30e1b9, 0x8ff8e2, 0x323353, 0x484a77, 0x4d65b4, 0x4d9be6,
		0x8fd3ff, 0x45293f, 0x6b3e75, 0x905ea9, 0xa884f3, 0xeaaded,
		0x753c54, 0xa24b6f, 0xcf657f, 0xed8099, 0x831c5d, 0xc32454,
		0xf04f78, 0xf68181, 0xfca790, 0xfdcbb0
	])


img = None
try:
	img = Image.open(args.input)
except Exception as e:
	print("Couldn't open provided image path: ")
	print("\t", parser.input)
	print("Does the path exist? Is it an image?")
	print("Stopping due to error...")
	sys.exit()
	
img_dithered = None

if args.algorithm == 1:
	print("Floyd Steinberg!")
	img_dithered = hitherdither.diffusion.error_diffusion_dithering(
		img, palette, method='floyd-steinberg', order=2
	)
elif args.algorithm == 2:
	print("Atkinson!")
	img_dithered = hitherdither.diffusion.error_diffusion_dithering(
		img, palette, method='atkinson', order=2
	)
elif args.algorithm == 3:
	print("Jarvis-Judice-Ninke!")
	img_dithered = hitherdither.diffusion.error_diffusion_dithering(
		img, palette, method='jarvis-judice-ninke', order=2
	)
elif args.algorithm == 4:
	print("Stucki!")
	img_dithered = hitherdither.diffusion.error_diffusion_dithering(
		img, palette, method='stucki', order=2
	)
elif args.algorithm == 5:
	print("Burkes!")
	img_dithered = hitherdither.diffusion.error_diffusion_dithering(
		img, palette, method='burkes', order=2
	)
elif args.algorithm == 6:
	print("Sierra3!")
	img_dithered = hitherdither.diffusion.error_diffusion_dithering(
		img, palette, method='sierra3', order=2
	)
elif args.algorithm == 7:
	print("Sierra2!")
	img_dithered = hitherdither.diffusion.error_diffusion_dithering(
		img, palette, method='sierra2', order=2
	)
elif args.algorithm == 8:
	print("Sierra-2-4A!")
	img_dithered = hitherdither.diffusion.error_diffusion_dithering(
		img, palette, method='sierra-2-4a', order=2
	)
elif args.algorithm == 9:
	print("Stevenson-Acre!")
	img_dithered = hitherdither.diffusion.error_diffusion_dithering(
		img, palette, method='stevenson-arce', order=2
	)
elif args.algorithm == 10:
	print("Bayer!")
	img_dithered = hitherdither.ordered.bayer.bayer_dithering(
		img, palette, [256/4, 256/4, 256/4], order=8
	)
elif args.algorithm == 11:
	print("Cluster!")
	img_dithered = hitherdither.ordered.cluster.cluster_dot_dithering(
		img, palette, [256/4, 256/4, 256/4], order=4
	)
else:
	print("Yliluomas!")
	img_dithered = hitherdither.ordered.yliluoma.yliluomas_1_ordered_dithering(
		img, palette, order=8
	)

# Save the image
img_dithered.save(args.input + ".dithered", "PNG")





