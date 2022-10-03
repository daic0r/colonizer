#version 410

in vec3 vertexPos;
in vec4 color;
in vec3 normal;

//out vec2 fragTexCoord;
flat out vec3 vsNormal;
out vec3 toLight;
out vec2 shadowMapCoord;
out float distToLight;
out float distFromCam;
out float visibility;

flat out vec4 vertexColor;

const float density = 0.002;
const float gradient = 3.5;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;
// x = waterLevel, y = clip plane y component
uniform vec2 waterLevelAndClipPlaneY;
//uniform mat4 shadowProjViewMatrix;
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
	vec4 worldPos = model * vec4(vertexPos, 1.0f);
    gl_Position = projection * view * worldPos;
	if (waterLevelAndClipPlaneY.y != 0)
		gl_ClipDistance[0] = dot(worldPos, vec4(0, waterLevelAndClipPlaneY.y, 0, -1.0 * waterLevelAndClipPlaneY.x * waterLevelAndClipPlaneY.y));
    vsNormal = normal;
    toLight = normalize(sunPosition.xyz - worldPos.xyz);
    //fragTexCoord = texCoord;
	vertexColor = color;
	
	vec3 shadowMapVec = 0.5 + 0.5 * (shadowProjViewMatrix * worldPos).xyz;
	shadowMapCoord = shadowMapVec.xy;
	distToLight = shadowMapVec.z;
	distFromCam = length((view * worldPos).xyz);
	visibility = exp(-pow(distFromCam * density, gradient));
}
