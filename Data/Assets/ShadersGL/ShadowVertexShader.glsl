#version 410

in vec3 vertexPos;
in mat4 worldTransform;

layout(std140) uniform CommonMatrices
{
	mat4 shadowProjViewMatrix;
	// We don't need the other 2 in this shader
};

void main(){

	gl_Position = shadowProjViewMatrix * worldTransform * vec4(vertexPos, 1.0);

}