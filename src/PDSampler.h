//
//  PDSampler.h
//  Circular Bells
//
//  Created by Andrea Franceschini on 30/10/2020.
//

#ifndef PDSampler_h
#define PDSampler_h

#include <string>
#import "PdDispatcher.h"

class PDSampler {
    void* _patch;

public:
    PDSampler(NSString *pdFilename);

    void loadSample(NSString *sampleFilename);
    void noteOn(unsigned long note);
    void noteOff(unsigned long note);
};

#endif /* PDSampler_h */
