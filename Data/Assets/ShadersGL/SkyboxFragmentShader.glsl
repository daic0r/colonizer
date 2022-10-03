#version 140

in vec3 texCoord;
uniform samplerCube skyboxTexture;

out vec4 fragmentColor;

void main() {
    fragmentColor = texture(skyboxTexture, texCoord);
}
