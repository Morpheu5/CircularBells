#include "cinder/gl/gl.h"
#include "cinder/Perlin.h"
#include "cinder/Timeline.h"

#include "mopViews.h"
#include "BellView.h"

#import "EPSSampler.h"
#import <UIKit/UIKit.h>

class CircularBellsApp : public AppCocoaTouch, public mop::mopViewsApp {
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
	bool _noiseEnabled = false;
	
	void _timedPush();
	
	int _root;
	vector<int> _tones;
	vector<pair<string, vector<int>>> _scales;
	vector<pair<string, string>> _localizedScaleNames;
	string _currentScaleName;
	
	string _instrumentName;
	
	bool _active = true;
	bool _locked = false;
	
public:
	static void prepareSettings(Settings *settings);
	void launch() override;
	void setup() override;
	void setupNotes();
	void update() override;
	void draw() override;
	
	void resize() override;
	void rotateInterface(UIInterfaceOrientation orientation, NSTimeInterval duration);
	
	void willResignActive();
	void didBecomeActive();
	
	const vec2 screenToWorld(const vec2& p) override {
		auto q = vec2(glm::unProject(vec3(p, 0.0f), mat4(), _projection, _screen));
		return q;
	}

	vector<vec2> getInitialPositions();
	void resetPositions();
	
	string saveScreenshot();

	map<int, vec2> getPositions();
	void setPositions(map<int, vec2> positions);
	
	void noteViewTouchDown(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition);
	void noteViewTouchUp(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition);
	void noteViewDragged(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition);
	
	void rootDragged(mop::View* view, mop::TouchSignalType type, vec2 position, vec2 prevPosition);
	
	void setInstrument(string name);
	string& getInstrument() { return _instrumentName; }
	const string& getCurrentScaleName() { return _currentScaleName; }
	void setCurrentScale(string name);
	vector<pair<string, string>> getAvailableScales();
	
	void togglePerlin() { _noiseEnabled = !_noiseEnabled; }
	bool isPerlinEnabled() { return _noiseEnabled; }
	void toggleLocked() { _locked = !_locked; }
	bool isLocked() { return _locked; }
	
	void slowDownFrameRate() { ci::app::setFrameRate(1.0f); }
	void speedUpFrameRate() { ci::app::setFrameRate(60.0f); }
};
