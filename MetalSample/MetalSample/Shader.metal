//
//  Shader.metal
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;


typedef struct {
	float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
	float2 textureCoordinate; // 纹理坐标，会做插值处理

} RasterizerData;


vertex RasterizerData // 返回给片元着色器的结构体
vertex_main(uint vertexID [[ vertex_id ]], // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
			 constant SSVertex *vertexArray [[ buffer(SSVertexInputIndexVertices) ]],
			constant SSUniform & uniforms [[ buffer(SSVertexInputIndexUniforms) ]]) { // buffer表明是缓存数据，0是索引
	RasterizerData out;
	if (uniforms.transformed) {
		out.clipSpacePosition = uniforms.transform2 * uniforms.transform * vertexArray[vertexID].position;
//        out.clipSpacePosition = uniforms.transform * vertexArray[vertexID].position;
	} else {
		out.clipSpacePosition = vertexArray[vertexID].position;
	}
	out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
	return out;
}


fragment half4 //
fragment_main(RasterizerData input [[stage_in]],
			  texture2d<half> texture [[ texture(SSFragmentTextureIndexOne) ]]) {

	constexpr sampler textureSampler (mag_filter::linear,
									  min_filter::linear); // sampler是采样器

	half4 textureColor = texture.sample(textureSampler, input.textureCoordinate);
	return textureColor;
}
