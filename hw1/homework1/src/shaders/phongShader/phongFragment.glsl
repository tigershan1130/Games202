#extension GL_OES_standard_derivatives : enable

#ifdef GL_ES
precision mediump float;
#endif

// Phong related variables
uniform sampler2D uSampler;
uniform vec3 uKd;
uniform vec3 uKs;
uniform vec3 uLightPos;
uniform vec3 uCameraPos;
uniform vec3 uLightIntensity;

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;

// Shadow map related variables
#define NUM_SAMPLES 32
#define BLOCKER_SEARCH_NUM_SAMPLES NUM_SAMPLES
#define PCF_NUM_SAMPLES NUM_SAMPLES
#define NUM_RINGS 10
#define TEXEL_SCALE 0.008
#define BIAS 0.0011
#define BLOCKER_GRAIDENT_BIAS 0.005

#define SOFTNESS 0.2
#define SOFT_FALLOFF 15.0
#define SHADOW_DARKNESS 0.1

#define EPS 1e-3
#define PI 3.141592653589793
#define PI2 6.283185307179586

uniform sampler2D uShadowMap;

varying vec4 vPositionFromLight;

highp float rand_1to1(highp float x ) { 
  // -1 -1
  return fract(sin(x)*10000.0);
}

highp float rand_2to1(vec2 uv ) { 
  // 0 - 1
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract(sin(sn) * c);
}


/**
 * Computes the receiver plane depth bias for the given shadow coord in screen space.
 * Inspirations: 
 *		http://mynameismjp.wordpress.com/2013/09/10/shadow-maps/ 
 *		http://amd-dev.wpengine.netdna-cdn.com/wordpress/media/2012/10/Isidoro-ShadowMapping.pdf
 */
vec2 getReceiverPlaneDepthBias (vec3 shadowCoord)
{
	vec2 biasUV;
  vec3 dx = dFdx(shadowCoord);
	vec3 dy = dFdy(shadowCoord);

	biasUV.x = dy.y * dx.z - dx.y * dy.z;
  biasUV.y = dx.x * dy.z - dy.x * dx.z;
  biasUV *= 1.0 / ((dx.x * dy.y) - (dx.y * dy.x));
  return biasUV;
}

float unpack(vec4 rgbaDepth) {
    const vec2 bitShift = vec2(1.0, 1.0/256.0);
    return dot(rgbaDepth.rg, bitShift);
}

float unpackDepthAvg(vec4 rgbaDepth)
{
  const vec2 bitShift = vec2(1.0, 1.0/256.0);
  return dot(rgbaDepth.ba, bitShift);
}

float linstep(float low, float high, float value){
    return clamp((value-low)/(high-low), 0.0, 1.0);
}


vec2 poissonDisk[NUM_SAMPLES];

void poissonDiskSamples( const in vec2 randomSeed ) {

  float ANGLE_STEP = PI2 * float( NUM_RINGS ) / float( NUM_SAMPLES );
  float INV_NUM_SAMPLES = 1.0 / float( NUM_SAMPLES );

  float angle = rand_2to1( randomSeed ) * PI2;
  float radius = INV_NUM_SAMPLES;
  float radiusStep = radius;

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( cos( angle ), sin( angle ) ) * pow( radius, 0.75 );
    radius += radiusStep;
    angle += ANGLE_STEP;
  }
}

void uniformDiskSamples( const in vec2 randomSeed ) {

  float randNum = rand_2to1(randomSeed);
  float sampleX = rand_1to1( randNum ) ;
  float sampleY = rand_1to1( sampleX ) ;

  float angle = sampleX * PI2;
  float radius = sqrt(sampleY);

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( radius * cos(angle) , radius * sin(angle)  );

    sampleX = rand_1to1( sampleY ) ;
    sampleY = rand_1to1( sampleX ) ;

    angle = sampleX * PI2;
    radius = sqrt(sampleY);
  }
}

float findBlocker( sampler2D shadowMap,  vec2 uv, float zReceiver) 
{
  // float depth = unpack(texture2D(shadowMap, uv));  
  // float depthSD = unpackDepthAvg(texture2D(shadowMap, uv));
  // // chevy's inequality
  // float variance = depthSD - pow(depth, 2.00);
  // float d = zReceiver - (depth + BIAS);

  // //float p = smoothstep(zReceiver- BIAS, zReceiver, depth);
  // float pMax = variance / (variance + d * d);

  // return 1.0 - clamp(pMax, 0.0, 1.0);


  float blockSum = 0.0;
  float numBlocks = 0.0;
  
  vec2 receiverPlaneDepthBias = getReceiverPlaneDepthBias(vec3(uv.x, uv.y, zReceiver));

	for(int i = 0; i < BLOCKER_SEARCH_NUM_SAMPLES; i++)
  {
    vec2 offset = uv + poissonDisk[i] * TEXEL_SCALE;
    float depth = unpack(texture2D(shadowMap, offset));

    float biasedZReceiver = zReceiver + BLOCKER_GRAIDENT_BIAS;

    if(depth < biasedZReceiver)
    {
      blockSum+=depth;
      numBlocks+=1.0;
    }
    

  }

  if(numBlocks == 0.0)
    return 0.0;

  return blockSum/numBlocks;
}

float PCF(sampler2D shadowMap, vec4 shadowCoord, float filterRadius) {
  
  // convolution through texel?
  float shadow = 0.0;
  
  // convolution steps
  // for(int x = -sampleSize; x <= sampleSize; x++)
  // {
  //     for(int y = -sampleSize; y <= sampleSize; y++)
  //     {
  //         float pcfDepth = unpack(texture2D(shadowMap, shadowCoord.xy + vec2(x, y) * filterRadius)); 


  //         shadow += (shadowCoord.z > pcfDepth + BIAS) ? 0.3 : 1.0;     
  //     }    
  // }


  // Variance Test, we need mipmap some where, certain effect of variance ssm is shown, but blur is not here...
  // float depth = unpack(texture2D(shadowMap, shadowCoord.xy));  
  // float depthSD = unpackDepthAvg(texture2D(shadowMap, shadowCoord.xy));
  // float depth_2 = pow(depth, 2.0);

  // // chevy's inequality
  // float variance = depthSD - pow(depth, 2.00);
  // float d = shadowCoord.z - depth;

  // float p = smoothstep(shadowCoord.z- BIAS, shadowCoord.z, depth);
  // float pMax = variance / (variance + d * d);

  // shadow = (depth >= pMax) ? 0.3 : 1.0;

  // return shadow;


  // poisson Disk sampling for PCF

  for(int i = 0; i < PCF_NUM_SAMPLES; i++)
  {
    float pcfDepth = unpack(texture2D(shadowMap, shadowCoord.xy + poissonDisk[i] * filterRadius));

    shadow += (shadowCoord.z > pcfDepth + BIAS) ? SHADOW_DARKNESS : 1.0;   
  }

  return shadow/ float(PCF_NUM_SAMPLES);
}



///////// PCSS ///////////
float PCSS(sampler2D shadowMap, vec4 coords){
  
  float shadow = 0.0;
  // STEP 1: avg blocker depth
  float blocker = findBlocker(shadowMap, coords.xy, coords.z);
 
  if(blocker == 0.0)
    return 1.0;

  // STEP 2: penumbra size
  float penumbra = (coords.z - blocker);
  penumbra = 1.0 - pow(1.0 - penumbra, SOFT_FALLOFF);
  float filterRadius = penumbra * SOFTNESS;

  // STEP 3:  pcf filtering
  return PCF(shadowMap, coords, filterRadius);

}


float useShadowMap(sampler2D shadowMap, vec4 shadowCoord){

  vec4 rgbaDepth = texture2D(shadowMap, shadowCoord.xy);

  float depth = unpack(rgbaDepth);  

  return (shadowCoord.z > depth + BIAS) ? SHADOW_DARKNESS : 1.0;
}

vec3 blinnPhong() {
  vec3 color = texture2D(uSampler, vTextureCoord).rgb;
  color = pow(color, vec3(2.2));

  vec3 ambient = 0.05 * color;

  vec3 lightDir = normalize(uLightPos);
  vec3 normal = normalize(vNormal);
  float diff = dot(lightDir, normal) * 0.5 + 0.5;
  vec3 light_atten_coff =
      uLightIntensity / pow(length(uLightPos - vFragPos), 2.0);
  vec3 diffuse = diff * light_atten_coff * color;

  vec3 viewDir = normalize(uCameraPos - vFragPos);
  vec3 halfDir = normalize((lightDir + viewDir));
  float spec = pow(max(dot(halfDir, normal), 0.0), 32.0);
  vec3 specular = uKs * light_atten_coff * spec;

  vec3 radiance = (ambient + diffuse + specular);
  vec3 phongColor = pow(radiance, vec3(1.0 / 2.2));
  return phongColor;
}

void main(void) {

  float visibility;

  vec3 shadowCoord = (vPositionFromLight.xyz / vPositionFromLight.w)*0.5 + 0.5; // NDC

  poissonDiskSamples(shadowCoord.xy);
  //visibility = useShadowMap(uShadowMap, vec4(shadowCoord, 1.0));
  //visibility = PCF(uShadowMap, vec4(shadowCoord, 1.0), TEXEL_SCALE);
  visibility = PCSS(uShadowMap, vec4(shadowCoord, 1.0));

  vec3 phongColor = blinnPhong();

  gl_FragColor = vec4(phongColor * visibility, 1.0);
  //gl_FragColor = vec4(phongColor, 1.0);
}