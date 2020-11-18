//
//  StateManager.h
//  CircularBells
//
//  Created by Andrea Franceschini on 09/11/2020.
//

#ifndef StateManager_h
#define StateManager_h

#include <string>
#include <memory>
#include <vector>
#include "cinder/gl/gl.h"

struct StoredState {
    std::string scale;
    std::string preset;
    std::string filename;
    std::map<int, ci::vec2> notes;
};

class StoredStateManager {
    std::shared_ptr<StoredState> _state = nullptr;

protected:
    StoredStateManager() {}

    static StoredStateManager* manager;

public:
    StoredStateManager(StoredStateManager &other) = delete;
    void operator=(const StoredStateManager &) = delete;

    static StoredStateManager* getManager();

    std::string scale()    { return _state->scale; }
    std::string preset()   { return _state->preset; }
    std::string filename() { return _state->filename; }
    std::map<int, ci::vec2> notes() { return _state->notes; }

    void setScale(std::string& scale)       { _state->scale = std::string(scale); }
    void setPreset(std::string& preset)     { _state->preset = std::string(preset); }
    void setFilename(std::string& filename) { _state->filename = std::string(filename); }
    void setNotes(std::map<int, ci::vec2>& notes) { _state->notes = std::map<int, ci::vec2>(notes); }

    void saveState();
};

#endif /* StateManager_h */
