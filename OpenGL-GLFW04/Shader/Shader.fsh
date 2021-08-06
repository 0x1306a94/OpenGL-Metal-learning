#version 410 core

in vec2 TexCoord;

uniform sampler2D ourTexture;

out vec4 FragColor;

void main() {
    FragColor = texture(ourTexture, TexCoord);
//    FragColor = vec4(1.0, 0.2, 1.0, 1.0);
}
