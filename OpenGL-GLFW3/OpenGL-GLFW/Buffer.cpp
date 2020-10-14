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

#include <GLKit/GLKMath.h>

namespace gl {

#if 1
// 右上角
glm::vec4 topRight(-0.1f, 0.8f, 0.0f, 1.0f);
// 右下角
glm::vec4 bottomRight(-0.1f, -0.5f, 0.0f, 1.0f);
// 左下角
glm::vec4 topLeft(-0.8f, 0.8f, 0.0f, 1.0f);
// 左上角
glm::vec4 bottomLeft(-0.8f, -0.5f, 0.0f, 1.0f);
#else
// 右上角
glm::vec4 topRight(0.5f, 0.5f, 0.0f, 1.0f);
// 右下角
glm::vec4 bottomRight(0.5f, -0.5f, 0.0f, 1.0f);
// 左下角
glm::vec4 topLeft(-0.5f, -0.5f, 0.0f, 1.0f);
// 左上角
glm::vec4 bottomLeft(-0.5f, 0.5f, 0.0f, 1.0f);
#endif

// 右上角
glm::vec3 topRightColor(1.0, 0.0, 0.0);
// 右下角
glm::vec3 bottomRightColor(0.0, 1.0, 0.0);
// 左下角
glm::vec3 topLeftColor(0.0f, 0.0f, 1.0f);
// 左上角
glm::vec3 bottomLeftColor(0.3, 0.5, 0.5);

struct Context {
	float position[4];  // 位置
	float color[3];     // 颜色

	Context(glm::vec4 p, glm::vec3 c) {

		position[0] = p.x;
		position[1] = p.y;
		position[2] = p.z;
		position[3] = p.w;

		color[0] = c.x;
		color[1] = c.y;
		color[2] = c.z;
	}

	void updatePosition(glm::vec4 v) {
		position[0] = v.x;
		position[1] = v.y;
		position[2] = v.z;
		position[3] = v.w;
	}
};

Buffer::Buffer() {

	/* clang-format off */
//    GLfloat vertices[] = {
//		// 右上角		  // 颜色
//		0.5f, 0.5f, 0.0f, 1.0, 0.0, 0.0,
//		// 右下角
//		0.5f, -0.5f, 0.0f, 0.0, 1.0, 0.0,
//		// 左下角
//		-0.5f, -0.5f, 0.0f, 0.0f, 0.0f, 1.0f,
//		// 左上角
//		-0.5f, 0.5f, 0.0f, 0.3, 0.5, 0.5,
//    };

//	GLfloat vertices[] = {
//		// 右上角		  // 颜色
//		-0.1f, 0.8f, 0.0f, 1.0, 0.0, 0.0,
//		// 右下角
//		-0.1f, -0.5f, 0.0f, 0.0, 1.0, 0.0,
//		// 左下角
//		-0.8f, -0.5f, 0.0f, 0.0f, 0.0f, 1.0f,
//		// 左上角
//		-0.8f, 0.8f, 0.0f, 0.3, 0.5, 0.5,
//	};

	Context data[] = {
		Context(topRight,topRightColor),
		Context(bottomRight,bottomRightColor),
		Context(topLeft,topLeftColor),
		Context(bottomLeft,bottomLeftColor),
	};

	GLuint indices[] = { // 注意索引从0开始!
		0, 1, 2, // 第一个三角形
		2, 1, 3  // 第二个三角形
	};
	/* clang-format on */

	glGenBuffers(1, &VBO);
	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW);

	glGenVertexArrays(1, &VAO);
	glBindVertexArray(VAO);
	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), (GLvoid *)0);
	glEnableVertexAttribArray(0);

	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), (GLvoid *)(4 * sizeof(GLfloat)));
	glEnableVertexAttribArray(1);

	glGenBuffers(1, &EBO);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
}

Buffer::~Buffer() {
	cout << this << " " << __FUNCTION__ << endl;
	glDeleteVertexArrays(1, &VAO);
	glDeleteBuffers(1, &VBO);
	glDeleteBuffers(1, &EBO);
}

void Buffer::Draw(GLuint programId, bool rotate) const {

	Context data[4] = {
	    Context(topRight, topRightColor),
	    Context(bottomRight, bottomRightColor),
	    Context(topLeft, topLeftColor),
	    Context(bottomLeft, bottomLeftColor),
	};

	if (rotate) {
		GLuint index = 3;
		GLKMatrix4 transformto   = GLKMatrix4MakeTranslation(-data[index].position[0], -data[index].position[1], 0);
		GLKMatrix4 rotate        = GLKMatrix4MakeZRotation(GLKMathDegreesToRadians(-15));
		GLKMatrix4 transformback = GLKMatrix4MakeTranslation(data[index].position[0], data[index].position[1], 0);

		rotate = GLKMatrix4Multiply(transformback, rotate);
		rotate = GLKMatrix4Multiply(rotate, transformto);

//		glUniformMatrix4fv(glGetUniformLocation(programId, "transformto"), 1, GL_FALSE, transformto.m);
		glUniformMatrix4fv(glGetUniformLocation(programId, "rotate"), 1, GL_FALSE, rotate.m);
//		glUniformMatrix4fv(glGetUniformLocation(programId, "transformback"), 1, GL_FALSE, transformback.m);
		glUniform1i(glGetUniformLocation(programId, "transformed"), true);
	} else {

		glUniform1i(glGetUniformLocation(programId, "transformed"), false);
	}

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW);

	glBindVertexArray(VAO);
	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), (GLvoid *)0);
	glEnableVertexAttribArray(0);

	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), (GLvoid *)(4 * sizeof(GLfloat)));
	glEnableVertexAttribArray(1);

	/* clang-format off */
	GLuint indices[] = { // 注意索引从0开始!
		0, 1, 2, // 第一个三角形
		2, 1, 3  // 第二个三角形
	};
	/* clang-format on */
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

	glBindVertexArray(VAO);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
	glBindVertexArray(0);
}

}  // namespace gl

