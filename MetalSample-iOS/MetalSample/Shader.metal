//
//  Shader.metal
//  MetalSample
//
//  Created by king on 2020/10/19.
//

#include <metal_stdlib>
#include "SSShaderTypes.h"
using namespace metal;

typedef struct {
	float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
	float4 color;
} RasterizerData;

vertex RasterizerData // 返回给片元着色器的结构体
vertex_main(uint vid [[ vertex_id ]], // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
			 constant SSVertex *vertexArray [[ buffer(SSVertexInputIndexVertexs) ]], // buffer表明是缓存数据，SSVertexInputIndexVertexs是索引
			constant SSUniform & uniforms [[ buffer(SSVertexInputIndexUniforms) ]]) { // buffer表明是缓存数据，SSVertexInputIndexUniforms是索引
	RasterizerData out;
	if (uniforms.transformed) {
		out.clipSpacePosition = uniforms.transform * vertexArray[vid].position;
	} else {
		out.clipSpacePosition = vertexArray[vid].position;
	}
	out.color = vertexArray[vid].color;
	return out;
}

fragment float4 //
fragment_main(RasterizerData input [[stage_in]]) {
	return input.color;
}
