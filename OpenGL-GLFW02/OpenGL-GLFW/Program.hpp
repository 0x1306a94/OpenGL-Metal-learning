//
//  Program.hpp
//  OpenGL-GLFW
//
//  Created by king on 2020/9/2.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#ifndef Program_hpp
#define Program_hpp

#include <GL/glew.h>
#include <memory>

namespace gl {

class Shader;
class Buffer;

class Program {

  public:
	Program(std::shared_ptr<Shader> shader, std::shared_ptr<Buffer> buffer);
	~Program();

	void Use();
	void Draw();
	GLuint getID() const { return this->program; }

  private:
	GLuint program;
	std::shared_ptr<Shader> shader;
	std::shared_ptr<Buffer> buffer;
};
}  // namespace gl

#endif /* Program_hpp */

