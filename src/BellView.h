#pragma once

#include "mopView.h"

class BellView : public mop::View {
	float _radius = 0.0f;
	ColorAf _color = ColorAf(0,0,0,1);
	ColorAf _rimMultColor = ColorAf(0.8f, 0.8f, 0.8f, 1.0f);
	int _pitch = -1;
	
	gl::BatchRef _rimCircle = nullptr;
	gl::BatchRef _bellCircle = nullptr;
	
	vec2 _pushForce;
	
	bool _still = false;
	
public:
	BellView();
	void update() override;
	void draw() override;
	bool hitTest(vec2 position) override;
	
	void setRadius(float size);
	float getRadius() { return _radius; }
	
	void setColor(ColorAf color) { _color = color; }
	
	void setPitch(int pitch) { _pitch = pitch; }
	const int getPitch() const { return _pitch; }
	
	void push(vec2 force) { if(!_still) _pushForce += force; }
	
	bool isStill() { return _still; }
	void setStill(bool still = true) { _still = still; }
};