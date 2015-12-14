#include "BellView.h"

BellView::BellView() : View() {
	_rimCircle = gl::Batch::create(geom::Circle().center(vec2(0)).radius(_radius), gl::getStockShader(gl::ShaderDef().color()));
	_bellCircle = gl::Batch::create(geom::Circle().center(vec2(0)).radius(_radius), gl::getStockShader(gl::ShaderDef().color()));
}

void BellView::setRadius(float size) {
	_radius = size;
	setSize(vec2(size));
	_rimCircle = gl::Batch::create(geom::Circle().center(vec2(0)).radius(_radius), gl::getStockShader(gl::ShaderDef().color()));
	_bellCircle = gl::Batch::create(geom::Circle().center(vec2(0)).radius(_radius - 15.0f), gl::getStockShader(gl::ShaderDef().color()));
}

void BellView::update() {
	if(length(_pushForce) > 0.01f) {
		_position += _pushForce;
		_pushForce *= vec2(0.5);
	} else {
		_pushForce = vec2(0.0f);
	}
}

void BellView::draw() {
	gl::color(_color * _rimMultColor);
	_rimCircle->draw();
	gl::color(_color);
	_bellCircle->draw();
	gl::color(Color::white());
}

bool BellView::hitTest(vec2 point) {
	auto p = vec2(rotate(-_angle, vec3(0, 0, 1)) * translate(vec3(-_position, 0)) * vec4(point, 0, 1));
	if(glm::length(p) < _radius) {
		return true;
	} else {
		return false;
	}
}
