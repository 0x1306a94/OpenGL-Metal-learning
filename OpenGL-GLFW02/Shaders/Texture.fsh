#version 410 core

in vec3 ourColor;
in vec2 TexCoord;

uniform sampler2D ourTexture;

out vec4 FragColor;

void main() {
//	FragColor = vec4(ourColor, 1.0);
	FragColor = texture(ourTexture, TexCoord);
}
