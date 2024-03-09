#include <structs.hlsli>
#include <resources.hlsli>
#include <functions.hlsli>

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

    const float3 normalRaw = autoNormal(normalS.xy, g_NormalScale);
    const float3 xyz = NORMAL(normalRaw) * 0.5 + 0.5;
#ifdef PASS_G_SEMITRANSPARENCY
    const float w = alpha / g_AlphaThreshold;
#else
    float shininess = lerp(g_Shininess, g_SceneParameter.m_Wetness.y, ps.misc.w);
    shininess = lerp(1, shininess, g_UNK_15B70E35 < 0.01 ? 1.0 : 0);
    const float w = exp2(shininess / -15);
#endif
    return float4(xyz, w);
}
