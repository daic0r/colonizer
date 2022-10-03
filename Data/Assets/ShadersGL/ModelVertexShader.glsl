#version 410

in vec3 vertexPos;
in vec2 texCoord;
in vec3 normal;
in mat4 worldTransform;

out vec2 coord;
out vec3 toLight;
out vec3 outNormal;
out vec2 shadowMapCoord;
out float distToLight;
out float distFromCam;
out float visibility;

const float density = 0.002;
const float gradient = 3.5;

uniform mat4 projection;
uniform mat4 view;
// x = waterLevel, y = clip plane y component
uniform vec2 waterLevelAndClipPlaneY;
//uniform mat4 shadowProjViewMatrix;
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
    coord = texCoord;//
    //surfaceNormal = normal;
	
	
    vec4 worldPosition = worldTransform * vec4( vertexPos, 1);
    //gl_ClipDistance[0] = dot(worldPosition, plane);
    
    gl_Position = projection * view * worldPosition;
	if (waterLevelAndClipPlaneY.y != 0)
		gl_ClipDistance[0] = dot(worldPosition, vec4(0, waterLevelAndClipPlaneY.y, 0, -1.0 * waterLevelAndClipPlaneY.x * waterLevelAndClipPlaneY.y));
    
    toLight = normalize(sunPosition - worldPosition.xyz);
	outNormal = normalize((worldTransform * vec4(normal, 0.0)).xyz);
	
	vec3 shadowMapVec = 0.5 + 0.5 * (shadowProjViewMatrix * worldPosition).xyz;
	shadowMapCoord = shadowMapVec.xy;
	distToLight = shadowMapVec.z;
	distFromCam = length((view * worldPosition).xyz);
	visibility = exp(-pow(distFromCam * density, gradient));
}
