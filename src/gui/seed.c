/*****************************************************************************
 * contour.c is the source file for the contour tracing portion of an
 * application to construct surfaces from serial secions
 * Oliver Hinds <oph@cns.bu.edu> 2004-03-16
 *
 *
 *
 *****************************************************************************/

#include"contour.h"
#include"colors.extern"

/******************************************************
 * globals
 ******************************************************/

/* the image */
static image *imgBuf;
static quadri imgBounds;
static GLuint tex;
static image *segImg;
static GLuint segTex;

/* the seeds */
static sliceSeeds *seeds = NULL;
static image *fgSeeds = NULL;
static image *bgSeeds = NULL;
static image *overlapSeeds = NULL;
static int showSeeds = TRUE;
static int showSeg = TRUE;
static int showTacks = TRUE;

/* mouse modifier state */
#define GLUT_NO_BUTTON (GLUT_MIDDLE_BUTTON + 3)
static int buttonDown = GLUT_NO_BUTTON;
static int controlDown = FALSE;
static int shiftDown = FALSE;
static int altDown = FALSE;

/* draw sizes for paintbrush in pixels */
static float brushRadius = 4;

/* start location of clear path */
static pixelLocation *clearPathStart = NULL;

/******************************************************
 * functions
 ******************************************************/

/****** LOCALLY USED FUNCTIONS ********/
int subToInd2D(int row, int col, image *img) {
  return row + col * img->width;
}

int subToInd3D(int row, int col, int chan, image *img) {
  return chan + row * 4 + col * (img->width * 4);
}

void clearSeedPixels(image *seedImg) {
  int row, col, chan;
  for (row = 0; row < seedImg->width; row++) {
    for (col = 0; col < seedImg->height; col++) {
      for (chan = 0; chan < 4; chan++) {
        seedImg->pixels[subToInd3D(row, col, chan, seedImg)] = 0;
      }
    }
  }
}

void assignSeedPixels(list *seedList, int colorDim, image *seedImg) {
  int chan;
  pixelLocation *location;
  listNode *i;

  for (i = getListNode(seedList, 0); i; i = (listNode*) i->next) {
    location = (pixelLocation*) i->data;
    for (chan = 0; chan < 3; chan++) {
      seedImg->pixels[subToInd3D(location->row,
                               location->col, chan, seedImg)] = 0;
    }
    seedImg->pixels[subToInd3D(location->row,
                               location->col, colorDim, seedImg)] = USHRT_MAX;
    seedImg->pixels[subToInd3D(location->row,
                             location->col, 3, seedImg)] = USHRT_MAX;
  }
}

void assignOverlapPixels(image *img1, image *img2, int colorDim,
                         image *overlap) {
  int row, col, chan;

  for (row = 0; row < overlap->width; row++) {
    for (col = 0; col < overlap->height; col++) {
      for (chan = 0; chan < 4; chan++) {
        overlap->pixels[subToInd3D(row, col, chan, overlap)] = 0;
      }

      if (img1->pixels[subToInd3D(row, col, 3, overlap)] > 0 &&
          img2->pixels[subToInd3D(row, col, 3, overlap)] > 0) {
        overlap->pixels[subToInd3D(row, col, colorDim, overlap)] = USHRT_MAX;
        overlap->pixels[subToInd3D(row, col, 3, overlap)] = USHRT_MAX;
      }
    }
  }
}

void assignSeedLists(image *seedImg, int chan, list *seedList) {
  int row;
  int col;
  pixelLocation *loc;

  for (row = 0; row < seedImg->width; row++) {
    for (col = 0; col < seedImg->height; col++) {
      if (seedImg->pixels[subToInd3D(row, col, chan, seedImg)] > 0) {
        loc = (pixelLocation*) malloc(sizeof(pixelLocation));
        loc->row = row;
        loc->col = col;

        enqueue(seedList, loc);
      }
    }
  }
}

void copySeeds(int slice) {
  fprintf(stdout, "copying seeds from slice %d\n", slice);

  sliceSeeds *seeds = (sliceSeeds*) getListNode(curDataset->sliceSeedLists,
                                                slice)->data;

  if (seeds == NULL) {
    printf("NULL\n");
    return;
  }

  printf("num fg: %d\nnum bg: %d\n", listSize(seeds->fgSeeds), listSize(seeds->bgSeeds));

  assignSeedPixels(seeds->fgSeeds, 0, fgSeeds);
  assignSeedPixels(seeds->bgSeeds, 2, bgSeeds);
}

void buildSegTex(image *segImage) {
  image *segTexImage = createImage(segImage->width, segImage->height, 4);
  int row, col, chan;

  for (row = 0; row < segImage->width; row++) {
    for (col = 0; col < segImage->height; col++) {
      if (segImage->pixels[subToInd2D(row, col, segImage)] == 1) {
        segTexImage->pixels[subToInd3D(row, col, 0, segTexImage)] = USHRT_MAX;
        segTexImage->pixels[subToInd3D(row, col, 1, segTexImage)] = USHRT_MAX;
        segTexImage->pixels[subToInd3D(row, col, 2, segTexImage)] = 0;
        segTexImage->pixels[subToInd3D(row, col, 3, segTexImage)] =
          0.1 * USHRT_MAX;
      }
      else {
        for (chan = 0; chan < 4; chan++) {
          segTexImage->pixels[subToInd3D(row, col, chan, segTexImage)] = 0;
        }
      }
    }
  }

  segTex = imageTexture(curDataset, segTexImage);
  freeImage(segTexImage);
}

int outOfRange(pixelLocation *v, image *img) {
  return v->col < 0 || v->col >= img->width || v->row < 0 || v->row >= img->height;
}

void clearPathInSegImage(image *segImage,
                         pixelLocation *start, pixelLocation *end) {
  list *vertexHeap = newList(MINHEAP);
  image *closed = createImage(segImage->width, segImage->height, 1);
  image *predecessor_row = createImage(segImage->width, segImage->height, 1);
  image *predecessor_col = createImage(segImage->width, segImage->height, 1);
  double *distance = (double*) calloc(segImage->width * segImage->height,
                                      sizeof(double));

  const int NUM_NEIGHBORS = 8;
  const int NEIGHBOR_MAP [8][2] = {
    { -1,  0 },
    { -1, -1 },
    {  0, -1 },
    {  1, -1 },
    {  1,  0 },
    {  1,  1 },
    {  0,  1 },
    { -1,  1 }
  };

  int i, curDist, neighborDist, thisDist;
  pixelLocation *neighbor;
  listNode *curNode = NULL;
  pixelLocation *cur = (pixelLocation*) malloc(sizeof(pixelLocation));

  image* sliceImg = NULL;
  if(curDataset->imageSource == VP_VOLUME) {
    curDataset->vol->selectedVoxel[curDataset->vol->sliceDir] = curSlice;
    sliceImg = sliceVolume(curDataset->vol,0,curDataset->vol->sliceDir,0);
  }
  else {
    sliceImg = imgBuf;
  }

  *cur = *start;
  insertHeapNode(vertexHeap, 0, cur);

  while (listSize(vertexHeap) > 0) {
    curNode = getHeapTop(vertexHeap);
    cur = (pixelLocation*) curNode->data;
    curDist = distance[subToInd2D(cur->row, cur->col, segImage)];

    // check if we are done
    if (cur->row == end->row && cur->col == end->col) {
      break;
    }

    // expand neighbors
    for (i = 0; i < NUM_NEIGHBORS; i++) {
      neighbor = (pixelLocation*) malloc(sizeof(pixelLocation));
      neighbor->row = cur->row + NEIGHBOR_MAP[i][0];
      neighbor->col = cur->col + NEIGHBOR_MAP[i][1];

      neighborDist =
        distance[subToInd2D(neighbor->row, neighbor->col, segImage)];

      if (outOfRange(neighbor, segImage) ||
          getPixelValue(closed, neighbor->row, neighbor->col)) {
        continue;
      }

      thisDist = getPixelValue(sliceImg, neighbor->row, neighbor->col);

      if (neighborDist == 0 || thisDist + curDist < neighborDist) {
        setPixelValue(predecessor_row, neighbor->row, neighbor->col, cur->row);
        setPixelValue(predecessor_col, neighbor->row, neighbor->col, cur->col);

        distance[subToInd2D(neighbor->row, neighbor->col, segImage)] =
          thisDist + curDist;

        insertHeapNode(vertexHeap, thisDist + curDist,
                       neighbor);
      }
    }

    setPixelValue(closed, cur->row, cur->col, 1);
  }

  if (cur->row != end->row || cur->col != end->col) {
    fprintf(stderr, "ERROR: no path from start to end found\n");
    return;
  }

  // follow path, clearing seg image along it
  while (cur->row != start->row || cur->col != start->col) {
    if (cur->row == 0 && cur->col == 0) {
      return;
    }

    bgSeeds->pixels[subToInd3D(cur->col,
                               cur->row, 2, bgSeeds)] = USHRT_MAX;
    bgSeeds->pixels[subToInd3D(cur->col,
                               cur->row, 3, bgSeeds)] = USHRT_MAX;

    pixelLocation next;
    next.row = getPixelValue(predecessor_row, cur->row, cur->col);
    next.col = getPixelValue(predecessor_col, cur->row, cur->col);
    *cur = next;
  }

  freeList(vertexHeap);
  freeImage(closed);
  freeImage(predecessor_row);
  freeImage(predecessor_col);
  free(distance);
}

/****** END LOCALLY USED FUNCTIONS ********/

/**
 * load the images and perform init on them
 */
void seedImgInit() {
  image *img;

  /* validate the curSlice */
  curSlice %= curDataset->numSlices;
  if(curSlice < 0) curSlice += curDataset->numSlices;

  /* load the texture if dynamic textures is on */
  if(dynamicTextures) {
    img = loadImage(curDataset, curSlice);
    curDataset->slices[curSlice] = *img;
    freeImage(img);
  }

  /* get image */
  imgBuf = &curDataset->slices[curSlice];

  tex = curDataset->sliceTextures[curSlice];

  if (curDataset->seg != NULL) {
    curDataset->seg->selectedVoxel[curDataset->vol->sliceDir] = curSlice;
    segImg = sliceVolume(curDataset->seg,0,curDataset->vol->sliceDir,0);
    buildSegTex(segImg);
    freeImage(segImg);
  }
}

/**
 * initialize general properties
 */
void seedInit() {
  listNode *ln;

  /* find the placement of the image (square and centered) */
  imgBounds.v1.x = 0;
  imgBounds.v1.y = 0;
  imgBounds.v2.x = imgBuf->width;
  imgBounds.v2.y = 0;
  imgBounds.v3.x = imgBuf->width;
  imgBounds.v3.y = imgBuf->height;
  imgBounds.v4.x = 0;
  imgBounds.v4.y = imgBuf->height;

  curDataset->width = imgBuf->width;
  curDataset->height = imgBuf->height;

  /* get the current seed to modify, create if it doesn't exist */
  while(NULL == (ln = getListNode(curDataset->sliceSeedLists,curSlice))) {
    seeds = (sliceSeeds*) malloc(sizeof(sliceSeeds));
    seeds->fgSeeds = newList(LIST);
    seeds->bgSeeds = newList(LIST);

    enqueue(curDataset->sliceSeedLists, seeds);
  }
  seeds = (sliceSeeds*) ln->data;

  /* transfer to image for interaction */
  /* build seed textures */
  fgSeeds = createImage(imgBuf->width, imgBuf->height, 4);
  bgSeeds = createImage(imgBuf->width, imgBuf->height, 4);
  overlapSeeds = createImage(imgBuf->width, imgBuf->height, 4);

  clearSeedPixels(fgSeeds);
  assignSeedPixels(seeds->fgSeeds, 0, fgSeeds);
  clearSeedPixels(bgSeeds);
  assignSeedPixels(seeds->bgSeeds, 2, bgSeeds);
  assignOverlapPixels(fgSeeds, bgSeeds, 1, overlapSeeds);

  strcpy(alertString,"");
}

/**
 * uninitializes the seed drawing and imaging stuff
 */
void seedUninit() {
  freeListAndData(seeds->fgSeeds);
  seeds->fgSeeds = newList(LIST);
  assignSeedLists(fgSeeds, 0, seeds->fgSeeds);

  freeListAndData(seeds->bgSeeds);
  seeds->bgSeeds = newList(LIST);
  assignSeedLists(bgSeeds, 2, seeds->bgSeeds);

  freeImage(fgSeeds);
  freeImage(bgSeeds);
  freeImage(overlapSeeds);

  /* unload the texture if dynamic textures are on */
  if(dynamicTextures) {
    unloadTexture(curSlice);
  }
}

/**
 * cleans up
 */
void seedDestroy() {
  // nothing
}

/**
 * check to see if a repaint is needed
 */
int seedRepaintNeeded(long now) {
  return FALSE;
}

void drawTexture() {

  float maxTexX = (float) imgBuf->width, maxTexY = (float) imgBuf->height;
  GLenum textureMethod = getTextureMethod();
  quadri windowCoords = getWindowCoordsQ(imgBounds);

  /* if we have no extensions, calculate the extent of the texture in (0,1) */
  if(textureMethod == GL_TEXTURE_2D) {
    maxTexX = imgBuf->width/(float)(imgBuf->width+imgBuf->padX);
    maxTexY = imgBuf->height/(float)(imgBuf->height+imgBuf->padY);
  }

  /* make a quadrilateral and provide texture coords */
  glBegin(GL_QUADS); {
    glTexCoord2d(0.0,0.0);
    glVertex3d(windowCoords.v1.x, windowCoords.v1.y, 0.0);
    glTexCoord2d(maxTexX,0.0);
    glVertex3d(windowCoords.v2.x, windowCoords.v2.y, 0.0);
    glTexCoord2d(maxTexX,maxTexY);
    glVertex3d(windowCoords.v3.x, windowCoords.v3.y, 0.0);
    glTexCoord2d(0.0,maxTexY);
    glVertex3d(windowCoords.v4.x, windowCoords.v4.y, 0.0);
  } glEnd();
}

/**
 * do seed specific drawing
 */
void seedDraw() {
  listNode *i, *j;

  GLenum textureMethod = getTextureMethod();

  /* build seed textures */
  GLuint fgTex = imageTexture(curDataset, fgSeeds);
  GLuint bgTex = imageTexture(curDataset, bgSeeds);
  GLuint overlapTex = imageTexture(curDataset, overlapSeeds);

  if(curDataset->imageSource != VP_NOIMAGES) {
    /* turn on texture mapping */
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    glEnable(textureMethod);

    /* draw the textures */
    glBindTexture(textureMethod, tex);
    drawTexture();

    if (showSeg && curDataset->seg != NULL) {
      glBindTexture(textureMethod, segTex);
      drawTexture();
    }

    if (showSeeds) {
      glBindTexture(textureMethod, fgTex);
      drawTexture();

      glBindTexture(textureMethod, bgTex);
      drawTexture();

      glBindTexture(textureMethod, overlapTex);
      drawTexture();
    }

    glDisable(textureMethod);

    if (clearPathStart != NULL) {
      glColor3f(0, 1, 0);

      vertex start;
      start.x = clearPathStart->col;
      start.y = clearPathStart->row;

      GLUquadricObj *quad = gluNewQuadric();
      gluQuadricDrawStyle(quad, GLU_FILL);
      vertex v = getWindowCoordsVert(start);

      /* draw an annulus */
      glTranslated(v.x, v.y,0);
      gluDisk(quad,tackInnerRadius,tackWidth,20,1);
      glTranslated(-v.x, -v.y,0);

      /* make a tiny point */
      glPointSize(1);
      glBegin(GL_POINTS); {
        glVertex3d(v.x, v.y, 0);
      } glEnd();

      gluDeleteQuadric(quad);

    }

    /* draw tacks, if we should */
    if (showTacks) {
      glColor4f(0.5, 1, 0.5, 0.5);

      GLUquadricObj *quad = gluNewQuadric();
      gluQuadricDrawStyle(quad, GLU_FILL);

      list *l = (list*)getListNode(
        curDataset->sliceContourLists,curSlice)->data;
      for(i = getListNode(l,0); i; i = (listNode*) i->next) {
        list *cList = ((contour*)i->data)->vertices;
        for(j = getListNode(cList,0); j; j = (listNode*) j->next) {
          vertex *t = (vertex*) j->data;
          vertex v = getWindowCoordsVert(*t);
          glTranslated(v.x, v.y,0);
          gluDisk(quad,tackInnerRadius,tackWidth,20,1);
          glTranslated(-v.x, -v.y,0);
        }
      }

      gluDeleteQuadric(quad);
    }

  }

  /* build the mode string */
  sprintf(modeString,"slice %d ",curSlice);
  strcat(modeString,"seed");

  strcat(modeString,":");
}

void runSegmentation() {
  char command[MAX_STR_LEN * 2];
  char seg_filename[MAX_STR_LEN];

  strcpy(seg_filename, curDataset->vol->filename);
  // TODO: hack, fixme
  strcpy(&seg_filename[strlen(seg_filename) - 4], "_seg.mgh");

  if (getenv("SURFACE_CONSTRUCTOR_HOME") == NULL) {
    fprintf(stderr, "ERROR: the env var SURFACE_CONSTRUCTOR_HOME must "
            "be set to run segmentation!\n");
    return;
  }

  sprintf(command, "matlab -nosplash -nodisplay -r \"addpath(genpath('%s')); "
          "random_walker_mri('%s', '%s', '%s', %d:%d); exit\"",
          "$SURFACE_CONSTRUCTOR_HOME",
          curDataset->vol->filename, curDataset->filename, seg_filename,
          curSlice - 4, curSlice + 6);

  fprintf(stdout, "%s\n", command);

  fprintf(stdout, "running segmentation...\n");
  int ret = system(command);
  fprintf(stdout, "done with segmentation, returned %d\n", ret);

  if (curDataset->seg != NULL) {
    freeVolume(curDataset->seg);
  }

  curDataset->seg = loadMGHVolume(seg_filename);
  fprintf(stdout, "loaded: %s\n", curDataset->seg->filename);
  changeSlice(0);
}

/** event handlers **/

/**
 * keyboard handler
 */
void seedAction(int action) {
  switch(action) {
      case 'p': /* print the seed list */
        fprintf(stdout,"---------------------------------------\n");
        //dumpSeeds(); // TODO
        fprintf(stdout,"---------------------------------------\n");
        break;
      case 'w': /* toggle current slice seed display */
        showSeeds = !showSeeds;
        redisplay();
        break;
      case 't': /* toggle segmentation volume */
        showSeg = !showSeg;
        redisplay();
        break;
      case 'c':
        copySeeds(curSlice + 1);
        redisplay();
        break;
      case 'v':
        copySeeds(curSlice - 1);
        redisplay();
        break;
      case '-':
      case '_':
        brushRadius /= 2.f;
        break;
      case '=':
      case '+':
        brushRadius *= 2.f;
        break;
      case 'r':
        runSegmentation();
        break;
      default:
        break;
  }
}

void addSeed(int foreground, vector mousePos) {
  int row;
  int col;
  int chan;
  float sqBrushRadius = brushRadius * brushRadius;

  image *img = foreground ? fgSeeds : bgSeeds;

  for (row = mousePos.x - brushRadius; row <= mousePos.x + brushRadius; row++) {
    for (col = mousePos.y - brushRadius; col <= mousePos.y + brushRadius;
         col++) {
      if (pow(row - mousePos.x, 2) + pow(col - mousePos.y, 2) > sqBrushRadius) {
        continue;
      }

      if (img->pixels[subToInd3D(row, col, 3, img)] == 0) {
        for (chan = 0; chan < 4; chan++) {
          img->pixels[subToInd3D(row, col, chan, img)] = 0;
        }
        img->pixels[subToInd3D(row, col, foreground ? 0 : 2, img)] = USHRT_MAX;
        img->pixels[subToInd3D(row, col, 3, img)] = USHRT_MAX;
      }
    }
  }
}

void removeSeed(int foreground, vector mousePos) {
  int row;
  int col;
  int chan;
  float sqBrushRadius = brushRadius * brushRadius;

  image *img = foreground ? fgSeeds : bgSeeds;

  for (row = mousePos.x - brushRadius; row <= mousePos.x + brushRadius; row++) {
    for (col = mousePos.y - brushRadius; col <= mousePos.y + brushRadius;
         col++) {
      if (pow(row - mousePos.x, 2) + pow(col - mousePos.y, 2) > sqBrushRadius) {
        continue;
      }

      if (img->pixels[subToInd3D(row, col, 3, img)] > 0) {
        for (chan = 0; chan < 4; chan++) {
          img->pixels[subToInd3D(row, col, chan, img)] = 0;
        }
      }
    }
  }
}

/**
 * creates the menu for the seed
 */
void createSeedMenu() {
  glutAddMenuEntry("-- Seed Specific Actions --",0);
  glutAddMenuEntry("'w' toggle seed visibility",'w');
  glutAddMenuEntry("'t' toggle segmentation visibility",'t');
  glutAddMenuEntry("'c' copy next slice's seeds to this slice",'c');
  glutAddMenuEntry("'v' copy previous slice's seeds to this slice",'v');
  glutAddMenuEntry("'=' increase brush size",'=');
  glutAddMenuEntry("'-' reduce brush size",'-');
  glutAddMenuEntry("'r' run segmentation",'r');
}

/**
 * keyboard handler
 */
void seedKeyboard(unsigned char key, int x, int y) {
  seedAction(key);
}

/**
 * mouse handler determines what kind of actions are being performed
 */
void mouseHandler(vector mousePos) {
  // middle button defines path clearing points
  if (buttonDown == GLUT_MIDDLE_BUTTON) {
    if (clearPathStart == NULL) {
      clearPathStart = (pixelLocation*) malloc(sizeof(vector));
      clearPathStart->col = rint(mousePos.x);
      clearPathStart->row = rint(mousePos.y);
    }
    else {
      pixelLocation end;
      end.col = rint(mousePos.x);
      end.row = rint(mousePos.y);

      clearPathInSegImage(segImg, clearPathStart, &end);
      free(clearPathStart);
      clearPathStart = NULL;
    }

    redisplay();

    return;
  }

  // left button defines seed drawing
  int fg = !controlDown;

  if(!shiftDown)  { /* add a new seed */
    addSeed(fg, mousePos);
  }
  else { /* remove a seed */
    removeSeed(fg, mousePos);
  }

  redisplay();
}

void seedMouse(int button, int state, vector mousePos) {
  int mod = glutGetModifiers();

  /* assign a modifier so we can see them in other funcitons */
  if(state == GLUT_DOWN) {
    buttonDown = button;

    if(mod & GLUT_ACTIVE_CTRL) {
      controlDown = TRUE;
    }

    if(mod & GLUT_ACTIVE_SHIFT) {
      shiftDown = TRUE;
    }

    if (mod & GLUT_ACTIVE_ALT ||
        (mod & GLUT_ACTIVE_SHIFT && mod & GLUT_ACTIVE_CTRL)) {
          altDown = TRUE;
    }
    mouseHandler(mousePos);
  }
  else {
    buttonDown = GLUT_NO_BUTTON;
    controlDown = shiftDown = altDown = FALSE;
  }
}

/**
 * mouse motion handler determines the parameters of the action
 */
void seedMouseMotion(vector mousePos) {
  if (buttonDown == GLUT_NO_BUTTON) {
    return;
  }

  mouseHandler(mousePos);
}
