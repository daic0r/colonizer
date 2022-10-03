#version 410

in vec3 vertexPos;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

void main(void) {
    gl_Position = projection * view * model * vec4(vertexPos, 1);
}
