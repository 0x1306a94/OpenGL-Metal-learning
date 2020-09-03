#version 410 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 color;

out vec3 ourColor;

void main() {
    gl_Position = vec4(position.x, position.y, position.z, 1.0);
	ourColor = color;//vec3(0.5,0.6,0.8);
}
