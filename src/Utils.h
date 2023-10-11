//
//  Utils.h
//  CircularBells
//
//  Created by Andrea Franceschini on 13/12/2020.
//

#ifndef Utils_h
#define Utils_h

#include <vector>
#include <string>
#include <map>

#include "json.hpp"

struct Scale {
    std::string id;
    std::map<std::string, std::string> name;
    std::vector<int> notes;

    NLOHMANN_DEFINE_TYPE_INTRUSIVE(Scale, id, name, notes)
};

struct Instrument {
    std::string filename;
    std::map<std::string, std::string> name;
    std::string preset;

    NLOHMANN_DEFINE_TYPE_INTRUSIVE(Instrument, filename, name, preset)
};

#endif /* Utils_h */
