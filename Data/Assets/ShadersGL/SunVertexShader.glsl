#version 410

in vec3 vertexPos;
out vec2 xy;
out float radius;

uniform mat4 projection;
uniform mat4 view;
uniform vec3 sunPosition;

void main(void) {
	mat4 worldTrans = mat4(1.0, 0.0, 0.0, 0.0,
							0.0, 1.0, 0.0, 0.0,
							0.0, 0.0, 1.0, 0.0,
							sunPosition.x, sunPosition.y, sunPosition.z, 1.0);
    gl_Position = projection * view * worldTrans * vec4(vertexPos, 1.0);
	xy = (gl_Position.xy / gl_Position.w) * 0.5 + 0.5;
	gl_Position.z = -gl_Position.w;
	gl_PointSize = 50;
	radius = 25;
}