#version 140

in vec3 vertexPos;
out vec3 texCoord;
uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

uniform float rotation;

mat4 rotateY(float angle) {
	float s = sin(angle);
	float c = cos(angle);

	return mat4(
		c, 0.0, -s, 0.0,
		0.0, 1.0, 0.0, 0.0,
		s, 0.0, c, 0.0,
		0.0, 0.0, 0.0, 1.0
	);
}

void main() {
    texCoord = vertexPos;
    gl_Position = (projection * view * rotateY(rotation) * vec4( vertexPos, 1.0 )).xyww;
}

