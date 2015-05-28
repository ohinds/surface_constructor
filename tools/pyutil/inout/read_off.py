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
