#include <structs.hlsl>
#include <resources.hlsl>
#include <functions.hlsl>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = SAMPLE(g_SamplerDither, 0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

    const float normalSZ = SAMPLE(g_SamplerNormal, ps.texCoord2.xy).z;
    const float sAA78 = ps.color.w * normalSZ;
#ifdef PART_FACE
#ifdef PASS_COMPOSITE
    if (sAA78 < g_AlphaThreshold) discard;
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
    if (sAA78 >= g_AlphaThreshold) discard;
    if (0.01 >= sAA78) discard;
#endif
#endif
    const float2 screenSpaceTexCoord = g_CommonParameter.m_RenderTarget.zw + ps.position.xy * g_CommonParameter.m_RenderTarget.xy;
    const float3 lightSpecularS = SAMPLE(g_SamplerLightSpecular, screenSpaceTexCoord).xyz;
    const float4 gBufferS = SAMPLE(g_SamplerGBuffer, screenSpaceTexCoord);
    const float3 halfWeightedNormal = gBufferS.xyz - 0.5;
    const float normalWeightSq = dot(halfWeightedNormal, halfWeightedNormal);
    const float3 normal = halfWeightedNormal * rsqrt(normalWeightSq);
    const float shininess = log2(clamp(gBufferS.w, 0.002, 0.99)) * -15;
#ifdef PASS_COMPOSITE
    float3 lightDiffuseS;
    if (normalWeightSq < 0.15) {
        const float neighborSSUVDelta = 0.0025 / ps.misc.z;
        float3 lightDiffuseAcc = float3(0, 0, 0);
        float weightAcc = 0.0001;
        for (int i = -2; i <= 2; ++i) {
            for (int j = -2; j <= 2; ++j) {
                const float2 neighborSSUV = screenSpaceTexCoord + float2(i, j) * neighborSSUVDelta;
                const float3 neighborHWN = SAMPLE_LEVEL(g_SamplerGBuffer, neighborSSUV, 0).xyz - 0.5;
                const float neighborNWSq = dot(neighborHWN, neighborHWN);
                if (neighborNWSq < 0.15) {
                    const float3 neighborViewPosS = SAMPLE_LEVEL(g_SamplerViewPosition, neighborSSUV, 0).xyz;
                    const float3 neighborViewPosDelta = neighborViewPosS - ps.misc.xyz;
                    const float neighborViewPosDistance = length(neighborViewPosDelta);
                    const float3 neighborNormal = neighborHWN * rsqrt(neighborNWSq);
                    const float s4EED = saturate(dot(normal, neighborNormal));
                    const float s35FC = 0.0001 + neighborViewPosDistance * 1000.0;
                    const float neighborWeight = pow(s4EED, 100) * min(1, 1 / s35FC);
                    const float3 neighborLightDiffuseS = SAMPLE_LEVEL(g_SamplerLightDiffuse, neighborSSUV, 0).xyz;
                    lightDiffuseAcc += neighborLightDiffuseS * neighborWeight;
                    weightAcc += neighborWeight;
                }
            }
        }
        lightDiffuseS = lightDiffuseAcc / weightAcc;
    } else {
        lightDiffuseS = SAMPLE_LEVEL(g_SamplerLightDiffuse, screenSpaceTexCoord, 0).xyz;
    }
    const float3 occlusionS = SAMPLE(g_SamplerOcclusion, screenSpaceTexCoord).xyz;
    const float s3522 = 1 - occlusionS.y - occlusionS.z * g_AreaAlignment;
    const float sF465 = lerp(s3522, occlusionS.x, g_SceneParameter.m_OcclusionIntensity.w);
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
    const float3 lightDiffuseS = SAMPLE(g_SamplerLightDiffuse, screenSpaceTexCoord).xyz;
#endif
    const float s866F = g_AmbientParam[4].y + g_AmbientParam[4].x * ps.misc.z;
    const float sEDB0 = abs(s866F) * s866F;
    const float sEBD9 = clamp(sEDB0, g_AmbientParam[4].z, 1);
    const float3 t4FC9 = g_AmbientParam[3].w * saturate(MUL_3X4_ROWS(g_AmbientParam, 0, float4(normal, 1)));
    const float3 t36A0 = t4FC9 * sEBD9;
    const float3 t2F89 = lightDiffuseS + t36A0 * t36A0;
    const float s509C = dot(t2F89, float3(0.29891, 0.58661, 0.11448));
    const float s3A10 = saturate(g_CommonParameter.m_Misc.w + g_CommonParameter.m_Misc.z * s509C);
    const float3 incident = normalize(ps.misc.xyz);
    const float3 reflection = reflect(incident, normal);
    const float3 t99D9 = g_AmbientParam[3].w * saturate(MUL_3X4_ROWS(g_AmbientParam, 0, float4(reflection, 1)));
    const float3 reflectionTexCoord = normalize(mul(g_CameraParameter.m_InverseViewMatrix, float4(reflection, 0)));
    const float reflectionLevel = 1 + (7 - log2(shininess)) * 0.75;
    const float reflectionS = SAMPLE_LEVEL(g_SamplerReflection, reflectionTexCoord, reflectionLevel).x;
    const float s3134 = reflectionS * g_AmbientParam[5].x * 2;
    const float s4BD7 = g_AmbientParam[5].y + s3134;
    const float3 t76A8 = t99D9 * s4BD7;
    const float3 tA72B = t76A8 * s3A10;
#ifdef PASS_COMPOSITE
    const float s94E5 = saturate(lerp(2, sF465, sAA78));
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
#ifdef PART_FACE
    const float s0DDB = 0 < g_AlphaThreshold ? (sAA78 / g_AlphaThreshold) : sAA78;
#else
    const float s0DDB = sAA78;
#endif
    const float s94E5 = saturate(2 - s0DDB);
#endif
    const float s76EF = (1 - s94E5) * 0.25;
    const float sE25C = lerp(s94E5, 2, g_SceneParameter.m_OcclusionIntensity.w * 0.5);
    const float2 dB260 = POW(sE25C, g_SceneParameter.m_OcclusionIntensity.xy);
    const float3 t632C = s94E5 * t36A0;
    const float3 t2D55 = t632C + dB260.x * lightDiffuseS;
    const float3 t82B2 = s94E5 * tA72B;
    const float3 mtrlFresnelValue0Sq = g_FresnelValue0 * g_FresnelValue0;
    const float3 t1890 = SAMPLE(g_SamplerDiffuse, ps.texCoord2.xy).xyz;
    const float3 t86FC = t1890 * t1890;
    const float3 maskS = SAMPLE(g_SamplerMask, ps.texCoord2.xy).xyz;
    const float3 tF5DD = lerp(1, g_CustomizeParameter.m_SkinColor.xyz, maskS.x);
    const float3 t3F37 = lerp(mtrlFresnelValue0Sq, g_CustomizeParameter.m_SkinFresnelValue0.xyz, maskS.x);
#ifdef PART_BODY_HRO
    const float specularSq = 0.04;
    const float3 tFC46 = lerp(g_CustomizeParameter.m_MainColor.xyz, g_CustomizeParameter.m_MeshColor.xyz, maskS.z);
    const float3 tBB51 = lerp(tF5DD, tFC46, maskS.y);
#else
    const float specularSq = maskS.y * maskS.y;
    const float3 tBB51 = tF5DD;
#endif
    const float3 t19A8 = t86FC * tBB51;
#ifdef PART_FACE
    const float lipInfluence = maskS.z * (0.1 < g_CustomizeParameter.m_LipColor.w ? 1.0 : 0);
    const float3 t98C7 = lerp(t3F37, g_LipFresnelValue0, lipInfluence);
    const float shininess2 = lerp(g_Shininess, g_LipShininess, lipInfluence);
#else
    const float shininess2 = g_Shininess;
#endif
#ifdef PART_BODY
    const float3 t98C7 = t3F37;
#endif
#ifdef PART_BODY_HRO
    const float3 t98C7 = lerp(t3F37, g_CustomizeParameter.m_HairFresnelValue0.xyz, maskS.y);
#endif
#ifdef PART_FACE
    const float2 tileTexCoord = g_TileScale.x * ps.texCoord2.zw;
#else
    const float2 tileTexCoord = g_TileScale.x * ps.texCoord2.xy;
#endif
    const float tileIndex = 0.015625 * (0.5 + floor(0.5 + g_TileIndex));
    const float4 tileDiffuseS = SAMPLE_LEVEL(g_SamplerTileDiffuse, float3(tileTexCoord, tileIndex), 0).xyzw;
    const float4 q4046 = tileDiffuseS * tileDiffuseS;
    const float3 tEC2C = q4046.xyz * t19A8;
    const float s2A74 = q4046.w * g_SpecularMask;
#ifdef PART_FACE
    const float decalU = ps.texCoord2.z * g_CustomizeParameter.m_LeftColor.w + g_CustomizeParameter.m_RightColor.w;
    const float decalSY = SAMPLE(g_SamplerDecal, float2(decalU, ps.texCoord2.w)).y;
#else
    // The following is disabled because, when redirecting skin.shpk, the game mixes up the body decal (legacy mark) with the gear decal (FC crest)
    const float decalSY = 0 /* SAMPLE(g_SamplerDecal, ps.texCoord2.zw).y */;
#endif
#ifdef PART_FACE
    const float sD2BF = g_CustomizeParameter.m_LipColor.w * maskS.z;
    const float3 t1F64 = lerp(tEC2C, g_CustomizeParameter.m_LipColor.xyz, sD2BF);
#else
    const float3 t1F64 = tEC2C;
#endif
    const float3 t5E5C = lerp(t1F64, g_DecalColor.xyz, decalSY * g_DecalColor.w);
    const float3 mtrlDiffuseColorSq = g_DiffuseColor * g_DiffuseColor;
    const float3 t473B = t5E5C * mtrlDiffuseColorSq;
    const float3 diffuseColor = ps.color.y * t473B;
    const float s127B = ps.color.z * s2A74;
    const float s5D19 = 1 - min(1, abs(dot(incident, normal)));
    const float sCF0E = s5D19 * s5D19;
    const float3 t11C4 = lerp(t98C7 * specularSq, 1, sCF0E * sCF0E);
    const float2 d26F8 = lerp(1, g_SceneParameter.m_Wetness.xw, ps.misc.w);
    const float s5623 = saturate(s127B * d26F8.x);
    const float3 t5938 = d26F8.y * diffuseColor;
    const float s1937 = dot(t11C4, t11C4) / (dot(t11C4, 1) + 0.001);
    const float sFEBF = s1937 * s1937;
    const float3 tC228 = ps.misc.www / (1 + sFEBF * 4);
    const float3 tDCB4 = lerp(t11C4, g_SceneParameter.m_Wetness.z, tC228);
    const float sDCB5 = lerp(shininess2, g_SceneParameter.m_Wetness.y, ps.misc.w);
    const float3 t833A = normalize(float3(0, -0.2, 0) - ps.misc.xyz);
    const float3 t18BE = normalize(float3(g_InstanceParameter.m_CameraLight.m_Rim.y, 0, 0) - incident);
    const float s386B = 1 - saturate(dot(normal, t18BE));
    const float s91E9 = s386B * s386B * s386B;
    const float s284B = g_InstanceParameter.m_CameraLight.m_Rim.z * s91E9;
    const float s8C1C = saturate(0.5 * dot(normal, t833A) + 0.3);
    const float s93B2 = 0.36 + s8C1C * s8C1C;
    const float3 tD8C7 = t2D55 + g_InstanceParameter.m_CameraLight.m_DiffuseSpecular.z * s93B2;
    const float s65E1 = saturate(dot(reflection, t833A));
    const float s386F = pow(s65E1, sDCB5);
    const float sC68C = s386F * g_InstanceParameter.m_CameraLight.m_DiffuseSpecular.w + s284B;
    const float3 tE81F = sC68C + lightSpecularS * dB260.y;
    const float s371D = (tDCB4.x + tDCB4.y + tDCB4.z) / 3;
    const float sC414 = s371D * s371D;
    const float3 tB799 = tE81F + sC414 * t82B2;
    const float3 tEC0A = tDCB4 * tB799;
    const float s7B92 = dot(t5938, float3(0.29891, 0.58661, 0.11448));
    const float s694E = saturate(0.5 + s7B92 * 0.5);
    const float3 t5B6A = saturate(t5938);
    const float sA38C = 1 + s76EF * s694E;
    const float3 tC25B = t5938 + pow(t5B6A, sA38C) - t5B6A;
    const float3 t8418 = 0 < g_SceneParameter.m_OcclusionIntensity.w ? tC25B : t5938;
    const float3 tBD00 = s5623 * tEC0A;
    const float3 t555F = t8418 * tD8C7 + tBD00;
    const float3 emissiveColorSq = g_EmissiveColor * g_EmissiveColor;
    const float3 t67AD = t555F + emissiveColorSq;
    const float3 tE432 = t67AD * g_InstanceParameter.m_MulColor.xyz;
    const float3 xyz = g_CommonParameter.m_Misc2.x * sqrt(max(0, tE432));

#ifdef PASS_COMPOSITE
    const float3 t70DF = g_InstanceParameter.m_EnvParameter.w * emissiveColorSq;
    const float3 tB7EA = g_CommonParameter.m_Misc.x * tBD00 + t70DF;
    const float4 q9723 = max(float4(tB7EA.xy, t67AD.xy), float4(tB7EA.z, 0, t67AD.z, 0.001));
    const float2 dCCC3 = max(q9723.xz, q9723.yw);
    const float w = dCCC3.x / dCCC3.y;
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
    const float w = s0DDB;
#endif

    return float4(xyz, w);
}
