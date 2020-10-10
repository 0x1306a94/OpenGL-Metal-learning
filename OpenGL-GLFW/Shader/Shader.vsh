#version 410 core

layout (location = 0) in vec4 position;
layout (location = 1) in vec3 color;

out vec3 ourColor;

uniform mat4 transform;
uniform bool transformed;

void main() {
	if (transformed) {
		gl_Position = position * transform;
	} else {
		gl_Position = position;
	}
	ourColor = color;//vec3(0.5,0.6,0.8);
}
