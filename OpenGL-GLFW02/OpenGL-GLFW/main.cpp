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
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <iostream>
#include <math.h>
#include <sstream>
#include <string>

#include "Buffer.hpp"
#include "Program.hpp"
#include "Shader.hpp"

using namespace std;
using namespace gl;

static void key_callback(GLFWwindow *window, int key, int scancode, int action, int mode) {
	//如果按下ESC，把windowShouldClose设置为True，外面的循环会关闭应用
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
		glfwSetWindowShouldClose(window, GL_TRUE);
		std::cout << "ESC " << mode << std::endl;
	}
}

static GLsizei viewportWitdh  = 680;
static GLsizei viewportheight = 420;

static void framebuffer_size_callback(GLFWwindow *window, int width, int height) {
	viewportWitdh  = width;
	viewportheight = height;
	glViewport(0, 0, width, height);
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
	GLFWwindow *window = glfwCreateWindow(viewportWitdh, viewportheight, "hello world", NULL, NULL);
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

	const string imageName  = "iu_01.jpg";
	const string shaderName = "Texture";

	shared_ptr<Buffer> buffer(new Buffer(imageName));
	shared_ptr<Shader> shader(new Shader(shaderName));
	shared_ptr<Program> program(new Program(shader, buffer));

	//	glm::mat4 trans(1.0f);
	//	trans = glm::rotate(trans, glm::radians(90.0f), glm::vec3(0.0, 0.0, 1.0));
	//	trans = glm::scale(trans, glm::vec3(0.5, 0.5, 0.5));

	glEnable(GL_DEPTH_TEST);

	while (!glfwWindowShouldClose(window)) {

		//		glm::mat4 trans(1.0f);
		//		trans = glm::translate(trans, glm::vec3(0.5f, -0.5f, 0.0f));
		//		trans = glm::rotate(trans, (float)glfwGetTime(), glm::vec3(0.0f, 0.0f, 1.0f));

		glm::mat4 model(1.0f);
		model = glm::rotate(model, (float)glfwGetTime() * glm::radians(50.0f), glm::vec3(0.5f, 1.0f, 1.0f));
		glm::mat4 view(1.0f);
		// 注意，我们将矩阵向我们要进行移动场景的反方向移动。
		view = glm::translate(view, glm::vec3(0.0f, 0.0f, -3.0f));
		glm::mat4 projection(1.0f);
		projection = glm::perspective(glm::radians(45.0f), (float)viewportWitdh / (float)viewportheight, 0.1f, 100.0f);

		glClearColor(0.2, 0.3, 0.3, 1);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		// 激活着色器
		program->Use();
		//		glUniformMatrix4fv(glGetUniformLocation(program->getID(), "transform"), 1, GL_FALSE, glm::value_ptr(trans));
		glUniformMatrix4fv(glGetUniformLocation(program->getID(), "model"), 1, GL_FALSE, glm::value_ptr(model));
		glUniformMatrix4fv(glGetUniformLocation(program->getID(), "view"), 1, GL_FALSE, glm::value_ptr(view));
		glUniformMatrix4fv(glGetUniformLocation(program->getID(), "projection"), 1, GL_FALSE, glm::value_ptr(projection));
		program->Draw();
		// 交换缓冲并查询IO事件
		glfwSwapBuffers(window);
		glfwPollEvents();
	}
	glfwTerminate();
	return EXIT_SUCCESS;
}

