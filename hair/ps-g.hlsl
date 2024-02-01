#include <structs.hlsl>
#include <resources.hlsl>
#include <functions.hlsl>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = g_SamplerDither.Sample(0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

#ifdef PASS_G_SEMITRANSPARENCY
    const float alphaThreshold = 1.0 / 255.0;
#else
    const float alphaThreshold = g_AlphaThreshold;
#endif

    const float4 normalS = g_SamplerNormal.Sample(ps.texCoord2.xy);
#ifdef PART_FACE
    const float alphaS = normalS.w;
#else
    const float alphaS = g_SamplerNormal.Sample(ps.texCoord2.zw).w;
#endif
    const float alpha = ps.color.w * alphaS;
    if (alpha < alphaThreshold) discard;

    const float2 normalXY = normalS.xy - 0.5;
    const float normalZ = sqrt(max(0, 0.25 - dot(normalXY, normalXY)));
    const float3 normalRaw = normalize(float3(normalXY * g_NormalScale, normalZ));
    const float3 xyz = NORMAL(normalRaw) * 0.5 + 0.5;
#ifdef PASS_G_SEMITRANSPARENCY
    const float w = alpha / g_AlphaThreshold;
#else
#if defined(ALUM_LEVEL_3) || defined(ALUM_LEVEL_T)
    const float4 effectMaskS = g_SamplerEffectMask.Sample(ps.texCoord2.xy);
    const float wetnessInfluence = max(ps.misc.w, screen(ps.misc.w, effectMaskS.y));
#else
    const float wetnessInfluence = ps.misc.w;
#endif

#ifdef ALUM_LEVEL_T
    const float index = g_SamplerIndex.Sample(ps.texCoord2.xy).z; /* /!\ NOT w */
    const ColorRow colorRow = g_SamplerTable.Lookup(index);
    float shininess = colorRow.m_Shininess;
#else
    float shininess = g_Shininess;
#endif

    shininess = lerp(shininess, g_SceneParameter.m_Wetness.y, wetnessInfluence);
    shininess = lerp(1, shininess, g_UNK_15B70E35 < 0.01 ? 1.0 : 0);
    const float w = exp2(shininess / -15);
#endif
    return float4(xyz, w);
}
