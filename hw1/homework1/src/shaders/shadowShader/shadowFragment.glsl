#extension GL_OES_standard_derivatives : enable

#ifdef GL_ES
precision mediump float;
#endif

uniform vec3 uLightPos;
uniform vec3 uCameraPos;

varying highp vec3 vNormal;
varying highp vec2 vTextureCoord;

// 因为需要 variance shadow map, 所以修改了此方法， 精度降低... 16 位代表每个depth.
vec4 pack (float depth, float depth2) {
    // 使用rgba 4字节共32位来存储z值,1个字节精度为1/256
    // gl_FragCoord:片元的坐标,fract():返回数值的小数部分
    vec2 rgbaDepthP = vec2(fract(depth * 65536.0), fract(depth2 * 65536.0));
    vec4 rgbaDepth = vec4(fract(depth), fract(depth * 256.0), fract(depth2) , fract(depth2 * 256.0)); //计算每个点的z值

    rgbaDepth.r = rgbaDepth.r - rgbaDepth.g * (0.00390625);
    rgbaDepth.g = rgbaDepth.g - rgbaDepthP.r * (0.00390625);
    rgbaDepth.b = rgbaDepth.b - rgbaDepth.a * (0.00390625);
    rgbaDepth.a = rgbaDepth.a - rgbaDepthP.g * (0.00390625);

    return rgbaDepth;
}

void main(){

   float depth2 = pow(gl_FragCoord.z, 2.0);

  // approximate the spatial average of vDepth^2
  // to avoid self shadowing.
  float dx = dFdx(gl_FragCoord.z);
  float dy = dFdy(gl_FragCoord.z);
  float depth2Avg = depth2 + 0.50 * (dx*dx + dy*dy);

  //gl_FragColor = vec4( 1.0, 0.0, 0.0, gl_FragCoord.z);
  gl_FragColor = pack(gl_FragCoord.z, depth2Avg);
}