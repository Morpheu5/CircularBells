#include "cinder/app/App.h"
#include "cinder/app/RendererGl.h"
#include "cinder/gl/gl.h"
#include "cinder/Perlin.h"
#include "cinder/Timeline.h"

#import "CBAppDelegateImpl.h"
#include "CircularBellsApp.h"

#include "mopViews.h"
#include "BellView.h"

#import "EPSSampler.h"

#import "FirstViewController.h"

using namespace ci;
using namespace ci::app;
using namespace std;

FirstViewController *sFirstVC = [[FirstViewController alloc] init]; //[[UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"FirstVC"];

void CircularBellsApp::launch() {
	const auto &args = getCommandLineArgs();
	int argc = (int)args.size();
	
	char* argv[argc];
	for( int i = 0; i < argc; i++ )
		argv[i] = const_cast<char *>( args[i].c_str() );
	
	::UIApplicationMain( argc, argv, nil, ::NSStringFromClass( [CBAppDelegateImpl class] ) );
}

void CircularBellsApp::setup() {
	NSError *error = nil;
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
	
	if(error != nil) {
		console() << "Could not set AVAudioSession category: " << [AVAudioSessionCategoryPlayback cStringUsingEncoding:NSUnicodeStringEncoding];
		console() << "Error: " << [[error description] cStringUsingEncoding:NSUnicodeStringEncoding];
	}
	
	_zoom = 1.0;
	_w = getWindowWidth()/(_zoom);
	_h = getWindowHeight()/(_zoom);
	_pan = vec2(0,0);
	_cam = CameraOrtho(-_w/_zoom, _w/_zoom, -_h/_zoom, _h/_zoom, -1000, 1000);
	_cam.lookAt(vec3(0,0,1), vec3(0));
	_projection = _cam.getProjectionMatrix() * _cam.getViewMatrix();
	_screen = vec4(0.0f, getWindowHeight(), getWindowWidth(), -getWindowHeight());

	NSString *lang = [[NSBundle preferredLocalizationsFromArray:@[@"es", @"en", @"it"]] objectAtIndex:0];

	NSString *filepath = [[NSBundle mainBundle] pathForResource:@"assets/Scales" ofType:@"plist"];
	NSArray *scales = nil;
	if([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
		scales = [NSArray arrayWithContentsOfFile:filepath];
	} else {
		console() << "Horrible things happened!" << endl;
	}
	for(NSDictionary *scale in scales) {
		vector<int> notes;
		for(NSNumber *note in scale[@"notes"]) {
			notes.push_back((int)[note intValue]);
		}
		string scaleId = [((NSString *)scale[@"id"]) UTF8String];
		_scales.push_back(pair<string, vector<int>>(scaleId, notes));
		_localizedScaleNames.push_back(pair<string, string>(scaleId, [((NSString *)scale[@"name"][lang]) UTF8String]));
	}

	_rootView = make_shared<mop::RootView>();
	getWindow()->getSignalTouchesBegan().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchBegan));
	getWindow()->getSignalTouchesMoved().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchMoved));
	getWindow()->getSignalTouchesEnded().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchEnded));
	_rootView->getTouchDragInside().connect(ci::signals::slot(this, &CircularBellsApp::rootDragged));
	
	getSignalWillResignActive().connect(ci::signals::slot(this, &CircularBellsApp::willResignActive));
	getSignalDidBecomeActive().connect(ci::signals::slot(this, &CircularBellsApp::didBecomeActive));
}

vector<vec2> CircularBellsApp::getInitialPositions() {
	vector<vec2> positions;
	float a = toRadians(360.0/(_tones.size()+1));
	for(int i = 0; i < _tones.size(); ++i) {
		positions.push_back(vec2(rotate((float)M_PI-a*i, vec3(0.0, 0.0, 1.0)) * vec4(200 + arc4random_uniform(100), 0.0, 1.0, 1.0)));
	}
	return positions;
}

void CircularBellsApp::resetPositions() {
	auto positions = getInitialPositions();
	for(auto v : _rootView->getSubviews()) {
		if(auto bv = dynamic_pointer_cast<BellView>(v)) {
			vec2 d = positions[bv->id()-2] - bv->getPosition();
			bv->push(0.5f*d);
		}
	}
}

void CircularBellsApp::setupNotes() {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error;
	NSURL *url = [fm URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	NSDictionary *state = nil;
	if(url != nil) {
		url = [url URLByAppendingPathComponent:@"restoreState.plist"];
		if([fm fileExistsAtPath:url.path]) {
			state = [NSDictionary dictionaryWithContentsOfURL:url];
		}
	}
	if(state != nil) {
		// If the stored scale isn't one of the available scales, reset it to "major"
		// This should actually never happen more than once ever.
		NSString *scale = (NSString *)state[@"scale"];
		vector<pair<string, string>> scales = getAvailableScales();
		string cScale = [scale cStringUsingEncoding:NSUTF8StringEncoding];
		BOOL scaleFound = NO;
		for(pair<string, string> p : scales) {
			if(cScale == p.first) {
				setCurrentScale(cScale);
				scaleFound = YES;
			}
		}
		if(!scaleFound) {
			setCurrentScale("major");
		}

		NSString *instrument = (NSString *)state[@"instrument"];
		setInstrument([instrument cStringUsingEncoding:NSUTF8StringEncoding]);
	} else {
		// Some sensible defaults
		setCurrentScale("major");
		setInstrument("CircBell");
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

		vector<vec2> positions = getInitialPositions();

		for(int i = 0; i < _tones.size(); ++i) {
			auto bv = make_shared<BellView>();
			bv->setRadius(100.0f - 2*_tones[i]);
			bv->setSize(vec2(bv->getRadius()));
			bv->setPitch(i);
			auto color = colors[i%7];
			bv->setColor(color);
			
			if(state != nil) {
				// But if we do have a state, let's restore it
				NSString *pitch = [NSString stringWithFormat:@"%d", i];
				NSArray *notePosition = (NSArray *)state[@"notes"][pitch];
				bv->setPosition(vec2( ((NSNumber *)notePosition[0]).floatValue, ((NSNumber *)notePosition[1]).floatValue ));
			} else {
				bv->setPosition(positions[i]);
			}
			
			bv->getTouchDownInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchDown));
			bv->getTouchUpInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchUp));
			bv->getTouchUpOutside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchUp));
			bv->getTouchDragInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewDragged));
			bv->getTouchDragOutside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewDragged));
			
			_rootView->addSubView(bv);
		}
	} else {
		// We have them already, let's see if we have a state
		if(state != nil) {
			// We have a state
			for(auto v : _rootView->getSubviews()) {
				if(auto bv = dynamic_pointer_cast<BellView>(v)) {
					NSString *pitch = [NSString stringWithFormat:@"%d", bv->getPitch()];
					NSArray *notePosition = (NSArray *)state[@"notes"][pitch];
					bv->setPosition(vec2( ((NSNumber *)notePosition[0]).floatValue, ((NSNumber *)notePosition[1]).floatValue ));
				}
			}
		} else {
			// We don't have a state
			// So we do nothing
		}
	}
	
	if(state != nil) {
		[fm removeItemAtURL:url error:&error];
	}
}

void CircularBellsApp::willResignActive() {
	_cue->reset();
	_cue = nullptr;
	_active = false;
	
	// Save the current state
	NSMutableDictionary *state = [@{} mutableCopy];
	NSMutableDictionary *notes = [@{} mutableCopy];
	
	for(auto v : _rootView->getSubviews()) {
		if(auto bv = dynamic_pointer_cast<BellView>(v)) {
			NSArray *notePosition = @[[NSNumber numberWithFloat:bv->getPosition().x], [NSNumber numberWithFloat:bv->getPosition().y]];
			[notes setObject:notePosition forKey:[NSString stringWithFormat:@"%d", bv->getPitch()]];
		}
	}
	state[@"notes"] = notes;
	state[@"instrument"] = [NSString stringWithUTF8String:_instrumentName.c_str()];
	state[@"scale"] = [NSString stringWithUTF8String:_currentScaleName.c_str()];
	
	NSError *error;
	NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	BOOL success;
	if(url != nil) {
		url = [url URLByAppendingPathComponent:@"restoreState.plist"];
		success = [state writeToFile:url.path atomically:YES];
	}
	
	slowDownFrameRate();
}

void CircularBellsApp::didBecomeActive() {
	_cue = timeline().add(bind(&CircularBellsApp::_timedPush, this), timeline().getCurrentTime() + 1);
	_cue->setDuration(1);
	_cue->setAutoRemove(false);
	_cue->setLoop();
	_active = true;

	setupNotes();
	
	speedUpFrameRate();
}

string CircularBellsApp::saveScreenshot() {
	NSError *error;
	NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	if(url != nil) {
		url = [url URLByAppendingPathComponent:@"screenshot.png"];
		string path = string(url.path.UTF8String);
		writeImage(path, copyWindowSurface());
		return path;
	}
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

void CircularBellsApp::setInstrument(string name) {
	NSURL* presetUrl = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"assets/%@", [NSString stringWithUTF8String:name.c_str()]] withExtension:@"aupreset"];
	_sampler = [[EPSSampler alloc] initWithPresetURL:presetUrl];
	_instrumentName = name;
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
		[_sampler startPlayingNote:(48 + _tones[bellView->getPitch()]) withVelocity:1.0];
	}
}

void CircularBellsApp::noteViewTouchUp(mop::View *view, mop::TouchSignalType type, vec2 position, vec2 prevPosition) {
	if(auto bellView = static_cast<BellView*>(view)) {
		bellView->setStill(false);
		[_sampler stopPlayingNote:(48 + _tones[bellView->getPitch()])];
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
	settings->prepareWindow(Window::Format().rootViewController(sFirstVC));
}

CINDER_APP(CircularBellsApp,
		   RendererGl(RendererGl::Options().msaa(1)),
		   CircularBellsApp::prepareSettings
		   );
