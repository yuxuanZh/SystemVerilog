#include <stdio.h>
#include <stdlib.h>
#include "rmapats.h"

scalar dummyScalar;
scalar fScalarIsForced=0;
scalar fScalarIsReleased=0;
scalar fScalarHasChanged=0;
void  hsF_0(struct dummyq_struct * I734, EBLK  * I735, U  I553);
void  hsF_0(struct dummyq_struct * I734, EBLK  * I735, U  I553)
{
    U  I914;
    U  I915;
    U  I916;
    struct futq * I917;
    I914 = ((U )vcs_clocks) + I553;
    I916 = I914 & 0xfff;
    I735->I483 = (EBLK  *)(-1);
    I735->I493 = I914;
    if (I914 < (U )vcs_clocks) {
        I915 = ((U  *)&vcs_clocks)[1];
        sched_millenium(I734, I735, I915 + 1, I914);
    }
    else if ((I917 = I734->I708[I916].I502)) {
        I735->I494 = (struct eblk *)I917->I501;
        I917->I501->I483 = (RP )I735;
        I917->I501 = (RmaEblk  *)I735;
    }
    else {
        sched_hsopt(I734, I735, I914);
    }
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
