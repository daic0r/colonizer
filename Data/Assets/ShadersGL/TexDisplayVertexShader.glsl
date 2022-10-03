#version 410

in vec2 vertexPos;
out vec2 texCoord;

void main() {
	texCoord = vertexPos;
	gl_Position = vec4(vertexPos, -1, 1);
}