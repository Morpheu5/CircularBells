#include "cinder/app/App.h"
#include "cinder/app/RendererGl.h"
#include "cinder/gl/gl.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class CircularBellsApp : public App {
  public:
	void setup() override;
	void mouseDown( MouseEvent event ) override;
	void update() override;
	void draw() override;
};

void CircularBellsApp::setup()
{
}

void CircularBellsApp::mouseDown( MouseEvent event )
{
}

void CircularBellsApp::update()
{
}

void CircularBellsApp::draw()
{
	gl::clear( Color( 0, 0, 0 ) ); 
}

CINDER_APP( CircularBellsApp, RendererGl )
