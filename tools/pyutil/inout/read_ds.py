#!/usr/bin/env python

"""TODO only supports volume files
"""

import os
import sys

def read_ds(ds_file):
    ds = {}
    with open(ds_file) as f:
        ds['filename'] = ds_file
        ds['slices'] = []
        ds['adjacency'] = []
        ds['markers'] = []

        cur_contour = None
        for line in f:
            line = line[:-1]

            if len(line) == 0 or line[0] == '#':
                continue

            if ':' in line:
                if line.startswith('tack:'):
                    x, y = map(float, line.split()[-1][1:-1].split(','))
                    cur_contour[1].append((x, y))
                else:
                    key_val = line.split(':')
                    ds[key_val[0]] = key_val[-1][1:]
            elif line.startswith('begin'):
                if line == "begin slice tacks":
                    ds['slices'].append([])
                elif line == "begin slice markers":
                    ds['markers'].append([])
                elif line.endswith('contour'):
                    if cur_contour is not None:
                        ds['slices'][-1].append(cur_contour)
                    cur_contour = (line.split()[1], [])
            elif line == 'end':
                if cur_contour is not None:
                    ds['slices'][-1].append(cur_contour)
                cur_contour = None
            elif line == 'slice':
                ds['adjacency'].append([])
            elif line.startswith('contour') and line.endswith('-1'):
                ds['adjacency'][-1].append(map(int, line.split()[1:-1]))
            elif line == "contour adjacency":
                pass
            else:
                print "WARNING: parse error, failed on line %s" % line

    return ds

if __name__ == "__main__":
    print read_ds(sys.argv[1])
