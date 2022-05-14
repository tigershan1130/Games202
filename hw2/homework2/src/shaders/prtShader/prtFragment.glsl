#ifdef GL_ES
precision mediump float;
#endif

// Phong related variables
uniform sampler2D uSampler;
uniform vec3 uKd;
uniform vec3 uKs;
uniform vec3 uLightPos;
uniform vec3 uCameraPos;
uniform vec3 uLightRadiance;

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;
varying highp vec3 vColor;

void main(void) {

  float Gamma = 2.2;

  vec4 gammaColor = vec4(pow(vColor.r/3.14, 1.0/Gamma), pow(vColor.g/3.14, 1.0/Gamma), pow(vColor.b/3.14, 1.0/Gamma), 1.0);

  gl_FragColor = gammaColor;
}
