#!/usr/bin/env python

import nibabel as nb
import numpy as np
import os
import sys

# TODO figure out how to use the version in ../io
def read_off(filename):
    vertices = []
    faces = []

    with open(filename) as f:
        f.readline() # OFF
        num_verts, num_faces, _ = map(int, f.readline().split())

        for vert in xrange(num_verts):
            vertices.append(map(float, f.readline().split()))

        for face in xrange(num_faces):
            faces.append(map(int, f.readline().split()[1:]))

    return (vertices, faces)


def main(argv):
    if len(argv) != 4:
        raise ValueError('too few arguments\n'
            'usage: %s in_vol in_surf out_mask_vol', argv[0])

    try:
        in_vol = nb.load(argv[1])

        if argv[2].endswith(".off"):
            verts, faces = read_off(argv[2])
        else:
            verts, faces = nb.freesurfer.read_geometry(argv[2])

    except:
        raise ValueError('at least one input file not found\n'
                         'usage: %s in_vol in_surf out_mask_vol', argv[0])

    out_mask_vol = in_vol

    mask = out_mask_vol.get_data()

    # Hack to zero out all data. (nibabel docs suck and I don't feel
    # like figuring it out.)
    for x in xrange(mask.shape[0]):
        for y in xrange(mask.shape[1]):
            for z in xrange(mask.shape[2]):
                mask[x, y, z] = 0

    ras2vox = np.matrix(in_vol.get_affine()).I

    def map_ras_to_vox(ras):
        ras4d = list(ras)
        ras4d.append(1)
        vox = map(int, np.round(ras2vox * np.array([ras4d]).T));
        return np.array(vox[:3])

    edges = [[0, 1], [0, 2], [1, 2]]
    for face in faces:
        for edge in edges:
            beg = map_ras_to_vox(verts[face[edge[0]]])
            end = map_ras_to_vox(verts[face[edge[1]]])

            mask[beg[0], beg[1], beg[2]] = 1
            mask[end[0], end[1], end[2]] = 1

            for pos in xrange(1, int(np.round(np.linalg.norm(end - beg))) - 1):
                cur = map(
                    int, np.round(
                        beg + pos / np.linalg.norm(end - beg) * (end - beg)))
                mask[cur[0], cur[1], cur[2]] = 1

    out_mask_vol.to_filename(argv[3])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
