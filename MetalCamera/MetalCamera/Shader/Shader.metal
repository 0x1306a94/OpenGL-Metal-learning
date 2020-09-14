//
//  Shader.metal
//  MetalCamera
//
//  Created by king on 2020/9/11.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#include <metal_stdlib>
#import "ShaderTypes.h"

using namespace metal;

typedef struct {
    float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
    float2 textureCoordinate; // 纹理坐标，会做插值处理

} RasterizerData;

vertex RasterizerData // 返回给片元着色器的结构体
vertexShader(uint vertexID [[ vertex_id ]], // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
             constant SSVertex *vertexArray [[ buffer(SSVertexInputIndexVertices) ]]) { // buffer表明是缓存数据，0是索引
    RasterizerData out;
    out.clipSpacePosition = vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

constant float3 greenMaskColor = float3(0.0, 1.0, 0.0); // 过滤掉绿色的

fragment float4
samplingShader(RasterizerData input [[stage_in]], // stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
               texture2d<float> greenTextureY [[ texture(SSFragmentTextureIndexGreenTextureY) ]], // texture表明是纹理数据，SSFragmentTextureIndexGreenTextureY是索引
               texture2d<float> greenTextureUV [[ texture(SSFragmentTextureIndexGreenTextureUV) ]], // texture表明是纹理数据，SSFragmentTextureIndexGreenTextureUV是索引
               texture2d<float> normalTextureY [[ texture(SSFragmentTextureIndexNormalTextureY) ]], // texture表明是纹理数据，SSFragmentTextureIndexNormalTextureY是索引
               texture2d<float> normalTextureUV [[ texture(SSFragmentTextureIndexNormalTextureUV) ]], // texture表明是纹理数据，SSFragmentTextureIndexNormalTextureUV是索引
               constant SSConvertMatrix *convertMatrix [[ buffer(SSFragmentInputIndexMatrix) ]]) //buffer表明是缓存数据，SSFragmentInputIndexMatrix是索引
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear); // sampler是采样器

    /*
     From RGB to YUV
     Y = 0.299R + 0.587G + 0.114B
     U = 0.492 (B-Y)
     V = 0.877 (R-Y)

     上面是601

     下面是601-fullrange
     */
    float maskY = 0.257 * greenMaskColor.r + 0.504 * greenMaskColor.g + 0.098 * greenMaskColor.b;
    float maskU = -0.148 * greenMaskColor.r - 0.291 * greenMaskColor.g + 0.439 * greenMaskColor.b;
    float maskV = 0.439 * greenMaskColor.r - 0.368 * greenMaskColor.g - 0.071 * greenMaskColor.b;
    float3 maskYUV = float3(maskY, maskU, maskV) + float3(16.0 / 255.0, 0.5, 0.5);
    // 绿幕视频读取出来的图像，yuv颜色空间
    float3 greenVideoYUV = float3(greenTextureY.sample(textureSampler, input.textureCoordinate).r,
                              greenTextureUV.sample(textureSampler, input.textureCoordinate).rg);
    // yuv转成rgb
    float3 greenVideoRGB = convertMatrix->matrix * (greenVideoYUV + convertMatrix->offset);
    // 正常视频读取出来的图像，yuv颜色空间
    float3 normalVideoYUV = float3(normalTextureY.sample(textureSampler, input.textureCoordinate).r,
                             normalTextureUV.sample(textureSampler, input.textureCoordinate).rg);
    // yuv转成rgb
    float3 normalVideoRGB = convertMatrix->matrix * (normalVideoYUV + convertMatrix->offset);
    // 计算需要替换的值
    float blendValue = smoothstep(0.1, 0.3, distance(maskYUV.yz, greenVideoYUV.yz));
    // 混合两个图像
    return float4(mix(normalVideoRGB, greenVideoRGB, blendValue), 1.0); // blendValue=0，表示接近绿色，取normalColor；
}

// GPUImage3 https://github.com/BradLarson/GPUImage3/blob/master/framework/Source/Operations/ColorBurnBlend.metal
fragment half4
chromaKeyBlendFragment(RasterizerData input [[stage_in]],
			   texture2d<half> greenTexture [[ texture(SSFragmentTextureIndexGreenTextureRGBA) ]],
				texture2d<half> normalTexture [[ texture(SSFragmentTextureIndexNormalTextureRGBA) ]]) {


	const float thresholdSensitivity = 0.4;
	const float smoothing = 0.1;

	constexpr sampler quadSampler;
	half4 textureColor = greenTexture.sample(quadSampler, input.textureCoordinate);
	half4 textureColor2 = normalTexture.sample(quadSampler, input.textureCoordinate);

	half maskY = 0.2989h * greenMaskColor.r + 0.5866h * greenMaskColor.g + 0.1145h * greenMaskColor.b;
	half maskCr = 0.7132h * (greenMaskColor.r - maskY);
	half maskCb = 0.5647h * (greenMaskColor.b - maskY);

	half Y = 0.2989h * textureColor.r + 0.5866h * textureColor.g + 0.1145h * textureColor.b;
	half Cr = 0.7132h * (textureColor.r - Y);
	half Cb = 0.5647h * (textureColor.b - Y);

	float blendValue = 1.0 - smoothstep(thresholdSensitivity, thresholdSensitivity + smoothing, distance(float2(Cr, Cb), float2(maskCr, maskCb)));
	return half4(mix(textureColor, textureColor2, half(blendValue)));
}

fragment float4
normalSamplingShader(RasterizerData input [[stage_in]], // stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
               texture2d<float> normalTextureY [[ texture(SSFragmentTextureIndexNormalTextureY) ]],
               texture2d<float> normalTextureUV [[ texture(SSFragmentTextureIndexNormalTextureUV) ]],
               constant SSConvertMatrix *convertMatrix [[ buffer(SSFragmentInputIndexMatrix) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);



    // 正常视频读取出来的图像，yuv颜色空间
    float3 normalVideoYUV = float3(normalTextureY.sample(textureSampler, input.textureCoordinate).r,
                             normalTextureUV.sample(textureSampler, input.textureCoordinate).rg);
    // yuv转成rgb
    float3 normalVideoRGB = convertMatrix->matrix * (normalVideoYUV + convertMatrix->offset);
	return float4(normalVideoRGB, 1.0);
}
