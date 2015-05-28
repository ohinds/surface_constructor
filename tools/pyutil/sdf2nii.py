#!/usr/bin/env python

import nibabel as nb
import numpy as np
import sys

def main(argv):
    if len(argv) < 3:
        print "usage: %s in_sdf out_nii"
        return 0

    in_sdf = argv[1]
    out_nii = argv[2]

    with open(in_sdf) as sdf:
        ni, nj, nk = map(int, sdf.readline().split())
        oi, oj, ok = map(float, sdf.readline().split())
        dx = float(sdf.readline())

        data = np.zeros((ni, nj, nk))
        for k in xrange(nk):
            for j in xrange(nj):
                for i in xrange(ni):
                    data[i, j, k] = float(sdf.readline())

    affine = np.eye(4)
    affine[0, 3] = oi
    affine[1, 3] = oj
    affine[2, 3] = ok

    nb.save(nb.nifti1.Nifti1Image(data, affine), out_nii)

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
