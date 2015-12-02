#include "cinder/app/App.h"
#include "cinder/app/RendererGl.h"
#include "cinder/gl/gl.h"
#include "cinder/Perlin.h"
#include "cinder/Timeline.h"

#include "CircularBellsApp.h"

#include "mopViews.h"
#include "BellView.h"

#import "EPSSampler.h"

#import "FirstViewController.h"

using namespace ci;
using namespace ci::app;
using namespace std;

FirstViewController *sFirstVC = [[FirstViewController alloc] init];

void CircularBellsApp::setup() {
	_zoom = 1.0;
	_w = getWindowWidth()/(_zoom);
	_h = getWindowHeight()/(_zoom);
	_pan = vec2(0,0);
	_cam = CameraOrtho(-_w/_zoom, _w/_zoom, -_h/_zoom, _h/_zoom, -1000, 1000);
	_cam.lookAt(vec3(0,0,1), vec3(0));
	_projection = _cam.getProjectionMatrix() * _cam.getViewMatrix();
	_screen = vec4(0.0f, getWindowHeight(), getWindowWidth(), -getWindowHeight());
	
	_rootView = make_shared<mop::RootView>();
	getWindow()->getSignalTouchesBegan().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchBegan));
	getWindow()->getSignalTouchesMoved().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchMoved));
	getWindow()->getSignalTouchesEnded().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchEnded));
	
	_scales["Major"] =		{ 0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24 };
	_scales["Dorian"] =		{ 0, 2, 3, 5, 7, 9, 10, 12, 14, 15, 17, 19, 21, 22, 24 };
	_scales["Phrygian"] =	{ 0, 1, 3, 5, 7, 8, 10, 12, 13, 15, 17, 19, 20, 22, 24 };
	_scales["Lydian"] =		{ 0, 2, 4, 6, 7, 9, 11, 12, 14, 16, 18, 19, 21, 23, 24 };
	_scales["Myxolydian"] =	{ 0, 2, 4, 5, 7, 9, 10, 12, 14, 15, 17, 19, 20, 22, 24 };
	_scales["Minor"] =		{ 0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24 };
	_scales["Locrian"] =	{ 0, 1, 3, 5, 6, 8, 10, 12, 13, 15, 17, 18, 20, 22, 24 };

	vector<ColorAf> colors {
		ColorAf(ColorModel::CM_HSV,         0.0, 1.0, 0.8, 1.0),		//
		ColorAf(ColorModel::CM_HSV,  30.0/360.0, 1.0, 1.0, 1.0),		//
		ColorAf(ColorModel::CM_HSV,  60.0/360.0, 1.0, 1.0, 1.0),		//
		ColorAf(ColorModel::CM_HSV, 120.0/360.0, 1.0, 0.8, 1.0),		//
		ColorAf(ColorModel::CM_HSV, 190.0/360.0, 1.0, 1.0, 1.0),		//
		ColorAf(ColorModel::CM_HSV, 210.0/360.0, 1.0, 0.8, 1.0),		//
		ColorAf(ColorModel::CM_HSV, 290.0/360.0, 1.0, 0.8, 1.0),		//
	};
	_tones = _scales["Major"];
	float a = toRadians(360.0/(_tones.size()+1));
	for(int i = 0; i < _tones.size(); ++i) {
		auto v = make_shared<BellView>();
		v->setSize(vec2(100.0f));
		vec2 rPos = vec2(rotate(a*i, vec3(0.0, 0.0, 1.0)) * vec4(200 + arc4random_uniform(100), 0.0, 1.0, 1.0));
		v->setPosition(rPos);
		v->getTouchDownInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchDown));
		v->getTouchUpInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchUp));
		v->getTouchUpOutside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchUp));
		v->getTouchDragInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewDragged));
		v->getTouchDragOutside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewDragged));
		v->setRadius(100.0f - 2*_tones[i]);
		v->setPitch(i);
		auto color = colors[i%7];
		v->setColor(color);
		_rootView->addSubView(v);
	}
	_currentScaleName = "Major";
	
	_rootView->getTouchDragInside().connect(ci::signals::slot(this, &CircularBellsApp::rootDragged));

	setInstrument("CircBell");
	
	_cue = timeline().add(bind(&CircularBellsApp::_timedPush, this), timeline().getCurrentTime() + 1);
	_cue->setDuration(1);
	_cue->setAutoRemove(false);
	_cue->setLoop();
	
	getSignalWillResignActive().connect(ci::signals::slot(this, &CircularBellsApp::willResignActive));
	getSignalDidBecomeActive().connect(ci::signals::slot(this, &CircularBellsApp::didBecomeActive));
}

void CircularBellsApp::willResignActive() {
	_cue->reset();
	_cue = nullptr;
	_active = false;
	ci::app::setFrameRate(0.5f);
}

void CircularBellsApp::didBecomeActive() {
	_cue = timeline().add(bind(&CircularBellsApp::_timedPush, this), timeline().getCurrentTime() + 1);
	_cue->setDuration(1);
	_cue->setAutoRemove(false);
	_cue->setLoop();
	_active = true;
	ci::app::setFrameRate(60.0f);
}

void CircularBellsApp::setInstrument(string name) {
	NSURL* presetUrl = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"assets/%@", [NSString stringWithUTF8String:name.c_str()]] withExtension:@"aupreset"];
	_sampler = [[EPSSampler alloc] initWithPresetURL:presetUrl];
	_instrumentName = name;
}

vector<string> CircularBellsApp::getAvailableScales() {
	vector<string> r;
	for(auto e : _scales) {
		r.push_back(e.first);
	}
	return r;
}

void CircularBellsApp::setCurrentScale(string name) {
	if(_scales.find(name) != _scales.end()) {
		_tones = _scales[name];
		_currentScaleName = name;
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
					float F = 0.25f * (aRadius*bRadius)/pow(length(aPos-bPos)*2.0f, 2.0f);
					aBell->push(F * normalize(aPos - bPos));
					bBell->push(F * normalize(bPos - aPos));
				}
			}
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
	console() << getWindowSize() << endl;
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
	if(auto bellView = static_cast<BellView*>(view)) {
		bellView->setPosition(bellView->getPosition() + position - prevPosition);
	}
}

void CircularBellsApp::rootDragged(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition) {
	_pan -= (position - prevPosition);
	_cam.lookAt(vec3(_pan, 1), vec3(_pan, 0));
	_cam.setOrtho(-_w/_zoom, _w/_zoom, -_h/_zoom, _h/_zoom, -1000, 1000);
	_projection = _cam.getProjectionMatrix() * _cam.getViewMatrix();
}

CINDER_APP(CircularBellsApp,
		   RendererGl(RendererGl::Options().msaa(1)),
		   [](App::Settings* settings) {
			   settings->setHighDensityDisplayEnabled(true);
			   settings->setMultiTouchEnabled();
			   settings->setFrameRate(60.0f);
//			   settings->disableFrameRate();
			   settings->prepareWindow(Window::Format().rootViewController(sFirstVC));
		   });