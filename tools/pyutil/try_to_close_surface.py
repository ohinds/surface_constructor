#!/usr/bin/env python

import sys

from inout import read_ds
from inout import write_ds

def main(argv):
    if len(argv) != 3:
        print "usage: %s in_ds out_ds" % argv[0]
        return 0

    in_ds = argv[1]
    out_ds = argv[2]

    ds = read_ds.read_ds(in_ds)

    for slc in ds['slices']:
        if len(slc) == 1 and slc[0][0] == 'open':

            slc[0] = ("closed",
                      slc[0][1] + [(400, 280),
                                   (400, 140),
                                   (140, 140),
                                   (140, 280)])

    write_ds.write_ds(ds, out_ds)

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
