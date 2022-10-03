#version 410

in vec2 texCoord;
uniform sampler2D tex;

out vec4 outColor;

void main() {
	float val = 1.0 - texture(tex, texCoord).r;
	val = clamp(5 * val, 0.0, 1.0);
	outColor = vec4(val, 0, 0, 1);
	//outColor  = vec4(1.0);
}