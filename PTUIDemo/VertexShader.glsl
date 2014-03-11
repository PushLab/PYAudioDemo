precision highp float;

uniform vec3 _p0;
uniform vec3 _p1;
uniform vec3 _p2;
uniform vec3 _p3;
uniform vec3 _p4;
uniform vec3 _p5;
attribute vec4 _curvePoints;
attribute vec4 _curveColor;
varying vec4 _sharedCurveColor;

void main( void ) {
    float _t = (_curvePoints[0] + 1.0) / 2.0;
    float _1_t = 1.0 - _t;
    float _1_t_5 = _1_t * _1_t * _1_t * _1_t * _1_t;
    float _1_t_4 = _1_t * _1_t * _1_t * _1_t;
    float _1_t_3 = _1_t * _1_t * _1_t;
    float _1_t_2 = _1_t * _1_t;
    float _1_t_1 = _1_t;
    float _t_5 = _t * _t * _t * _t * _t;
    float _t_4 = _t * _t * _t * _t;
    float _t_3 = _t * _t * _t;
    float _t_2 = _t * _t;
    float _t_1 = _t;
    
    gl_Position = _curvePoints;
    gl_Position[1] = (_p0[1] * _1_t_5 * 1.0 +          // P0(1-t)^5
                      _p1[1] * _1_t_4 * _t_1 * 5.0 +   // 5P1(1-t)^4 * t
                      _p2[1] * _1_t_3 * _t_2 * 10.0 +  // 10P2(1-t)^3 * t^2
                      _p3[1] * _1_t_2 * _t_3 * 10.0 +  // 10P3(1-t)^2 * t^3
                      _p4[1] * _1_t_1 * _t_4 * 5.0 +   // 5P4(1-t) * t^4
                      _p5[1] * _t_5 * 1.0);            // P5t^5
    _sharedCurveColor = _curveColor;
}