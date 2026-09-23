/*
 * delay.h
 *
 *  Created on: 2021Äê9ÔÂ22ÈÕ
 *      Author: taoshj
 */

#ifndef SRC_DELAY_H_
#define SRC_DELAY_H_

#include "sleep.h"


#define	mdelay(msecs)	usleep(1000*msecs)
#define udelay(usecs) 	usleep(usecs)

//void udelay(unsigned long usecs);
//void mdelay(unsigned long msecs);



#endif /* SRC_DELAY_H_ */
