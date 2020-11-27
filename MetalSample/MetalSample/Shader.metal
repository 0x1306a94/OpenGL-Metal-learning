//
//  Shader.metal
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

typedef float4 vec4;
typedef float3 vec3;
typedef float2 vec2;

typedef struct {
	float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
	float2 textureCoordinate;
} RasterizerData;

vec4 texture2D(texture2d<float> texture, vec2 uv) {
	constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
	return texture.sample(textureSampler, uv);
}

vertex RasterizerData
vertex_main(uint vertexID [[ vertex_id ]],
			constant SSVertex *vertexArray [[ buffer(SSVertexInputIndexVertices) ]],
			constant SSUniform & uniforms [[ buffer(SSVertexInputIndexUniforms) ]]) {
	RasterizerData out;
	out.clipSpacePosition = uniforms.projection * uniforms.model * vertexArray[vertexID].position;
	out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
	return out;
}

fragment float4
fragment_main(RasterizerData input [[stage_in]],
			  constant float2 & size [[ buffer(0) ]],
			  constant int & antiAliasing [[ buffer(1) ]],
			  texture2d<float> texture [[ texture(SSFragmentTextureIndexOne) ]]) {

	if (antiAliasing == 0) {
		return texture2D(texture, input.textureCoordinate);
	}

	vec2 texCoords = input.textureCoordinate;
	vec2 u_texelStep = vec2(1.0/size.x, 1.0/size.y);
	float u_lumaThreshold = 0.5;
	float u_mulReduce = 1.0/8.0;
	float u_minReduce = 1.0/128.0;
	float u_maxSpan = 8.0;
	vec3 rgbNW = texture2D(texture,texCoords+(vec2(-1.0,1.0))).xyz;
	vec3 rgbNE = texture2D(texture,texCoords+(vec2(1.0,1.0))).xyz;
	vec3 rgbSW = texture2D(texture,texCoords+(vec2(-1.0,-1.0))).xyz;
	vec3 rgbSE = texture2D(texture,texCoords+(vec2(1.0,-1.0))).xyz;
	vec4 rgbM = texture2D(texture,texCoords);

	// see http://en.wikipedia.org/wiki/Grayscale
	const vec3 toLuma = vec3(0.299, 0.587, 0.114);

	// Convert from RGB to luma.
	float lumaNW = dot(rgbNW, toLuma);
	float lumaNE = dot(rgbNE, toLuma);
	float lumaSW = dot(rgbSW, toLuma);
	float lumaSE = dot(rgbSE, toLuma);
	float lumaM = dot(rgbM.xyz, toLuma);

	// Gather minimum and maximum luma.
	float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
	float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

	// If contrast is lower than a maximum threshold ...
	if (lumaMax - lumaMin <= lumaMax * u_lumaThreshold) {
		return rgbM;
	}

	// Sampling is done along the gradient.
	vec2 samplingDirection;
	samplingDirection.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
	samplingDirection.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

	// Sampling step distance depends on the luma: The brighter the sampled texels, the smaller the final sampling step direction.
	// This results, that brighter areas are less blurred/more sharper than dark areas.
	float samplingDirectionReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * 0.25 * u_mulReduce, u_minReduce);

	// Factor for norming the sampling direction plus adding the brightness influence.
	float minSamplingDirectionFactor = 1.0 / (min(abs(samplingDirection.x), abs(samplingDirection.y)) + samplingDirectionReduce);

	// Calculate final sampling direction vector by reducing, clamping to a range and finally adapting to the texture size.
	samplingDirection = clamp(samplingDirection * minSamplingDirectionFactor, vec2(-u_maxSpan), vec2(u_maxSpan)) * u_texelStep;

	// Inner samples on the tab.
	vec3 rgbSampleNeg = texture2D(texture,texCoords + samplingDirection * (1.0/3.0 - 0.5)).rgb;
	vec3 rgbSamplePos = texture2D(texture,texCoords + samplingDirection * (2.0/3.0 - 0.5)).rgb;

	vec3 rgbTwoTab = (rgbSamplePos + rgbSampleNeg) * 0.5;

	// Outer samples on the tab.
	vec3 rgbSampleNegOuter = texture2D(texture,texCoords + samplingDirection * (0.0/3.0 - 0.5)).rgb;
	vec3 rgbSamplePosOuter = texture2D(texture,texCoords + samplingDirection * (3.0/3.0 - 0.5)).rgb;

	vec3 rgbFourTab = (rgbSamplePosOuter + rgbSampleNegOuter) * 0.25 + rgbTwoTab * 0.5;

	// Calculate luma for checking against the minimum and maximum value.
	float lumaFourTab = dot(rgbFourTab, toLuma);

	vec4 color = rgbM;
	// Are outer samples of the tab beyond the edge ...
	if (lumaFourTab < lumaMin || lumaFourTab > lumaMax) {
		// ... yes, so use only two samples.
		color = vec4(rgbTwoTab, 1.0);
	} else {
		// ... no, so use four samples.
		color = vec4(rgbFourTab, 1.0);
	}

	return color;
}
