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

#include "Buffer.hpp"
#include "Program.hpp"
#include "Shader.hpp"

using namespace std;
using namespace gl;

static void key_callback(GLFWwindow *window, int key, int scancode, int action, int mode) {
    //如果按下ESC，把windowShouldClose设置为True，外面的循环会关闭应用
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GL_TRUE);
    std::cout << "ESC " << mode << std::endl;
}

static void framebuffer_size_callback(GLFWwindow *window, int width, int height) {
    glViewport(0, 0, width, height);
}

int main(int argc, const char *argv[]) {

    if (!glfwInit()) {
        return EXIT_FAILURE;
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

    std::cout << "glfw version: " << glfwGetVersionString() << std::endl;
    //创建窗口以及上下文
    GLFWwindow *window = glfwCreateWindow(360, 640, "hello world", NULL, NULL);

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

    const string shaderName = "Shader";

    shared_ptr<Buffer> buffer(new Buffer(glm::vec2(360.0f, 640.0f)));
    shared_ptr<Shader> shader(new Shader(shaderName));
    shared_ptr<Program> program(new Program(shader, buffer));

    glViewport(0, 0, 720, 1280);
    float beginTime = glfwGetTime();

    while (!glfwWindowShouldClose(window)) {

        glClearColor(0.2, 0.3, 0.3, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        float duration = glfwGetTime() - beginTime;
        // 激活着色器
        program->Use();
        program->Draw(duration);

        // 交换缓冲并查询IO事件
        glfwSwapBuffers(window);
        glfwPollEvents();
        if (duration >= 1.5) {
            beginTime = glfwGetTime();
        }
    }
    glfwTerminate();
    return EXIT_SUCCESS;
}

