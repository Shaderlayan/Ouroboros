struct CompositeShaderHelper
{
    float3 viewPosition;
    float2 screenSpaceTexCoord;

    float normalWeightSq;
    float3 normal;
    float shininess;

    float3 incident;
    float3 reflection;
    float3 reflectionColor;
    float3 lightAmbient;
    float3 lightReflection;

    float occlusionValue;

    float3 lightDiffuseS;

    float3 lightDiffuseValue;
    float3 lightSpecularValue;

    float3 diffuseColor;
    float3 fresnelValue0;
    float3 emissiveColor;
    float specularMask;
    float alpha;

    bool AlphaTest()
    {
#ifdef PASS_COMPOSITE
        return alpha >= g_AlphaThreshold;
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
        return alpha < g_AlphaThreshold && alpha >= 0.01;
#endif
    }

    void DivideAlpha()
    {
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
        if (g_AlphaThreshold > 0) {
            alpha /= g_AlphaThreshold;
        }
#endif
    }

    void CalculateScreenSpaceTexCoord(float2 position)
    {
        screenSpaceTexCoord = g_CommonParameter.m_RenderTarget.zw + position * g_CommonParameter.m_RenderTarget.xy;
    }

    void SampleGBuffer()
    {
        const float4 gBufferS = g_SamplerGBuffer.Sample(screenSpaceTexCoord);
        const float3 halfWeightedNormal = gBufferS.xyz - 0.5;
        normalWeightSq = dot(halfWeightedNormal, halfWeightedNormal);
        normal = halfWeightedNormal * rsqrt(normalWeightSq);
        shininess = log2(clamp(gBufferS.w, 0.002, 0.99)) * -15;
    }

    void SampleLightDiffuse()
    {
        lightDiffuseS = g_SamplerLightDiffuse.SampleLevel(screenSpaceTexCoord, 0).xyz;
    }

    void MultisampleLightDiffuse()
    {
        if (normalWeightSq < 0.15) {
            const float neighborSSUVDelta = 0.0025 / viewPosition.z;
            float3 lightDiffuseAcc = float3(0, 0, 0);
            float weightAcc = 0.0001;
            for (int i = -2; i <= 2; ++i) {
                for (int j = -2; j <= 2; ++j) {
                    const float2 nSSUV = screenSpaceTexCoord + float2(i, j) * neighborSSUVDelta;
                    const float3 nHWN = g_SamplerGBuffer.SampleLevel(nSSUV, 0).xyz - 0.5;
                    const float nNWSq = dot(nHWN, nHWN);
                    if (nNWSq < 0.15) {
                        const float3 nViewPosS = g_SamplerViewPosition.SampleLevel(nSSUV, 0).xyz;
                        const float3 nViewPosDelta = nViewPosS - viewPosition;
                        const float nViewPosDistance = length(nViewPosDelta);
                        const float3 nNormal = nHWN * rsqrt(nNWSq);
                        const float normalAlignment = saturate(dot(normal, nNormal));
                        const float distanceDivisor = 0.0001 + nViewPosDistance * 1000.0;
                        const float nWeight = pow(normalAlignment, 100) * min(1, 1 / distanceDivisor);
                        const float3 nLightDiffuseS = g_SamplerLightDiffuse.SampleLevel(nSSUV, 0).xyz;
                        lightDiffuseAcc += nLightDiffuseS * nWeight;
                        weightAcc += nWeight;
                    }
                }
            }
            lightDiffuseS = lightDiffuseAcc / weightAcc;
        } else {
            lightDiffuseS = g_SamplerLightDiffuse.SampleLevel(screenSpaceTexCoord, 0).xyz;
        }
    }

    void SampleReflection()
    {
        incident = normalize(viewPosition);
        reflection = reflect(incident, normal);
        const float3 texCoord = normalize(mul(g_CameraParameter.m_InverseViewMatrix, float4(reflection, 0)));
        const float level = 1 + (7 - log2(shininess)) * 0.75;
        const float rSample = g_SamplerReflection.SampleLevel(texCoord, level).x;
        const float rValue = g_AmbientParam[5].y + 2 * g_AmbientParam[5].x * rSample;
        reflectionColor = rValue * ambientColor(reflection);
    }

    void CalculateLightAmbientReflection()
    {
        const float viewZ2 = g_AmbientParam[4].y + g_AmbientParam[4].x * viewPosition.z;
        const float viewZ2Sq = clamp(abs(viewZ2) * viewZ2, g_AmbientParam[4].z, 1);
        const float3 rawLightAmbient = viewZ2Sq * ambientColor(normal);
        lightAmbient = rawLightAmbient * occlusionValue;
#ifdef SHPK_IRIS
        const float lightValue = 0.25;
#else
        const float lightLuminance = luminance(rawLightAmbient * rawLightAmbient + lightDiffuseS);
        const float lightValue = saturate(g_CommonParameter.m_Misc.w + g_CommonParameter.m_Misc.z * lightLuminance);
#endif
        lightReflection = reflectionColor * lightValue * occlusionValue;
    }

    void ApplyFresnelValue0Directionality()
    {
        const float directionality = 1 - min(1, abs(dot(incident, normal)));
        const float directionalitySq = directionality * directionality;
        fresnelValue0 = lerp(fresnelValue0, 1, directionalitySq * directionalitySq);
    }

    void CalculateLightDiffuseSpecular()
    {
#ifdef SHPK_CHARACTER
        const float2 cameraDiffSpec = g_InstanceParameter.m_CameraLight.m_DiffuseSpecular.xy;
#else
        const float2 cameraDiffSpec = g_InstanceParameter.m_CameraLight.m_DiffuseSpecular.zw;
#endif

        const float finalOcclusionValue = lerp(occlusionValue, 1, g_SceneParameter.m_OcclusionIntensity.w * OCCLUSION_FACTOR);
        const float2 diffSpecOcclusion = POW(finalOcclusionValue, g_SceneParameter.m_OcclusionIntensity.xy);
        const float3 direction = normalize(float3(0, -0.2, 0) - viewPosition);
#if defined(SHPK_HAIR) || defined(SHPK_CHARACTER)
        const float diffDirFactor = saturate(dot(normal, direction));
#else
        const float diffDirBase = saturate(dot(normal, direction) * 0.5 + 0.3);
        const float diffDirFactor = 0.36 + diffDirBase * diffDirBase;
#endif
        lightDiffuseValue = cameraDiffSpec.x * diffDirFactor
            + lightDiffuseS * diffSpecOcclusion.x
            + lightAmbient;

        const float specDirFactor = saturate(dot(reflection, direction));
        const float3 rimDirection = normalize(float3(g_InstanceParameter.m_CameraLight.m_Rim.y, 0, 0) - incident);
        const float rimAttenuation = 1 - saturate(dot(normal, rimDirection));
        const float rimAttenuation3 = rimAttenuation * rimAttenuation * rimAttenuation;
        const float fresnelValue0Gray = (fresnelValue0.x + fresnelValue0.y + fresnelValue0.z) / 3;
        const float fresnelValue0GraySq = fresnelValue0Gray * fresnelValue0Gray;

        lightSpecularValue = cameraDiffSpec.y * pow(specDirFactor, shininess)
            + g_SamplerLightSpecular.Sample(screenSpaceTexCoord).xyz * diffSpecOcclusion.y
            + g_InstanceParameter.m_CameraLight.m_Rim.z * rimAttenuation3;
#ifdef SHPK_HAIR
        if (g_UNK_15B70E35 > 0) {
            const float glossPosition = g_UNK_15B70E35 + dot(reflection, g_LightDirection.xyz);
            const float glossSpecFactor = saturate(glossPosition + min(0, 1 - glossPosition) * 2);
            lightSpecularValue *= pow(glossSpecFactor, shininess);
        }
#endif
        lightSpecularValue += lightReflection * fresnelValue0GraySq;
    }

    void ApplyWetness(float wetness)
    {
        const float2 wetSpecDiff = lerp(1, g_SceneParameter.m_Wetness.xw, wetness);
        const float brightness = dot(fresnelValue0, fresnelValue0) / (dot(fresnelValue0, 1) + 0.001);
        fresnelValue0 = lerp(fresnelValue0, g_SceneParameter.m_Wetness.z, wetness / (1 + 4 * brightness * brightness));
        shininess = lerp(shininess, g_SceneParameter.m_Wetness.y, wetness);
        specularMask *= wetSpecDiff.x;
        diffuseColor *= wetSpecDiff.y;
    }

    float SampleOcclusion()
    {
#ifdef PASS_COMPOSITE
        const float3 occlusionS = g_SamplerOcclusion.Sample(screenSpaceTexCoord).xyz;
        return lerp(1 - occlusionS.y - occlusionS.z * g_AmbientOcclusionMask, occlusionS.x, g_SceneParameter.m_OcclusionIntensity.w);
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
        return 1;
#endif
    }

    void OccludeDiffuse()
    {
        if (g_SceneParameter.m_OcclusionIntensity.w > 0) {
            const float lum = saturate(0.5 + 0.5 * luminance(diffuseColor));
            const float3 saturatedDiffuse = saturate(diffuseColor);
            diffuseColor += pow(saturatedDiffuse, lerp(1, occlusionValue, -0.25 * lum)) - saturatedDiffuse;
        }
    }

    float4 Finish()
    {
#ifndef SHPK_IRIS
        specularMask = saturate(specularMask);
#endif
        const float3 specularComponent = specularMask * fresnelValue0 * lightSpecularValue;
        const float3 finalSq = diffuseColor * lightDiffuseValue + specularComponent + emissiveColor;
        const float3 rgb = g_CommonParameter.m_Misc2.x * sqrt(max(0, finalSq * g_InstanceParameter.m_MulColor.xyz));

#ifdef PASS_COMPOSITE
        const float3 bloomNumSq = g_CommonParameter.m_Misc.x * specularComponent + g_InstanceParameter.m_EnvParameter.w * emissiveColor;
        const float4 bmMax1 = max(float4(bloomNumSq.xy, finalSq.xy), float4(bloomNumSq.z, 0, finalSq.z, 0.001));
        const float2 bmMax2 = max(bmMax1.xz, bmMax1.yw);
        const float bloom = bmMax2.x / bmMax2.y;

        return float4(rgb, bloom);
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
        return float4(rgb, alpha);
#endif
    }
};
