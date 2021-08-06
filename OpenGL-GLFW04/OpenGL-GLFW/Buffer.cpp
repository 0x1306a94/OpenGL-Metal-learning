//
//  Buffer.cpp
//  OpenGL-GLFW
//
//  Created by king on 2020/9/2.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#include "Buffer.hpp"

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <glm/vec3.hpp>
#include <glm/vec4.hpp>

#ifndef STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#endif
#include "stb_image.h"

namespace gl {

// 右上角
glm::vec4 topRight(1.0f, 1.0f, 0.0f, 1.0f);
// 右下角
glm::vec4 bottomRight(1.0f, -1.0f, 0.0f, 1.0f);
// 左下角
glm::vec4 topLeft(-1.0f, -1.0f, 0.0f, 1.0f);
// 左上角
glm::vec4 bottomLeft(-1.0f, 1.0f, 0.0f, 1.0f);

// 右上角
glm::vec2 topRightTexCoord(1.0, 0.0);
// 右下角
glm::vec2 bottomRightTexCoord(1.0, 1.0);
// 左下角
glm::vec2 topLeftTexCoord(0.0f, 1.0);
// 左上角
glm::vec2 bottomLeftTexCoord(0.0, 0.0);

struct Context {
    float position[4];  // 位置
    float texCoord[2];  // 纹理坐标

    Context(glm::vec4 p, glm::vec2 c) {

        position[0] = p.x;
        position[1] = p.y;
        position[2] = p.z;
        position[3] = p.w;

        texCoord[0] = c.x;
        texCoord[1] = c.y;
    }

    void updatePosition(glm::vec4 v) {
        position[0] = v.x;
        position[1] = v.y;
        position[2] = v.z;
        position[3] = v.w;
    }
};

Buffer::Buffer(const glm::vec2 size)
    : m_size(size) {

    Context data[] = {
        Context(topRight, topRightTexCoord),
        Context(bottomRight, bottomRightTexCoord),
        Context(topLeft, topLeftTexCoord),
        Context(bottomLeft, bottomLeftTexCoord),
    };

    GLuint indices[] = {
        // 注意索引从0开始!
        0, 1, 3,  // 第一个三角形
        1, 2, 3,  // 第二个三角形
    };

    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW);

    glGenVertexArrays(1, &VAO);
    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (GLvoid *)0);
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (GLvoid *)(4 * sizeof(GLfloat)));
    glEnableVertexAttribArray(1);

    glGenBuffers(1, &EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // 加载图片纹理
    glGenTextures(1, &texture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    // 为当前绑定的纹理对象设置环绕、过滤方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    stbi_set_flip_vertically_on_load(true);
    const char *filename = "./Images/test.jpg";

    GLint width, height, nrChannels;
    GLubyte *img_data = stbi_load(filename, &width, &height, &nrChannels, 0);
    if (img_data) {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, img_data);
        glGenerateMipmap(GL_TEXTURE_2D);
    } else {
        std::cout << "Failed to load texture" << std::endl;
    }
    stbi_image_free(img_data);

    keyframes[0] = {0.f, -90.f};
    keyframes[1] = {5.f / 30.f, 25.f};
    keyframes[2] = {8.f / 30.f, -25.f};
    keyframes[3] = {10.f / 30.f, 15.f};
    keyframes[4] = {14.f / 30.f, -15.f};
    keyframes[5] = {18.f / 30.f, 0.f};
}

Buffer::~Buffer() {
    cout << this << " " << __FUNCTION__ << endl;
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glDeleteBuffers(1, &EBO);
    glDeleteTextures(1, &texture);
}

void Buffer::Draw(GLuint programId, float time) const {

    //    Context data[4] = {
    //        Context(topRight, topRightTexCoord),
    //        Context(bottomRight, bottomRightTexCoord),
    //        Context(topLeft, topLeftTexCoord),
    //        Context(bottomLeft, bottomLeftTexCoord),
    //    };

    glm::mat4 projectionMatrix = glm::frustum(-1.f, 1.f, -1.f, 1.f, 1.f, 1000.f);
    glm::vec3 eye              = glm::vec3(0.0f, 0.0f, 2.0f);
    glm::vec3 center           = glm::vec3(0.0f, 0.0f, 0.0f);
    glm::vec3 up               = glm::vec3(0.0f, 1.0f, 0.0f);
    glm::mat4 viewMatrix       = glm::lookAt(eye, center, up);
    // 单元矩阵
    glm::mat4 modelMatrix = glm::mat4(1);

    float degree = 0;
    for (int i = 0; i < keyframesCount - 1; i++) {
        float startTime = keyframes[i].time;
        float endTime   = keyframes[i + 1].time;
        if (i == 0 && time < startTime) {
            degree = keyframes[i].value;
            break;
        }

        if (i == (keyframesCount - 2) && time > endTime) {
            degree = keyframes[i + 1].value;
            break;
        }

        if (time >= startTime && time <= endTime) {
            float progress = (time - startTime) / (endTime - startTime);

            //            progress = elasticEaseInOut(progress);
            //            progress = bounceEaseOut(progress);
            float fromValue = keyframes[i].value;
            float toValue   = keyframes[i + 1].value;
            degree          = fromValue + progress * (toValue - fromValue);
            break;
        }
    }

    modelMatrix = glm::rotate(modelMatrix, glm::radians(-degree), glm::vec3(1.0, 0.0, 0.0));
    modelMatrix = glm::scale(modelMatrix, glm::vec3(2.0, 2.0, 0.0));

    glm::mat4 mvpMatrix = projectionMatrix * viewMatrix * modelMatrix;
    glUniformMatrix4fv(glGetUniformLocation(programId, "mvp"), 1, GL_FALSE, glm::value_ptr(mvpMatrix));

    //    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    //    glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW);
    //
    //    glBindVertexArray(VAO);
    //    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    //    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (GLvoid *)0);
    //    glEnableVertexAttribArray(0);
    //
    //    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (GLvoid *)(4 * sizeof(GLfloat)));
    //    glEnableVertexAttribArray(1);
    //
    //    GLuint indices[] = {
    //        // 注意索引从0开始!
    //        0, 1, 3,  // 第一个三角形
    //        1, 2, 3,  // 第二个三角形
    //    };
    //    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    //    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    glBindVertexArray(VAO);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
}

}  // namespace gl

