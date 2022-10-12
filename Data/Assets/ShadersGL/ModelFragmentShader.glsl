#version 410

const float SPECULAR_STRENGTH = 0.5;

in vec2 coord;
in vec3 toLight;
in vec3 outNormal;
in vec3 toCamera;
in vec2 shadowMapCoord;
in float distToLight;
in float distFromCam;
in float visibility;
out vec4 outColor;

uniform sampler2D diffuseTex;
uniform sampler2D shadowMap;

uniform vec3 ambient;
uniform vec3 diffuse;
uniform vec3 specular;
uniform float fSpecularExponent;
uniform float fAlpha;
uniform float fRefractionIndex;
uniform bool hasTexture;

//uniform float shadowDistance;
//uniform float shadowMargin;
layout(std140) uniform CommonMatrices
{
	mat4 shadowProjViewMatrix;
	float shadowDistance;
	float shadowMargin;
	float shadowTexelSize;
	vec3 sunPosition;
	vec3 sunColor;
	vec3 sunAmbient;
};

void main(void) {
    vec3 a = ambient;
    vec3 d = diffuse;
    vec3 s = specular;
    float se = fSpecularExponent;
    float al = fAlpha;
    float re = fRefractionIndex;
	vec4 materialColor;
    if (!hasTexture)
        materialColor = vec4(diffuse, 1.0);
    else
        materialColor = texture(diffuseTex, coord);
	float brightnessDiffuse = max(dot(toLight, outNormal), 0.0);
	// Blinn-phong specular shading
	vec3 halfway = normalize(toCamera + toLight);
	float brightnessSpecular = SPECULAR_STRENGTH * pow(max(dot(halfway, outNormal), 0.0), fSpecularExponent);
	vec3 finalLight = (brightnessSpecular + brightnessDiffuse) * sunColor;
	outColor = materialColor * (vec4(finalLight, 1.0) + vec4(sunAmbient, 1.0));
	
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
