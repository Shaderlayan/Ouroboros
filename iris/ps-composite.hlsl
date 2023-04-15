#include <structs.hlsl>
#include <resources.hlsl>
#include <functions.hlsl>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = SAMPLE(g_SamplerDither, 0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

#ifdef PASS_COMPOSITE
    if (1 < g_AlphaThreshold) discard;
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
    if (1 >= g_AlphaThreshold) discard;
#endif

    const float2 screenSpaceTexCoord = ps.position.xy * g_CommonParameter.m_RenderTarget.xy + g_CommonParameter.m_RenderTarget.zw;
    const float3 lightDiffuseS = SAMPLE(g_SamplerLightDiffuse, screenSpaceTexCoord).xyz;
    const float3 lightSpecularS = SAMPLE(g_SamplerLightSpecular, screenSpaceTexCoord).xyz;
    const float3 normal = NORMAL(SAMPLE(g_SamplerNormal, ps.texCoord0).xy);
    const float3 incident = normalize(ps.misc.xyz);
    const float3 reflection = reflect(incident, normal);
    const float3 reflectionTexCoord = normalize(mul(g_CameraParameter.m_InverseViewMatrix, float4(reflection, 0)));
    const float reflectionLevel = (7 - log2(max(0.001, g_Shininess))) * 0.75 + 1;
    const float reflectionS = SAMPLE_LEVEL(g_SamplerReflection, reflectionTexCoord, reflectionLevel).x;
    const float2 maskS = SAMPLE(g_SamplerMask, ps.texCoord0).xy;
    const float2 maskSSq = maskS * maskS;
    const float3 specularColor = g_FresnelValue0 * maskSSq.y;
    const float3 mtrlDiffuseColorSq = g_DiffuseColor * g_DiffuseColor;
    const float3 customizeColor = g_CustomizeParameter.m_LeftColor.xyz * ps.color.x
                                + g_CustomizeParameter.m_RightColor.xyz * ps.color.y;
    const float3 diffuseColor = customizeColor * mtrlDiffuseColorSq * maskSSq.x;
    const float2 catchlightTexCoord = normal.xy * float2(0.5, -0.5) + 0.5;
    const float3 catchlightS = SAMPLE(g_SamplerCatchlight, catchlightTexCoord).xyz;

    const float s4375 = g_AmbientParam[4].x * ps.misc.z + g_AmbientParam[4].y;
    const float s7392 = abs(s4375) * s4375;
    const float s0654 = clamp(s7392, g_AmbientParam[4].z, 1);
    const float3 tD8F5 = g_AmbientParam[3].w * saturate(MUL_3X4_ROWS(g_AmbientParam, 0, float4(normal, 1)));
    const float s5E8C = reflectionS * g_AmbientParam[5].x * 2;
    const float s72E3 = g_AmbientParam[5].y + s5E8C;
    const float3 t7517 = g_AmbientParam[3].w * saturate(MUL_3X4_ROWS(g_AmbientParam, 0, float4(reflection, 1)));
    const float3 t4819 = t7517 * s72E3;
    const float sEE88 = 1 - min(1, abs(dot(incident, normal)));
    const float s9174 = sEE88 * sEE88;
    const float3 tF22F = normalize(float3(g_InstanceParameter.m_CameraLight.m_Rim.y, 0, 0) - incident);
    const float s6BA6 = 1 - saturate(dot(normal, tF22F));
    const float s94D3 = s6BA6 * s6BA6 * s6BA6;
    const float3 t9A69 = lerp(specularColor, 1, s9174 * s9174);
    const float3 t5018 = normalize(float3(0, -0.2, 0) - ps.misc.xyz);
    const float s3E4D = g_InstanceParameter.m_CameraLight.m_Rim.z * s94D3;
    const float sB3C5 = saturate(dot(normal, t5018) * 0.5 + 0.3);
    const float s0915 = sB3C5 * sB3C5 + 0.36;
    const float sC6FB = saturate(dot(reflection, t5018));
    const float s8C82 = pow(sC6FB, g_Shininess);
    const float sC4DF = g_InstanceParameter.m_CameraLight.m_DiffuseSpecular.w * s8C82 + s3E4D;
    const float s24C8 = (t9A69.x + t9A69.y + t9A69.z) / 3;
    const float sDA78 = s24C8 * s24C8;
    const float3 tB0D9 = s0654 * tD8F5;

#ifdef PASS_COMPOSITE
    const float3 occlusionS = SAMPLE(g_SamplerOcclusion, screenSpaceTexCoord).xyz;
    const float s3522 = 1 - occlusionS.y - occlusionS.z * g_AreaAlignment;
    const float sF465 = lerp(s3522, occlusionS.x, g_SceneParameter.m_OcclusionIntensity.w);
    const float2 d7FC0 = POW(sF465, g_SceneParameter.m_OcclusionIntensity.xy);
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
    const float sF465 = 1;
    const float2 d7FC0 = 1;
#endif

    const float3 tFDC1 = lightDiffuseS * d7FC0.x + tB0D9 * sF465;
    const float3 tD752 = lightSpecularS * d7FC0.y + sC4DF;
    const float3 t271F = 0.25 * sF465 * t4819;

    const float3 tC1E4 = catchlightS * g_InstanceParameter.m_CameraLight.m_Rim.w + tD752;
    const float3 tC9BB = sDA78 * t271F + tC1E4;
    const float3 t4AEC = tC9BB * t9A69;
    const float3 tC1F2 = g_InstanceParameter.m_CameraLight.m_DiffuseSpecular.z * s0915 + tFDC1;
    const float3 tB54E = g_SpecularMask * t4AEC;
    const float3 t6A2C = tC1F2 * diffuseColor + tB54E;
    const float3 t6F97 = g_InstanceParameter.m_MulColor.xyz * t6A2C;
    const float3 xyz = g_CommonParameter.m_Misc2.x * sqrt(max(0, t6F97));

#ifdef PASS_COMPOSITE
    const float3 tF4A8 = g_CommonParameter.m_Misc.x * tB54E;
    const float4 q9FC3 = max(float4(tF4A8.xy, t6A2C.xy), float4(tF4A8.z, 0, t6A2C.z, 0.001));
    const float2 d3F95 = max(q9FC3.xz, q9FC3.yw);
    const float w = d3F95.x / d3F95.y;
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
    const float w = 0 < g_AlphaThreshold ? (1 / g_AlphaThreshold) : 1;
#endif

    return float4(xyz, w);
}
