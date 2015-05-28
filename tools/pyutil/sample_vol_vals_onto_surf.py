#!/usr/bin/env python

"""Output a cdata file representing voxel values at the location of a
surface's vertices.
"""

import nibabel as nb
import numpy as np
import sys

from sv_io import read_surf
from sv_io import write_surf_cdata


def main(argv):
    if len(argv) < 4:
        print "usage: %s surf vol out_cdata" % argv[0]
        return 0

    surf_file = argv[1]
    vol_file = argv[2]
    cdata_file = argv[3]


    vertices, _ = read_surf(surf_file)
    vol = nb.load(vol_file)
    trans = np.matrix(vol.get_affine()).I

    cdata = []
    for vert in vertices:
        vert_one = list(vert)
        vert_one.append(1)

        vox = map(int, trans * np.array([vert_one]).T)

        # special case when slices needed wrapping
        if vox[2] < 0:
            vox[2] += vol.get_shape()[2]

        cdata.append(vol.get_data()[vox[0], vox[1], vox[2]])

    write_surf_cdata(cdata_file, cdata)

if __name__ == "__main__":
    sys.exit(main(sys.argv))
