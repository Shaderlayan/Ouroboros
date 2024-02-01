#include <structs.hlsl>
#include <resources.hlsl>
#include <functions.hlsl>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = g_SamplerDither.Sample(0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

#ifdef PASS_G
    if (1 < g_AlphaThreshold) discard;
#endif

    const float3 xyz = NORMAL(g_SamplerNormal.Sample(ps.texCoord0).xy) * 0.5 + 0.5;
    const float w = exp2(g_Shininess / -15);
    return float4(xyz, w);
}
