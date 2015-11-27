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
	
	_scales["major"] = { 0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24 };
	_scales["minor"] = { 0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24 };

	vector<ColorAf> colors {
		ColorAf(ColorModel::CM_HSV,         0.0, 1.0, 0.8, 1.0),		//
		ColorAf(ColorModel::CM_HSV,  30.0/360.0, 1.0, 1.0, 1.0),		//
		ColorAf(ColorModel::CM_HSV,  60.0/360.0, 1.0, 1.0, 1.0),		//
		ColorAf(ColorModel::CM_HSV, 120.0/360.0, 1.0, 0.8, 1.0),		//
		ColorAf(ColorModel::CM_HSV, 190.0/360.0, 1.0, 1.0, 1.0),		//
		ColorAf(ColorModel::CM_HSV, 220.0/360.0, 1.0, 0.8, 1.0),		//
		ColorAf(ColorModel::CM_HSV, 290.0/360.0, 1.0, 0.8, 1.0),		//
	};
	_tones = _scales["major"];
	float a = toRadians(450.0/_tones.size());
	for(int i = 0; i < _tones.size(); ++i) {
		auto v = make_shared<BellView>();
		v->setSize(vec2(100.0f));
		vec2 rPos = vec2(rotate(a*i, vec3(0.0, 0.0, 1.0)) * vec4(100 + 100*sqrt(i+1), 0.0, 1.0, 1.0));
		v->setPosition(rPos);
		v->getTouchDownInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchDown));
		v->getTouchUpInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchUp));
		v->getTouchUpOutside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouchUp));
		v->getTouchDragInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewDragged));
		v->getTouchDragOutside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewDragged));
		v->setRadius(100.0f - 2*_tones[i]);
		v->setPitch(i);
		auto color = colors[i%7];// + vec4(0.4*(i/7), 0.4*(i/7), 0.4*(i/7), 1.0);
		v->setColor(color);
		_rootView->addSubView(v);
	}
	_currentScaleName = "major";
	
	_rootView->getTouchDragInside().connect(ci::signals::slot(this, &CircularBellsApp::rootDragged));

	NSURL* presetUrl = [[NSBundle mainBundle] URLForResource:@"assets/CircBell" withExtension:@"aupreset"];
	_sampler = [[EPSSampler alloc] initWithPresetURL:presetUrl];
	
//	_cue = timeline().add(bind(&CircularBellsApp::_timedPush, this), timeline().getCurrentTime() + 1);
//	_cue->setDuration(1);
//	_cue->setAutoRemove(false);
//	_cue->setLoop();
}

vector<string> CircularBellsApp::getAvailableScales() {
	vector<string> r;
	for(auto e : _scales) {
		r.push_back(e.first);
	}
	return r;
}

void CircularBellsApp::setCurrentScale(string &name) {
	if(_scales.find(name) != _scales.end()) {
		_tones = _scales[name];
		_currentScaleName = name;
	}
}

void CircularBellsApp::_timedPush() {
	for(auto v : _rootView->getSubviews()) {
		if(auto bv = dynamic_pointer_cast<BellView>(v)) {
			auto p = bv->getPosition();
			bv->push(_noise.dfBm(p));
		}
	}
}

void CircularBellsApp::update() {
	_rootView->update();
}

void CircularBellsApp::draw() {
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
		[_sampler startPlayingNote:(48 + _tones[bellView->getPitch()]) withVelocity:1.0];
	}
}

void CircularBellsApp::noteViewTouchUp(mop::View *view, mop::TouchSignalType type, vec2 position, vec2 prevPosition) {
	if(auto bellView = static_cast<BellView*>(view)) {
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
			   settings->disableFrameRate();
			   settings->prepareWindow(Window::Format().rootViewController(sFirstVC));
		   });