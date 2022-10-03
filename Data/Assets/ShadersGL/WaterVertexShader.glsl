#version 410

layout(location=0) in vec2 vertexPos;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;
uniform vec3 lightPos;
uniform vec3 cameraPosition;

out vec4 clipSpaceCoord;
out vec2 texCoords;
out vec3 fromLightVector;
out vec3 toCameraVector;

const float tiling = 6.0;

void main(void) {
    texCoords = ((vertexPos / 2.0) + 0.5) *  tiling;
    vec4 worldPosition = model * vec4(vertexPos.x, 0, vertexPos.y, 1.0);
    clipSpaceCoord = projection * view * worldPosition;
    toCameraVector = cameraPosition - worldPosition.xyz;
    fromLightVector = worldPosition.xyz - lightPos;
    gl_Position = clipSpaceCoord;
}
