//
//  EarthShaders.metal
//  lvji
//
//  Created on 2025/5/8.
//

#include <metal_stdlib>
using namespace metal;

// 顶点着色器输入
struct VertexInput {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoord [[attribute(2)]];
};

// 顶点着色器输出/片元着色器输入
struct VertexOutput {
    float4 position [[position]];
    float2 texCoord;
    float3 worldPosition;
    float3 worldNormal;
    float3 viewDirection;
};

// 着色器统一变量
struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float3 cameraPosition;
    float time;
    float elevationScale;    // 高程缩放系数
    float atmosphereDensity; // 大气密度
    float detailLevel;       // 细节等级
};

// 顶点着色器 - 支持地形变形
vertex VertexOutput earthVertexShader(VertexInput in [[stage_in]],
                                    constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOutput out;
    
    // 计算变形后的顶点位置
    float3 position = in.position;
    
    // 使用纹理坐标计算高度变形参数 - 基于噪声
    float elevation = 0.0;
    
    // 山脉变形 - 使用简单噪声模拟山峰
    // 注意：实际应用中应当从高度图采样
    float2 noiseCoord = in.texCoord * 4.0; // 缩放坐标以增加变化
    float noise1 = sin(noiseCoord.x * 12.0) * cos(noiseCoord.y * 8.0) * 0.5 + 0.5;
    float noise2 = sin(noiseCoord.x * 5.0 + noiseCoord.y * 7.0) * 0.5 + 0.5;
    float combinedNoise = mix(noise1, noise2, 0.5);
    
    // 仅对陆地区域应用高程变形（简化逻辑示例）
    // 实际应用中应通过采样陆地/海洋掩码纹理确定
    if (combinedNoise > 0.75) {
        elevation = (combinedNoise - 0.75) * 4.0 * 0.05 * uniforms.elevationScale;
    }
    
    // 应用高程变形
    float3 direction = normalize(position);
    position = position + direction * elevation;
    
    // 标准变换管线
    float4 worldPosition = uniforms.modelMatrix * float4(position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * worldPosition;
    
    // 计算世界空间法线
    float3x3 normalMatrix = float3x3(uniforms.modelMatrix[0].xyz, 
                                    uniforms.modelMatrix[1].xyz, 
                                    uniforms.modelMatrix[2].xyz);
    out.worldNormal = normalize(normalMatrix * in.normal);
    
    // 传递纹理坐标
    out.texCoord = in.texCoord;
    
    // 世界空间位置用于光照计算
    out.worldPosition = worldPosition.xyz;
    
    // 计算视线方向用于反射和菲涅尔效应
    out.viewDirection = normalize(uniforms.cameraPosition - worldPosition.xyz);
    
    return out;
}

// 大气散射参数
constant float3 rayleighCoefficient = float3(5.8e-6, 13.5e-6, 33.1e-6); // 分子散射系数
constant float mieCoefficient = 21e-6;                                    // 米氏散射系数
constant float3 sunLight = float3(1.0, 0.95, 0.9) * 20.0;                // 阳光颜色和强度

// 计算大气散射
float3 computeAtmosphericScattering(float3 rayDirection, float3 sunDirection, float atmosphereDensity) {
    float sunE = saturate(dot(sunDirection, rayDirection));
    float rayleighCoeff = rayleighCoefficient.y * atmosphereDensity; // 使用绿色通道系数，重命名局部变量
    
    // 日出/日落效果
    float3 betaR = rayleighCoeff * float3(1.0, 1.0, 1.0) * 0.0001;
    
    // 米氏散射
    float mie = mieCoefficient * atmosphereDensity;
    float3 betaM = float3(mie, mie, mie) * 0.00001;
    
    // 光学深度
    float zenithAngle = acos(saturate(dot(float3(0.0, 1.0, 0.0), rayDirection)));
    float rayleighDepth = rayleighCoeff / cos(zenithAngle);
    float mieDepth = mieCoefficient / cos(zenithAngle);
    
    // 散射累积
    float3 Fex = exp(-(betaR * rayleighDepth + betaM * mieDepth));
    
    // 米氏散射相位函数
    float g = 0.9;  // 散射不对称因子
    float g2 = g * g;
    float theta = acos(sunE);
    float cos2Theta = cos(theta) * cos(theta);
    float miePhase = 1.5 * ((1.0 - g2) / (2.0 + g2)) * (1.0 + cos2Theta) / pow(1.0 + g2 - 2.0 * g * cos(theta), 1.5);
    
    // 光路积分 - 简化版
    float3 Lin = sunLight * ((1.0 - Fex) * (0.5 + miePhase));
    
    // 添加夜晚模拟 - 简单星光
    float nightSkyFactor = 1.0 - saturate(sunDirection.y + 0.4);
    float3 nightSky = float3(0.05, 0.05, 0.1) * nightSkyFactor;
    
    // 混合日夜大气效果
    float3 atmosphere = Lin + nightSky;
    
    return atmosphere;
}

// 片元着色器 - 渲染地球表面
fragment float4 earthFragmentShader(VertexOutput in [[stage_in]], 
                                  texture2d<float> diffuseTexture [[texture(0)]],
                                  texture2d<float> normalMap [[texture(1)]],
                                  texture2d<float> specularMap [[texture(2)]],
                                  texture2d<float> nightTexture [[texture(3)]],
                                  constant Uniforms &uniforms [[buffer(1)]]) {
    constexpr sampler textureSampler(filter::linear, address::repeat);
    
    // 基础地球颜色
    float4 diffuseColor = diffuseTexture.sample(textureSampler, in.texCoord);
    
    // 法线贴图
    float3 normalMapValue = normalMap.sample(textureSampler, in.texCoord).rgb * 2.0 - 1.0;
    
    // 构建TBN矩阵（切线空间到世界空间）- 简化版本
    float3 N = normalize(in.worldNormal);
    float3 T = normalize(cross(N, float3(0.0, 1.0, 0.0)));
    float3 B = normalize(cross(N, T));
    float3x3 TBN = float3x3(T, B, N);
    
    // 应用法线贴图
    float3 normal = normalize(TBN * normalMapValue);
    
    // 光照参数
    float3 sunDirection = normalize(float3(sin(uniforms.time * 0.05), 0.2, cos(uniforms.time * 0.05)));
    float3 viewDirection = normalize(in.viewDirection);
    
    // 环境光
    float3 ambient = float3(0.05, 0.05, 0.1);
    
    // 漫反射 - 朗伯照明
    float diffuseFactor = max(dot(normal, sunDirection), 0.0);
    float3 diffuse = diffuseColor.rgb * sunLight * diffuseFactor;
    
    // 高光反射 - Blinn-Phong模型
    float specularStrength = specularMap.sample(textureSampler, in.texCoord).r;
    float3 halfVector = normalize(sunDirection + viewDirection);
    float specularFactor = pow(max(dot(normal, halfVector), 0.0), 32.0) * specularStrength;
    float3 specular = sunLight * specularFactor * float3(1.0, 0.97, 0.85);
    
    // 菲涅尔效应 - 边缘增强
    float fresnel = pow(1.0 - max(dot(normal, viewDirection), 0.0), 5.0);
    float3 fresnelColor = mix(float3(0.1, 0.1, 0.3), float3(0.2, 0.5, 1.0), fresnel);
    
    // 夜晚灯光 - 地球黑暗面
    float nightFactor = 1.0 - saturate(diffuseFactor + 0.1);
    float3 nightColor = nightTexture.sample(textureSampler, in.texCoord).rgb * nightFactor * 2.0;
    
    // 大气散射
    float3 atmosphere = computeAtmosphericScattering(viewDirection, sunDirection, uniforms.atmosphereDensity);
    
    // 距离地球边缘的因子用于大气效果
    float rimFactor = 1.0 - max(dot(normal, viewDirection), 0.0);
    float atmosphereFactor = pow(rimFactor, 2.0) * uniforms.atmosphereDensity;
    
    // 组合所有光照组件
    float3 finalColor = ambient + diffuse + specular + nightColor + atmosphere * atmosphereFactor + fresnelColor * fresnel;
    
    // 色调映射和伽马校正
    finalColor = finalColor / (finalColor + float3(1.0));
    finalColor = pow(finalColor, float3(1.0/2.2)); // 伽马校正
    
    return float4(finalColor, diffuseColor.a);
}

// 备用着色器 - 当主着色器不可用时使用
vertex VertexOutput earthVertexShaderFallback(VertexInput in [[stage_in]],
                                           constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOutput out;
    
    // 标准变换管线，无地形变形
    float4 worldPosition = uniforms.modelMatrix * float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * worldPosition;
    
    // 计算世界空间法线
    float3x3 normalMatrix = float3x3(uniforms.modelMatrix[0].xyz, 
                                    uniforms.modelMatrix[1].xyz, 
                                    uniforms.modelMatrix[2].xyz);
    out.worldNormal = normalize(normalMatrix * in.normal);
    
    // 传递纹理坐标
    out.texCoord = in.texCoord;
    
    // 世界空间位置用于光照计算
    out.worldPosition = worldPosition.xyz;
    
    // 计算视线方向用于反射和菲涅尔效应
    out.viewDirection = normalize(uniforms.cameraPosition - worldPosition.xyz);
    
    return out;
}

// 备用片元着色器 - 简化版地球渲染
fragment float4 earthFragmentShaderFallback(VertexOutput in [[stage_in]], 
                                         texture2d<float> diffuseTexture [[texture(0)]],
                                         constant Uniforms &uniforms [[buffer(1)]]) {
    constexpr sampler textureSampler(filter::linear, address::repeat);
    
    // 基础地球颜色
    float4 diffuseColor = diffuseTexture.sample(textureSampler, in.texCoord);
    
    // 使用原生法线
    float3 normal = normalize(in.worldNormal);
    
    // 光照参数
    float3 sunDirection = normalize(float3(0.5, 0.2, 0.8));
    float3 viewDirection = normalize(in.viewDirection);
    
    // 环境光
    float3 ambient = float3(0.1, 0.1, 0.15);
    
    // 漫反射
    float diffuseFactor = max(dot(normal, sunDirection), 0.0);
    float3 diffuse = diffuseColor.rgb * float3(1.0, 0.95, 0.9) * diffuseFactor;
    
    // 高光反射
    float3 halfVector = normalize(sunDirection + viewDirection);
    float specularFactor = pow(max(dot(normal, halfVector), 0.0), 16.0) * 0.3;
    float3 specular = float3(1.0, 0.97, 0.85) * specularFactor;
    
    // 边缘增强
    float rimFactor = 1.0 - max(dot(normal, viewDirection), 0.0);
    float3 rim = float3(0.1, 0.3, 0.6) * pow(rimFactor, 3.0);
    
    // 组合所有光照组件
    float3 finalColor = ambient + diffuse + specular + rim;
    
    // 简单色调映射
    finalColor = finalColor / (finalColor + float3(1.0));
    
    return float4(finalColor, diffuseColor.a);
} 