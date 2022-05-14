attribute vec3 aVertexPosition;
attribute vec3 aNormalPosition;
attribute vec2 aTextureCoord;
attribute mat3 aPrecomputeLT;

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;

uniform mat3 uPrecomputeR;
uniform mat3 uPrecomputeG;
uniform mat3 uPrecomputeB;

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;

varying highp vec3 vColor;

void main(void) {

  vFragPos = (uModelMatrix * vec4(aVertexPosition, 1.0)).xyz;
  vNormal = (uModelMatrix * vec4(aNormalPosition, 0.0)).xyz;

  gl_Position = uProjectionMatrix * uViewMatrix * uModelMatrix *
                vec4(aVertexPosition, 1.0);

  vTextureCoord = aTextureCoord;

  float SHR = dot(aPrecomputeLT[0], uPrecomputeR[0]) + dot(aPrecomputeLT[1], uPrecomputeR[1]) + dot(aPrecomputeLT[2], uPrecomputeR[2]);
  float SHG = dot(aPrecomputeLT[0], uPrecomputeG[0]) + dot(aPrecomputeLT[1], uPrecomputeG[1]) + dot(aPrecomputeLT[2], uPrecomputeG[2]);
  float SHB = dot(aPrecomputeLT[0], uPrecomputeB[0]) + dot(aPrecomputeLT[1], uPrecomputeB[1]) + dot(aPrecomputeLT[2], uPrecomputeB[2]);


  vColor = vec3(SHR, SHG, SHB);
}