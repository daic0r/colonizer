#version 410

flat in vec3 vsNormal;
in vec3 toLight;
in vec2 shadowMapCoord;
in float distToLight;
in float distFromCam;
in float visibility;
flat in vec4 vertexColor;

out vec4 outColor;

uniform sampler2D tex;
uniform sampler2D shadowMap;
//uniform float shadowDistance;
//uniform float shadowMargin;
layout(std140) uniform CommonMatrices
{
	mat4 shadowProjViewMatrix;
	float shadowDistance;
	float shadowMargin;
	float shadowTexelSize;
	vec4 sunPosition;
	vec4 sunColor;
	vec4 sunAmbient;
};

void main(void) {
    
    float brightness = 1.0;
    if (length(vsNormal) > 0) {
        float fDot = dot(vsNormal, toLight);
        brightness = max(fDot,0.0);
    }
    vec4 dif = brightness * sunColor;
  
    outColor = (sunAmbient + dif) * vertexColor;
    
	
	//outColor = vec4(0.062, 0.544, 0.297, 1.0);
	
	const float fOneOverNumSamples = 1.0 / 25.0;
	float fTotalShadow = 0.0;
	for (float x = -2; x <= 2; ++x) {
		float u = x * shadowTexelSize + shadowMapCoord.x;
		if (u < 0.0 || u > 1.0)
			continue;
		for (float y = -2; y <= 2; ++y) {
			float v = y * shadowTexelSize + shadowMapCoord.y;
			if (v < 0.0 || v > 1.0)
				continue;
			float fInShadow = 0.0;
			float fDistAtUV = texture(shadowMap, vec2(u,v)).r;
			// Vertices outside the shadow box will have a distance of greater than 1
			// Depth map has no values greater than 1, therefore everything farther away
			// than 1 will be in the shadow if we only check distance ( > 1) < shadowMapEntry (<= 1).
			// Therefore, also check if distToLight is <= 1.0 == inside the shadow box
			if (distToLight <= 1.0 && fDistAtUV < (distToLight - .00001))
				fInShadow = 1.0;
			fTotalShadow += fInShadow * fOneOverNumSamples;
		}
	}
	float fDarkeningFactor = 1.0;
	fDarkeningFactor -= (fTotalShadow * 0.4) * clamp(1.0 - (distFromCam - (shadowDistance - shadowMargin)) / shadowMargin, 0.0, 1.0);
	outColor = vec4(outColor.rgb * fDarkeningFactor, 1.0);
	outColor = mix(vec4(1.0, 1.0, 1.0, 1.0), outColor, visibility);
}
