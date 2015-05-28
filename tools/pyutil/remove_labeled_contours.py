#!/usr/bin/env python

import re
import os
import sys


def main(argv):
    in_file = argv[1]
    out_file = argv[2]

    labeled = {}
    # build index of labeled contours
    with open(in_file) as f:
        reading = False
        for line in f:
            if line.startswith('slices labels'):
                reading = True
                continue

            if not reading:
                continue

            line_split = line.split()

            if len(line_split) < 4:
                break

            sli = int(line_split[0])
            cont = int(line_split[1])

            if sli not in labeled:
                labeled[sli] = set()

            labeled[sli].add(cont)

    contour_type = re.compile('begin ([a-z]*) contour')
    with open(out_file, 'w') as o:
        with open(in_file) as f:
            before_tacks = True
            after_tacks = False
            cur_slice = -1
            cur_cont = -1
            in_discard = False
            in_prefs = False
            for line in f:
                if line.startswith('slices tacked:'):
                    before_tacks = False
                    o.write(line)
                    continue

                if in_prefs or before_tacks:
                    o.write(line)
                    continue

                if line == 'contour adjacency\n':
                    o.write('slices marked: 0\n\n')
                    o.write('num vertices: 0\n\n')
                    o.write('num faces: 0\n\n')
                    after_tacks = True
                elif line == 'preferences:\n':
                    in_prefs = True
                    o.write(line)
                elif line == 'begin slice tacks\n':
                    cur_slice += 1
                    cur_cont = -1
                    o.write(line)
                elif contour_type.search(line) is not None:
                    cur_cont += 1

                    if cur_slice in labeled and cur_cont in labeled[cur_slice]:
                        in_discard = True
                    else:
                        in_discard = False
                        o.write(line)
                elif line.startswith('tack:'):
                    if not in_discard:
                        o.write(line)
                elif not after_tacks:
                    o.write(line)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
