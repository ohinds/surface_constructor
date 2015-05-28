#!/usr/bin/env python

"""Copy a vox2ras from one volume to another
"""

import nibabel as nb
import sys

def main(argv):
    if len(argv) < 4:
        print "usage: %s src_vol src_vol_for_vox2ras dst_vol" % argv[0]
        return 0

    src = nb.load(argv[1])
    src_vox2ras = nb.load(argv[2])

    src.set_qform(src_vox2ras.get_qform())
    src.set_sform(src_vox2ras.get_sform())

    nb.save(src, argv[3])

if __name__ == "__main__":
    sys.exit(main(sys.argv))
