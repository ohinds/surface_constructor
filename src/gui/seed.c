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

/* the seeds */
static sliceSeeds *seeds;
static image *fgSeeds = NULL;
static image *bgSeeds = NULL;
static image *overlapSeeds = NULL;
static int showSeeds = TRUE;

/* mouse modifier state */
#define GLUT_NO_BUTTON (GLUT_MIDDLE_BUTTON + 3)
static int buttonDown = GLUT_NO_BUTTON;
static int controlDown = FALSE;
static int shiftDown = FALSE;
static int altDown = FALSE;

/* draw sizes for paintbrush in pixels */
int brushRadius = 4;

/******************************************************
 * functions
 ******************************************************/

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
    free(img);
  }

  /* get image */
  imgBuf = &curDataset->slices[curSlice];

  tex = curDataset->sliceTextures[curSlice];
}

int subToInd(int row, int col, int chan, image *img) {
  return chan + row * 4 + col * (img->width * 4);
}

void assignSeedPixels(list *seedList, int colorDim, image *seedImg) {
  int row, col, chan;
  pixelLocation *location;
  listNode *i;

  for (row = 0; row < seedImg->width; row++) {
    for (col = 0; col < seedImg->height; col++) {
      for (chan = 0; chan < 4; chan++) {
        seedImg->pixels[subToInd(row, col, chan, seedImg)] = 0;
      }
    }
  }

  for (i = getListNode(seedList, 0); i; i = (listNode*) i->next) {
    location = (pixelLocation*) i->data;
    for (chan = 0; chan < 3; chan++) {
      seedImg->pixels[subToInd(location->row,
                               location->col, chan, seedImg)] = 0;
    }
    seedImg->pixels[subToInd(location->row, location->col, colorDim, seedImg)] =
      USHRT_MAX;
    seedImg->pixels[subToInd(location->row,
                             location->col, 3, seedImg)] = USHRT_MAX;
  }
}

void assignOverlapPixels(image *img1, image *img2, int colorDim,
                         image *overlap) {
  int row, col, chan;

  for (row = 0; row < overlap->width; row++) {
    for (col = 0; col < overlap->height; col++) {
      for (chan = 0; chan < 4; chan++) {
        overlap->pixels[subToInd(row, col, chan, overlap)] = 0;
      }

      if (img1->pixels[subToInd(row, col, 3, overlap)] > 0 &&
          img2->pixels[subToInd(row, col, 3, overlap)] > 0) {
        overlap->pixels[subToInd(row, col, colorDim, overlap)] = USHRT_MAX;
        overlap->pixels[subToInd(row, col, 3, overlap)] = USHRT_MAX;
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
      if (seedImg->pixels[subToInd(row, col, chan, seedImg)] > 0) {
        loc = (pixelLocation*) malloc(sizeof(pixelLocation));
        loc->row = row;
        loc->col = col;

        enqueue(seedList, loc);
      }
    }
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

  assignSeedPixels(seeds->fgSeeds, 0, fgSeeds);
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

    if (showSeeds) {
      glBindTexture(textureMethod, fgTex);
      drawTexture();

      glBindTexture(textureMethod, bgTex);
      drawTexture();

      glBindTexture(textureMethod, overlapTex);
      drawTexture();
    }

    glDisable(textureMethod);
  }

  /* build the mode string */
  sprintf(modeString,"slice %d ",curSlice);
  strcat(modeString,"seed");

  strcat(modeString,":");
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
      default:
        break;
  }
}

void addSeed(int foreground, vector mousePos) {
  int row;
  int col;
  int chan;
  int sqBrushRadius = brushRadius * brushRadius;

  image *img = foreground ? fgSeeds : bgSeeds;

  for (row = mousePos.x - brushRadius; row <= mousePos.x + brushRadius; row++) {
    for (col = mousePos.y - brushRadius; col <= mousePos.y + brushRadius;
         col++) {
      if (pow(row - mousePos.x, 2) + pow(col - mousePos.y, 2) > sqBrushRadius) {
        continue;
      }

      if (img->pixels[subToInd(row, col, 3, img)] == 0) {
        for (chan = 0; chan < 4; chan++) {
          img->pixels[subToInd(row, col, chan, img)] = 0;
        }
        img->pixels[subToInd(row, col, foreground ? 0 : 2, img)] = USHRT_MAX;
        img->pixels[subToInd(row, col, 3, img)] = USHRT_MAX;
      }
    }
  }
}

void removeSeed(int foreground, vector mousePos) {
  int row;
  int col;
  int chan;
  int sqBrushRadius = brushRadius * brushRadius;

  image *img = foreground ? fgSeeds : bgSeeds;

  for (row = mousePos.x - brushRadius; row <= mousePos.x + brushRadius; row++) {
    for (col = mousePos.y - brushRadius; col <= mousePos.y + brushRadius;
         col++) {
      if (pow(row - mousePos.x, 2) + pow(col - mousePos.y, 2) > sqBrushRadius) {
        continue;
      }

      if (img->pixels[subToInd(row, col, 3, img)] > 0) {
        for (chan = 0; chan < 4; chan++) {
          img->pixels[subToInd(row, col, chan, img)] = 0;
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
