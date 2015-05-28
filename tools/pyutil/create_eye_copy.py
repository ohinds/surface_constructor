#!/usr/bin/env python

import nibabel
import numpy
import os
import sys


def main(argv):
    if len(argv) != 3:
        print "usage: %s src dst" % argv[0]
        exit

    src = argv[1]
    dst = argv[2]

    vol = nibabel.load(src)
    vol.set_sform(numpy.eye(4))
    vol.set_qform(numpy.eye(4))
    nibabel.save(vol, dst)

if __name__ == "__main__":
    sys.exit(main(sys.argv))
