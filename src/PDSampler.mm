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
//    NSString *fullPath = [[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], sampleFilename] stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
//    NSLog(@"Loading %@", fullPath);
    int err = [PdBase sendMessage:sampleFilename withArguments:nil toReceiver:@"filename"];
    NSLog(@"loadSampler: %d", err);
}

void PDSampler::noteOn(unsigned int note) {
    int err = [PdBase sendMessage:[NSString stringWithFormat:@"%d 127", note] withArguments:nil toReceiver:@"toPoly"];
    NSLog(@"noteOn: %d", err);
}

void PDSampler::noteOff(unsigned int note) {
    int err = [PdBase sendMessage:[NSString stringWithFormat:@"%d 0", note] withArguments:nil toReceiver:@"toPoly"];
    NSLog(@"noteOff: %d", err);
}
