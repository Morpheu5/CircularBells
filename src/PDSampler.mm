//
//  PDSampler.cpp
//  Circular Bells
//
//  Created by Andrea Franceschini on 30/10/2020.
//

#include <string>
#include <sstream>
#include <exception>
#include "PDSampler.h"
#import "PdDispatcher.h"

PDSampler::PDSampler(NSString *pdFilename) {
    void *patch = [PdBase openFile:pdFilename path:[[NSBundle mainBundle] resourcePath]];
    if (!patch) {
        std::stringstream s("Could not open PD patch file: ");
        s << [pdFilename cStringUsingEncoding:NSUTF8StringEncoding];
        throw std::runtime_error(s.str());
    }
    _patch = patch;
}

void PDSampler::loadSample(NSString *sampleFilename) {
    int err = [PdBase sendMessage:sampleFilename withArguments:nil toReceiver:@"filename"];
    if (err != 0) {
        NSLog(@"loadSampler :: Could not load %@, error %d", sampleFilename, err);
    }
}

void PDSampler::noteOn(int note) {
    NSArray *args = @[ [NSNumber numberWithInt:note], [NSNumber numberWithInt:64] ];
    int err = [PdBase sendList:args toReceiver:@"toPoly"];
    if (err != 0) {
        NSLog(@"noteOn :: %@", args);
    }
}

void PDSampler::noteOff(int note) {
    NSArray *args = @[ [NSNumber numberWithInt:note], [NSNumber numberWithInt:0] ];
    int err = [PdBase sendList:args toReceiver:@"toPoly"];
    if (err != 0) {
        NSLog(@"noteOn :: %@", args);
    }
}
