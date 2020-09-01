//
//  main.cpp
//  OpenGL-GLFW
//
//  Created by king on 2020/8/30.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <fstream>
#include <iostream>
#include <math.h>
#include <sstream>
#include <string>

using namespace std;

static void key_callback(GLFWwindow *window, int key, int scancode, int action, int mode) {
	//如果按下ESC，把windowShouldClose设置为True，外面的循环会关闭应用
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
		glfwSetWindowShouldClose(window, GL_TRUE);
	std::cout << "ESC " << mode << std::endl;
}

static void framebuffer_size_callback(GLFWwindow *window, int width, int height) {
	glViewport(0, 0, width, height);
}

static std::string ParseShader(const std::string &filename) {
	std::ifstream in(filename);
	std::stringstream buffer;
	buffer << in.rdbuf();
	std::string contents(buffer.str());
	return contents;
}

static GLuint CompileShader(GLenum type, const std::string &source) {
	GLuint id       = glCreateShader(type);
	const char *src = source.c_str();
	glShaderSource(id, 1, &src, NULL);
	glCompileShader(id);

	GLint result;
	glGetShaderiv(id, GL_COMPILE_STATUS, &result);
	if (result == GL_FALSE) {
		GLint length;
		glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
		char *message = (char *)alloca(length * sizeof(char));
		glGetShaderInfoLog(id, length, &length, message);
		std::cout << "Faild to compile " << ((type == GL_VERTEX_SHADER) ? "vertex" : "fragment") << " shader!" << std::endl;
		std::cout << message << std::endl;
		glDeleteShader(id);
		return 0;
	}
	return id;
}

static unsigned int CreateShader(const std::string &vertexShader, const std::string &fragmentShader) {
	GLuint program = glCreateProgram();

	GLuint vs = CompileShader(GL_VERTEX_SHADER, vertexShader);
	GLuint fs = CompileShader(GL_FRAGMENT_SHADER, fragmentShader);

	glAttachShader(program, vs);
	glAttachShader(program, fs);
	glLinkProgram(program);

	GLint result;
	glGetProgramiv(program, GL_LINK_STATUS, &result);
	if (result == GL_FALSE) {
		GLint length;
		glGetProgramiv(program, GL_INFO_LOG_LENGTH, &length);
		char *message = (char *)alloca(length * sizeof(char));
		glGetProgramInfoLog(program, length, &length, message);
		glDeleteShader(vs);
		glDeleteShader(fs);
		return 0;
	}
	glValidateProgram(program);

	glDeleteShader(vs);
	glDeleteShader(fs);

	return program;
}

int main(int argc, const char *argv[]) {

	if (!glfwInit()) {
		return EXIT_FAILURE;
	}

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
//    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);
#ifdef __APPLE__
	glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

	std::cout << "glfw version: " << glfwGetVersionString() << std::endl;
	//创建窗口以及上下文
	GLFWwindow *window = glfwCreateWindow(640, 480, "hello world", NULL, NULL);
	if (!window) {
		//创建失败会返回NULL
		glfwTerminate();
		exit(EXIT_FAILURE);
	}

	glfwMakeContextCurrent(window);

	GLenum err = glewInit();
	if (err != GLEW_OK) {
		const GLubyte *str = glewGetErrorString(err);
		std::cout << str << std::endl;
		return EXIT_FAILURE;
	}

	std::cout << "glew version: " << glewGetString(GLEW_VERSION) << std::endl;
	std::cout << "gl shading language version: " << glGetString(GL_SHADING_LANGUAGE_VERSION) << std::endl;
	glfwSetKeyCallback(window, key_callback);                           //注册回调函数
	glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);  // glfwGetFramebufferSize doesnt work

	/* clang-format off */
    GLfloat vertices[] = {
		// 右上角		  // 颜色
		0.5f, 0.5f, 0.0f, 1.0, 0.0, 0.0,
		// 右下角
		0.5f, -0.5f, 0.0f, 0.0, 1.0, 0.0,
		// 左下角
		-0.5f, -0.5f, 0.0f, 0.0f, 0.0f, 1.0f,
		// 左上角
		-0.5f, 0.5f, 0.0f, 0.3, 0.5, 0.5,
    };

	GLuint indices[] = { // 注意索引从0开始!
		0, 1, 3, // 第一个三角形
		1, 2, 3  // 第二个三角形
	};
	/* clang-format on */

	std::string vertexShaderPath   = "./Shader/Shader.vsh";
	std::string fragmentShaderPath = "./Shader/Shader.fsh";
	std::string vertexShader       = ParseShader(vertexShaderPath);
	std::string fragmentShader     = ParseShader(fragmentShaderPath);
	GLuint shaderProgram           = CreateShader(vertexShader, fragmentShader);
	glUseProgram(shaderProgram);

	GLuint VBO, VAO, EBO;
	glGenBuffers(1, &VBO);
	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

	glGenVertexArrays(1, &VAO);
	glBindVertexArray(VAO);
	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (GLvoid *)0);
	glEnableVertexAttribArray(0);

	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (GLvoid *)(3 * sizeof(GLfloat)));
	glEnableVertexAttribArray(1);

	glGenBuffers(1, &EBO);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

	while (!glfwWindowShouldClose(window)) {

		glClearColor(0.2, 0.3, 0.3, 1);
		glClear(GL_COLOR_BUFFER_BIT);

		// 激活着色器
		glUseProgram(shaderProgram);

		// 更新uniform颜色
		//		float timeValue           = glfwGetTime();
		//		float redValue            = (sin(timeValue) / 2.0f) + 0.2f;
		//		float greenValue          = (sin(timeValue) / 2.0f) + 0.5f;
		//		float blueValue           = (sin(timeValue) / 2.0f) + 0.4f;
		//		GLint vertexColorLocation = glGetUniformLocation(shaderProgram, "ourColor");
		//		glUniform4f(vertexColorLocation, redValue, greenValue, blueValue, 1.0);

		// 绘制三角形
//		glBindVertexArray(VAO);
//		glDrawArrays(GL_TRIANGLES, 0, 3);
//		glBindVertexArray(0);

		// 绘制矩形
		glBindVertexArray(VAO);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
		glBindVertexArray(0);

		// 交换缓冲并查询IO事件
		glfwSwapBuffers(window);
		glfwPollEvents();
	}
	glDeleteVertexArrays(1, &VAO);
	glDeleteBuffers(1, &VBO);
	glDeleteBuffers(1, &EBO);
	glDeleteShader(shaderProgram);
	glfwTerminate();
	return EXIT_SUCCESS;
}

