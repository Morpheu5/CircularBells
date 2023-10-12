#include <exception>
#include <algorithm>

#include "cinder/app/App.h"
#include "cinder/app/RendererGl.h"
#include "cinder/gl/gl.h"
#include "cinder/Perlin.h"
#include "cinder/Timeline.h"

#include "CircularBellsApp.h"

#include "mopViews.h"
#include "BellView.h"

#include "StoredStateManager.h"
#include "Utils.h"

#ifdef __APPLE__
#import "CBAppDelegateImpl.h"
#import "EPSSampler.h"
#import "FirstViewController.h"
#elif __ANDROID
// TODO: Complete this
#endif

using namespace ci;
using namespace ci::app;
using namespace std;

#ifdef __APPLE__
FirstViewController *sFirstVC = [[FirstViewController alloc] init];
#elif __ANDROID__
// TODO: Complete this
#endif

void CircularBellsApp::launch() {
	const auto &args = getCommandLineArgs();
	int argc = (int)args.size();
	
	char* argv[argc];
	for( int i = 0; i < argc; i++ )
		argv[i] = const_cast<char *>( args[i].c_str() );
#ifdef __APPLE__
	::UIApplicationMain( argc, argv, nil, ::NSStringFromClass( [CBAppDelegateImpl class] ) );
#elif __ANDROID__
    // TODO: Complete this
#endif
}

void CircularBellsApp::setup() {
    _zoom = 1.0;
    _w = getWindowWidth()/(_zoom);
    _h = getWindowHeight()/(_zoom);
    _pan = vec2(0,0);
    _cam = CameraOrtho(-_w/_zoom, _w/_zoom, -_h/_zoom, _h/_zoom, -1000, 1000);
    _cam.lookAt(vec3(0,0,1), vec3(0));
    _projection = _cam.getProjectionMatrix() * _cam.getViewMatrix();
    _screen = vec4(0.0f, getWindowHeight(), getWindowWidth(), -getWindowHeight());

    // Pure Data setup
#ifdef __APPLE__
    _pd = [[PdAudioController alloc] init];
    int sampleRate = (int)[[AVAudioSession sharedInstance] sampleRate];
    int numberOfChannels = (int)[[AVAudioSession sharedInstance] outputNumberOfChannels];
    PdAudioStatus pdInit = [_pd configurePlaybackWithSampleRate:sampleRate numberChannels:numberOfChannels inputEnabled:NO mixingEnabled:YES];
    if (pdInit != PdAudioOK) {
        console() << "Could not initialize PD." << std::endl;
    }
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    [PdBase addToSearchPath:[NSString stringWithFormat:@"%@/pd-sampler/", bundlePath]];
#elif __ANDROID__
    // TODO: Complete this
    _pd = whatevs
#endif
    try {
        _pdSampler = shared_ptr<PDSampler>(new PDSampler(@"pd-sampler/main.pd"));
    } catch (std::runtime_error& e) {
        console() << "Could not load the PD patch." << std::endl << e.what() << std::endl;
    }
    _pd.active = true;
    
    auto m = StoredStateManager::getManager();
    if (m != nullptr) {
        setInstrument(m->preset(), m->filename());
    }

#ifdef __APPLE__
    string lang = [[NSBundle preferredLocalizationsFromArray:@[@"es", @"en", @"it"]] objectAtIndex:0].UTF8String;
    string filepath = [[NSBundle mainBundle] pathForResource:@"assets/Scales" ofType:@"json"].UTF8String;
#elif __ANDROID__
    // TODO: Complete this
    string lang = ...
    string filepath = ...
#endif
    std::ifstream i(filepath);
    nlohmann::json j = nlohmann::json::parse(i);
    auto scales = j.get<std::vector<Scale>>();

    for(Scale scale : scales) {
        std::vector<int> notes;
        for(int note : scale.notes) {
            notes.push_back(note);
        }
        std::string scaleId = scale.id;
        _scales.push_back(std::pair<std::string, std::vector<int>>(scaleId, notes));
        _localizedScaleNames.push_back(std::pair<std::string, std::string>(scaleId, scale.name[lang]));
    }

	_rootView = make_shared<mop::RootView>();
	getWindow()->getSignalTouchesBegan().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchBegan));
	getWindow()->getSignalTouchesMoved().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchMoved));
	getWindow()->getSignalTouchesEnded().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchEnded));
	_rootView->getTouchDragInside().connect(ci::signals::slot(this, &CircularBellsApp::rootDragged));
	
	getSignalWillResignActive().connect(ci::signals::slot(this, &CircularBellsApp::willResignActive));
	getSignalDidBecomeActive().connect(ci::signals::slot(this, &CircularBellsApp::didBecomeActive));
}

map<unsigned long, vec2> CircularBellsApp::getInitialPositions(const bool reset = false) {
	map<unsigned long, vec2> positions;
    auto m = StoredStateManager::getManager();
    if (!reset && m != nullptr && !m->notes().empty()) {
        positions = m->notes();
    } else {
        float a = toRadians(360.0/(_tones.size()+1));
        for(int i = 0; i < _tones.size(); ++i) {
            positions[i] = vec2(rotate((float)M_PI-a*i, vec3(0.0, 0.0, 1.0)) * vec4(200 + arc4random_uniform(100), 0.0, 1.0, 1.0));
        }
    }
	return positions;
}

void CircularBellsApp::resetPositions() {
	auto positions = getInitialPositions(true);
	for(auto v : _rootView->getSubviews()) {
		if(auto bv = dynamic_pointer_cast<BellView>(v)) {
			vec2 d = positions[bv->id()-2] - bv->getPosition();
			bv->push(0.5f*d);
		}
	}
}

void CircularBellsApp::setupNotes() {
    StoredStateManager* m = StoredStateManager::getManager();
    if (m != nullptr) {
        string scale = m->scale();
        vector<pair<string, string>> scales = getAvailableScales();
        auto foundScale = std::find_if(scales.begin(), scales.end(), [&] (const pair<string, string>& s) { return s.first == scale; });

        if (foundScale != scales.end()) {
            setCurrentScale(foundScale->first);
        } else {
            setCurrentScale("major");
        }
	} else {
		// Some sensible defaults
        setCurrentScale("major");
    }

	if(_rootView->getSubviews().empty()) {
		// We have to start fresh
		vector<ColorAf> colors {
			ColorAf(ColorModel::CM_HSV,         0.0, 1.0, 0.8, 1.0),		//
			ColorAf(ColorModel::CM_HSV,  30.0/360.0, 1.0, 1.0, 1.0),		//
			ColorAf(ColorModel::CM_HSV,  60.0/360.0, 1.0, 1.0, 1.0),		//
			ColorAf(ColorModel::CM_HSV, 120.0/360.0, 1.0, 0.8, 1.0),		//
			ColorAf(ColorModel::CM_HSV, 190.0/360.0, 1.0, 1.0, 1.0),		//
			ColorAf(ColorModel::CM_HSV, 210.0/360.0, 1.0, 0.8, 1.0),		//
			ColorAf(ColorModel::CM_HSV, 290.0/360.0, 1.0, 0.8, 1.0),		//
		};

		map<unsigned long, vec2> positions = getInitialPositions();

		for(int i = 0; i < _tones.size(); ++i) {
			auto bv = make_shared<BellView>();
			bv->setRadius(100.0f - 2*_tones[i]);
			bv->setSize(vec2(bv->getRadius()));
			bv->setPitch(i);
			auto color = colors[i%7];
			bv->setColor(color);
            bv->setPosition(positions[i]);

			bv->getTouchDownInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchDown));
			bv->getTouchUpInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchUp));
			bv->getTouchUpOutside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchUp));
			bv->getTouchDragInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewDragged));
			bv->getTouchDragOutside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewDragged));

			_rootView->addSubView(bv);
		}
	}
}

void CircularBellsApp::willResignActive() {
	_cue->reset();
	_cue = nullptr;
	_active = false;
    _pd.active = false;
	
	// Save the current state
    auto m = StoredStateManager::getManager();
    if (m != nullptr) {
        m->setPreset(_preset);
        m->setFilename(_sampleFilename);
        m->setScale(_currentScaleName);

        map<unsigned long, vec2> notes;
        if (_rootView != nullptr && !(_rootView->getSubviews().empty())) {
            auto subviews = _rootView->getSubviews();
            for (auto v : subviews) {
                if (auto bv = dynamic_pointer_cast<BellView>(v)) {
                    int pitch = bv->getPitch();
                    notes[pitch] = bv->getPosition();
                }
            }
        }
        m->setNotes(notes);

        m->saveState();
    }
	
	slowDownFrameRate();
}

void CircularBellsApp::didBecomeActive() {
	_cue = timeline().add(bind(&CircularBellsApp::_timedPush, this), timeline().getCurrentTime() + 1);
	_cue->setDuration(1);
	_cue->setAutoRemove(false);
	_cue->setLoop();
	_active = true;
    _pd.active = YES;

	setupNotes();
	
	speedUpFrameRate();
}

string CircularBellsApp::saveScreenshot() {
    // TODO: Convert this to C++
//	NSError *error;
//	NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
//	if(url != nil) {
//		url = [url URLByAppendingPathComponent:@"screenshot.png"];
//		string path = string(url.path.UTF8String);
//		writeImage(path, copyWindowSurface());
//		return path;
//	}
	return "";
}

map<int, vec2> CircularBellsApp::getPositions() {
	map<int, vec2> positions;
	for(auto v : _rootView->getSubviews()) {
		if(auto bv = dynamic_pointer_cast<BellView>(v)) {
			positions[bv->getPitch()] = bv->getPosition();
		}
	}
	return positions;
}

void CircularBellsApp::setPositions(map<int, vec2> positions) {
	for(auto v : _rootView->getSubviews()) {
		if(auto bv = dynamic_pointer_cast<BellView>(v)) {
			bv->setPosition(positions[bv->getPitch()]);
		}
	}
}

void CircularBellsApp::setInstrument(string preset, string filename) {
#ifdef __APPLE__
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    _pdSampler->loadSample([NSString stringWithFormat:@"%@/Sounds/%@", bundlePath, [NSString stringWithCString:filename.c_str() encoding:NSUTF8StringEncoding]]);
#elif __ANDROID__
    // TODO: Complete this
#endif
	_preset = preset;
    _sampleFilename = filename;
    auto m = StoredStateManager::getManager();
    if (m != nullptr) {
        m->setPreset(preset);
        m->setFilename(filename);
    }
}

vector<pair<string, string>> CircularBellsApp::getAvailableScales() {
	return _localizedScaleNames;
}

void CircularBellsApp::setCurrentScale(string name) {
	for(auto it = _scales.begin(); it != _scales.end(); ++it) {
		if(it->first == name) {
			_tones = it->second;
			_currentScaleName = name;
			return;
		}
	}
}

void CircularBellsApp::_timedPush() {
	if(!_noiseEnabled) {
		return;
	}
	for(auto v : _rootView->getSubviews()) {
		if(auto bv = dynamic_pointer_cast<BellView>(v)) {
			auto p = bv->getPosition();
			bv->push(normalize(vec2(_noise.dfBm(p.x, p.y, getElapsedSeconds()))) / (bv->getRadius()));
		}
	}
}

void CircularBellsApp::update() {
	if(!_active) {
		return;
	}
	
	if(_noiseEnabled) {
		auto subViews = _rootView->getSubviews();
		for(auto a = subViews.begin(); a != prev(subViews.end()); ++a) {
			for(auto b = next(a); b != subViews.end(); ++b) {
				auto aBell = dynamic_pointer_cast<BellView>(*a);
				auto bBell = dynamic_pointer_cast<BellView>(*b);
				if(aBell != nullptr && bBell != nullptr) {
					auto aPos = aBell->getPosition();
					auto bPos = bBell->getPosition();
					auto aRadius = aBell->getRadius();
					auto bRadius = bBell->getRadius();
					float F = (_w * 0.08)*(aRadius*bRadius)/pow(length(aPos-bPos)*3.0f, 2.0f);
					aBell->push(F * normalize(aPos - bPos));
					bBell->push(F * normalize(bPos - aPos));
				}
			}
		}
		for(auto b : subViews) {
			auto bell = dynamic_pointer_cast<BellView>(b);
			bell->push(-0.01f * bell->getPosition());
		}
	}
	_rootView->update();
}

void CircularBellsApp::draw() {
	if(!_active) {
		return;
	}

	gl::clear(ColorAf(ColorModel::CM_HSV, 300.0f/360.0f, 0.1f, 0.5f, 1.0f));
	gl::color(Color::white());
	
	gl::setMatrices(_cam);
	{
		gl::ScopedMatrices m;
		auto t = glm::translate(vec3(_rootView->getPosition(), 0.0)) * glm::rotate(_rootView->getAngle(), vec3(0,0,1));
		gl::multModelMatrix(t);
		_rootView->draw();
	}
}

void CircularBellsApp::resize() {
	_w = getWindowWidth()/(_zoom);
	_h = getWindowHeight()/(_zoom);
	_cam.lookAt(vec3(_pan, 1), vec3(_pan, 0));
	_cam.setOrtho(-_w/_zoom, _w/_zoom, -_h/_zoom, _h/_zoom, -1000, 1000);
	_projection = _cam.getProjectionMatrix() * _cam.getViewMatrix();
	_screen = vec4(0.0f, getWindowHeight(), getWindowWidth(), -getWindowHeight());
}

void CircularBellsApp::rotateInterface(UIInterfaceOrientation orientation, NSTimeInterval duration) {
}

void CircularBellsApp::noteViewTouchDown(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition) {
	if(auto bellView = static_cast<BellView*>(view)) {
		bellView->setStill();
        _pdSampler->noteOn(48 + _tones[bellView->getPitch()]);
	}
}

void CircularBellsApp::noteViewTouchUp(mop::View *view, mop::TouchSignalType type, vec2 position, vec2 prevPosition) {
	if(auto bellView = static_cast<BellView*>(view)) {
		bellView->setStill(false);
        _pdSampler->noteOff(48 + _tones[bellView->getPitch()]);
	}
}

void CircularBellsApp::noteViewDragged(mop::View *view, mop::TouchSignalType type, vec2 position, vec2 prevPosition) {
	if(_locked) {
		return;
	}

	if(auto bellView = static_cast<BellView*>(view)) {
		bellView->setPosition(bellView->getPosition() + position - prevPosition);
	}
}

void CircularBellsApp::rootDragged(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition) {
	if(_locked) {
		return;
	}
	
	_pan -= (position - prevPosition);
	_cam.lookAt(vec3(_pan, 1), vec3(_pan, 0));
	_cam.setOrtho(-_w/_zoom, _w/_zoom, -_h/_zoom, _h/_zoom, -1000, 1000);
	_projection = _cam.getProjectionMatrix() * _cam.getViewMatrix();
}

void CircularBellsApp::prepareSettings(App::Settings* settings) {
	settings->setHighDensityDisplayEnabled(true);
	settings->setMultiTouchEnabled();
	settings->setFrameRate(60.0f);
#ifdef __APPLE__
	settings->prepareWindow(Window::Format().rootViewController(sFirstVC));
#elif __ANROID__
    // TODO: Complete this
#endif
}

CINDER_APP(CircularBellsApp,
		   RendererGl(RendererGl::Options().msaa(1)),
		   CircularBellsApp::prepareSettings
		   );
