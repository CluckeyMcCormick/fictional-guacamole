import argparse

import tests

# First, compose the help string for our command.

d = "Given an index, runs the corresponding test. Available tests are:\n\n"

for i in range( len(tests.test_listing) ):
	avail_test = tests.test_listing[i]
	d = d + "{0} - {1}\n".format(i, avail_test.__name__)

parser = argparse.ArgumentParser(description=d, formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument("test_num", help="The test index you wish to run.", type=int)
args = parser.parse_args()

tests.test_listing[args.test_num].run()