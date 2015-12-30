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
    hdr = vol.get_header()

    R = numpy.eye(4)
    for r in xrange(3):
        R[r, r] = hdr['pixdim'][r + 1]
        R[r, 3] = - hdr['pixdim'][r + 1] * hdr['dim'][r + 1] / 2.

    R[2, 3] += hdr['pixdim'][3] / 2.

    vol.set_sform(R)
    vol.set_qform(R)
    nibabel.save(vol, dst)

if __name__ == "__main__":
    sys.exit(main(sys.argv))
