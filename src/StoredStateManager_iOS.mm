//
//  StoredStateManager_iOS.cpp
//  CircularBells
//
//  Created by Andrea Franceschini on 09/11/2020.
//

#include "StoredStateManager.h"

#import <Foundation/Foundation.h>
#import <Foundation/NSDictionary.h>

StoredStateManager* StoredStateManager::manager = nullptr;

StoredStateManager* StoredStateManager::getManager() {
    if (manager == nullptr) {
        manager = new StoredStateManager();
    }

    if (manager->_state == nullptr) {
        manager->_state = std::make_shared<StoredState>();

        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error;
        NSURL *url = [fm URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];

        NSLog(@"Loading state from: %@", url);

        NSDictionary *state = nil;
        if(url != nil) {
            url = [url URLByAppendingPathComponent:@"restoreState.plist"];
            if([fm fileExistsAtPath:url.path]) {
                state = [NSDictionary dictionaryWithContentsOfURL:url];
            }
        }
        if (state != nil) {
            // Pull from plist
            manager->_state->filename = std::string([(NSString *)state[@"filename"] cStringUsingEncoding:NSUTF8StringEncoding]);
            manager->_state->preset   = std::string([(NSString *)state[@"preset"]   cStringUsingEncoding:NSUTF8StringEncoding]);
            manager->_state->scale    = std::string([(NSString *)state[@"scale"]    cStringUsingEncoding:NSUTF8StringEncoding]);
            manager->_state->notes.clear();
            NSDictionary *notes = state[@"notes"];
            [notes enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                unsigned long pitch = [(NSString *)key intValue];
                NSArray *nsPosition = (NSArray *)obj;
                manager->_state->notes[pitch] = ci::vec2([nsPosition[0] floatValue], [nsPosition[1] floatValue]);
            }];
        } else {
            // Set some defaults
            manager->_state->filename = "C.wav";
            manager->_state->preset = "CircBell";
            manager->_state->scale = "major";
        }
    }

    return manager;
}

void StoredStateManager::saveState() {
    NSLog(@"Saving state...");

    NSDictionary *state = [@{} mutableCopy];
    [state setValue:[NSString stringWithCString:_state->filename.c_str() encoding:NSUTF8StringEncoding] forKey:@"filename"];
    [state setValue:[NSString stringWithCString:_state->preset.c_str() encoding:NSUTF8StringEncoding] forKey:@"preset"];
    [state setValue:[NSString stringWithCString:_state->scale.c_str() encoding:NSUTF8StringEncoding] forKey:@"scale"];
    NSDictionary *notes = [@{} mutableCopy];
    for (auto note : _state->notes) {
        unsigned long pitch = note.first;
        ci::vec2 position = note.second;
        NSArray *nsPosition = [NSArray arrayWithObjects:[NSNumber numberWithFloat:position.x], [NSNumber numberWithFloat:position.y], nil];
        [notes setValue:nsPosition forKey:[NSString stringWithFormat:@"%ld", pitch]];
    }
    [state setValue:notes forKey:@"notes"];

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSURL *url = [fm URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (url != nil) {
        url = [url URLByAppendingPathComponent:@"restoreState.plist"];
        NSError *error = nil;
        [state writeToURL:url error:&error];
        if (error != nil) {
            NSLog(@"An error occurred while writing the state to storage: %@", [error localizedDescription]);
        }
    }

    NSLog(@"... state saved.");
}
