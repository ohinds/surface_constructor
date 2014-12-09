/*****************************************************************************
 * seed.h is the header file for the seed editing portion of an
 * application to construct surfaces from serial secions
 * Oliver Hinds <oph@cns.bu.edu> 2004-03-16
 *
 *
 *
 *****************************************************************************/

#ifndef SEED_H
#define SEED_H

#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>

#include"surfConUtil.h"

#ifndef MAC
#include<GL/glut.h>
#else
#include<GLUT/glut.h>
#endif

/* externs from surfCon.h */

#include"surfCon.h"
#include"surfCon.extern"
#include"align.h"

/******************************************************
 * functions
 ******************************************************/

/**
 * load the images and perform init on them
 */
void seedImgInit();

/**
 * initialize general properties
 */
void seedInit();

/**
 * uninitializes the seed drawing and imaging stuff
 */
void seedUninit();

/**
 * cleans up
 */
void seedDestroy();

/**
 * check to see if a repaint is needed
 */
int seedRepaintNeeded(long now);

/**
 * do seed specific drawing
 */
void seedDraw();

/** event handlers **/

/**
 * seed actions
 */
void seedAction(int action);

/**
 * creates the menu for the seed
 */
void createSeedMenu();

/**
 * keyboard handler
 */
void seedKeyboard(unsigned char key, int x, int y);

/**
 * mouse button handler
 */
void seedMouse(int button, int state, vector mousePos);

/**
 * mouse motion handler
 */
void seedMouseMotion(vector mousePos);

/** util **/

/**
 * increase the current seed
 */
void increaseSeed();

/**
 * decrease the current seed
 */
void decreaseSeed();

/**
 * gets a seed point color based on a seed id
 */
color getSeedColor(int seedNum);

/**
 * gets a seed point color based on a seed id and grayed
 */
color getGrayedSeedColor(int seedNum);

#endif
