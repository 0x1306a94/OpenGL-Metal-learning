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

namespace gl {

class Shader;
class Buffer;

class Program {

  public:
	Program(Shader *&shader, Buffer *&buffer);
	~Program();

	void Use();
	void Draw();

  private:
	GLuint program;
	Shader *&shader;
	Buffer *&buffer;
};
}  // namespace gl

#endif /* Program_hpp */

