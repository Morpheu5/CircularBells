#include "cinder/gl/gl.h"
#include "cinder/Perlin.h"
#include "cinder/Timeline.h"

#include "mopViews.h"
#include "BellView.h"

#import "EPSSampler.h"
#import <UIKit/UIKit.h>

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
	map<int, int> _notesLifetime;
	
	Perlin _noise;
	CueRef _cue;
	
	void _timedPush();
	
public:
	void setup() override;
	void update() override;
	void draw() override;
	
	void resize() override;
	void rotateInterface(UIInterfaceOrientation orientation, NSTimeInterval duration);
	
	const vec2 screenToWorld(const vec2& p) override {
		auto q = vec2(glm::unProject(vec3(p, 0.0f), mat4(), _projection, _screen));
		return q;
	}
	
	void noteViewTouchDown(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition);
	void noteViewTouchUp(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition);
	void noteViewDragged(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition);
};