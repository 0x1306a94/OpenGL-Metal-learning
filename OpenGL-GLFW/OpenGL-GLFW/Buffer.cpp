//
//  Buffer.cpp
//  OpenGL-GLFW
//
//  Created by king on 2020/9/2.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#include "Buffer.hpp"

namespace gl {
Buffer::Buffer() {

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
}

Buffer::~Buffer() {
	cout << this << " " <<__FUNCTION__<< endl;
	glDeleteVertexArrays(1, &VAO);
	glDeleteBuffers(1, &VBO);
	glDeleteBuffers(1, &EBO);
}

void Buffer::Draw() const {
	glBindVertexArray(VAO);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
	glBindVertexArray(0);
}

}  // namespace gl

