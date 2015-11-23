#include "BellView.h"

BellView::BellView() : View() {
	_circle = gl::Batch::create(geom::Circle().center(vec2(0)).radius(_size.x/2), gl::getStockShader(gl::ShaderDef().color()));
}

void BellView::setScaleGrade(int grade) {
	_scaleGrade = grade;
	setSize(vec2(300 - (10*grade)));
	_circle = gl::Batch::create(geom::Circle().center(vec2(0)).radius(_size.x/2), gl::getStockShader(gl::ShaderDef().color()));
}

void BellView::draw() {
	{
		gl::ScopedColor c(ColorAf(ColorModel::CM_HSV, 40.0/360.0, 1.0, 1.0, 1.0));
		_circle->draw();
	}
	{
		gl::ScopedMatrices m;
		gl::ScopedColor c(ColorAf(ColorModel::CM_HSV, 50.0/360.0, 1.0, 1.0, 1.0));
		auto t = glm::scale(vec3(0.667, 0.667, 1.0));
		gl::multModelMatrix(t);
		_circle->draw();
	}

	drawSubViews();
}

bool BellView::hitTest(vec2 point) {
	auto p = vec2(rotate(-_angle, vec3(0, 0, 1)) * translate(vec3(-_position, 0)) * vec4(point, 0, 1));
	if(glm::length(p) < _size.x/2) {
		return true;
	} else {
		return false;
	}
}
