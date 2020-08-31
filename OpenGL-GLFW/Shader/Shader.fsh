#version 410 core

layout (location = 0) out vec4 color;

uniform vec4 ourColor; // 在OpenGL程序代码中设定这个变量

void main() {
	color = ourColor;//vec4(1.0, 0.5, 0, 1.0);
}
