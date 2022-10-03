#version 410

out vec4 out_color;

in vec2 texCoords1;
in vec2 texCoords2;
in float outBlendFactor;

uniform sampler2D particleTexture;

void main(void) {
    //out_color = texture(particleTexture, texCoords1);
    out_color = mix(texture(particleTexture, texCoords1), texture(particleTexture, texCoords2), outBlendFactor);
}
