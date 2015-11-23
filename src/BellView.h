#pragma once

#include "mopView.h"

class BellView : public mop::View {
	int _scaleGrade = 0; // +1
	
	gl::BatchRef _circle;
	
public:
	BellView();
	void draw() override;
	bool hitTest(vec2 position) override;
	
	void setScaleGrade(int grade);
	const int getScaleGrade() const { return _scaleGrade; }
};