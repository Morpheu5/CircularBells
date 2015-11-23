#include "cinder/app/App.h"
#include "cinder/app/RendererGl.h"
#include "cinder/gl/gl.h"

#include "mopViews.h"
#include "BellView.h"

#import "EPSSampler.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class CircularBellsApp : public App, public mop::mopViewsApp {
	CameraOrtho _cam;
	mat4 _projection;
	vec4 _screen;
	
	float _w, _h;
	float _zoom;
	vec2 _pan;

	shared_ptr<mop::RootView> _rootView;
	list<shared_ptr<mop::View>> _views;
	
	EPSSampler* _sampler;
	
public:
	void setup() override;
	void update() override;
	void draw() override;
	
	const vec2 screenToWorld(const vec2& p) override {
		auto q = vec2(glm::unProject(vec3(p, 0.0f), mat4(), _projection, _screen));
		return q;
	}
	
	void noteViewTouched(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition);
	void noteViewDragged(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition);
};

void CircularBellsApp::setup() {
	_zoom = 1.0;
	_w = getWindowHeight()/(_zoom);
	_h = getWindowWidth()/(_zoom);
	if(getOrientation() & InterfaceOrientation::PortraitAll) {
		auto t = _w;
		_w = _h;
		_h = t;
	}
	_pan = vec2(0,0);
	_cam = CameraOrtho(-_w/_zoom, _w/_zoom, -_h/_zoom, _h/_zoom, -1000, 1000);
	_cam.lookAt(vec3(0,0,1), vec3(0));
	
	_projection = _cam.getProjectionMatrix() * _cam.getViewMatrix();
	_screen = vec4(0.0f, getWindowHeight(), getWindowWidth(), -getWindowHeight());
	
	_rootView = make_shared<mop::RootView>();
	getWindow()->getSignalTouchesBegan().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchBegan));
	getWindow()->getSignalTouchesMoved().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchMoved));
	getWindow()->getSignalTouchesEnded().connect(bind(&mop::View::propagateTouches, _rootView, std::placeholders::_1, mop::TouchEventType::TouchEnded));

	for(int i = 0; i < 4; ++i) {
		auto v = make_shared<BellView>();
		v->setSize(vec2(100.0f));
		vec2 rPos = vec2(200 * (i%2), 200 * (i/2));
		v->setPosition(rPos);
		v->getTouchDownInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewTouched));
		v->getTouchDragInside().connect(ci::signals::slot(this, &CircularBellsApp::noteViewDragged));
		v->setScaleGrade(i);
		_rootView->addSubView(v);
	}
	
	NSURL* presetUrl = [[NSBundle mainBundle] URLForResource:@"assets/CircBell" withExtension:@"aupreset"];
	_sampler = [[EPSSampler alloc] initWithPresetURL:presetUrl];
}

void CircularBellsApp::update() {
	// FIXME This stuff should probably be somewhere else for performance.
	_cam.lookAt(vec3(_pan, 1), vec3(_pan, 0));
	_cam.setOrtho(-_w/_zoom, _w/_zoom, -_h/_zoom, _h/_zoom, -1000, 1000);
	_projection = _cam.getProjectionMatrix() * _cam.getViewMatrix();
	_screen = vec4(0.0f, getWindowHeight(), getWindowWidth(), -getWindowHeight());
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

	// Draw UI stuff
}

void CircularBellsApp::noteViewTouched(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition) {
	if(auto bellView = dynamic_cast<BellView*>(view)) {
		unsigned int note = 48 + bellView->getScaleGrade();
		[_sampler startPlayingNote:note withVelocity:1.0];
		std::async(std::launch::async, [&]{ std::this_thread::sleep_for(std::chrono::milliseconds(50)); [_sampler stopPlayingNote:note]; });
	}
}

void CircularBellsApp::noteViewDragged(mop::View *view, mop::TouchSignalType type, vec2 position, vec2 prevPosition) {
	if(auto bellView = dynamic_cast<BellView*>(view)) {
		bellView->setPosition(bellView->getPosition() + (position - prevPosition));
	}
}

CINDER_APP(CircularBellsApp,
		   RendererGl(RendererGl::Options().msaa(1)),
		   [](App::Settings* settings) {
			   settings->setHighDensityDisplayEnabled(true);
			   settings->setMultiTouchEnabled();
			   settings->disableFrameRate();
		   });