#version 410
const int MAX_INSTANCES = 5000;
const int MAX_JOINTS = 50;

in vec3 vertexPos;
in vec2 texCoord;
in vec3 normal;
in mat4 worldTransform;
in ivec4 jointIds;
in vec4 jointWeights;

out vec2 coord;
out vec3 toLight;
out vec3 outNormal;
out vec3 toCamera;
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
uniform vec3 cameraPos;
//uniform mat4 shadowProjViewMatrix;
uniform samplerBuffer jointTransforms_TBO;
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

    vec4 totalPos = vec4( 0.0 );
    vec4 totalNormal = vec4( 0.0 );
    for (int i = 0; i < 4; ++i) {
		mat4 jointTransform = mat4(
			texelFetch(jointTransforms_TBO, gl_InstanceID * MAX_JOINTS * 4 + jointIds[i] * 4 + 0),
			texelFetch(jointTransforms_TBO, gl_InstanceID * MAX_JOINTS * 4 + jointIds[i] * 4 + 1),
			texelFetch(jointTransforms_TBO, gl_InstanceID * MAX_JOINTS * 4 + jointIds[i] * 4 + 2),
			texelFetch(jointTransforms_TBO, gl_InstanceID * MAX_JOINTS * 4 + jointIds[i] * 4 + 3)
			);
        totalPos += (jointTransform * vec4(vertexPos, 1.0)) * jointWeights[i];
        totalNormal += (jointTransform * vec4(normal, 0.0)) * jointWeights[i];
    }
    
	vec4 worldPosition = worldTransform * totalPos;
    gl_Position = projection * view * worldPosition;
	if (waterLevelAndClipPlaneY.y != 0)
		gl_ClipDistance[0] = dot(worldPosition, vec4(0, waterLevelAndClipPlaneY.y, 0, -1.0 * waterLevelAndClipPlaneY.x * waterLevelAndClipPlaneY.y));
    
    toLight = normalize(sunPosition - worldPosition.xyz);
	toCamera = normalize(cameraPos - worldPosition.xyz);
	outNormal = normalize((worldTransform * totalNormal).xyz);
	
	vec3 shadowMapVec = 0.5 + 0.5 * (shadowProjViewMatrix * worldPosition).xyz;
	shadowMapCoord = shadowMapVec.xy;
	distToLight = shadowMapVec.z;
	distFromCam = length((view * worldPosition).xyz);
	visibility = exp(-pow(distFromCam * density, gradient));
}

