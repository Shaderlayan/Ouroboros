#include <structs.hlsli>
#include <resources.hlsli>
#include <functions.hlsli>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = g_SamplerDither.Sample(0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

#ifdef PASS_G
    if (1 < g_AlphaThreshold) discard;
#endif

    const RemappedTexCoord mainTexCoord = remapTexCoord(ps.texCoord0, ps.normal.w, g_AsymmetryAdapter.x);

#ifdef ALUM_LEVEL_T
    const float index = g_SamplerIndex.SampleRemapped(mainTexCoord).w;
    const ColorRow colorRow = g_SamplerTable.Lookup(index);
    float shininess = colorRow.m_Shininess;
#else
    float shininess = g_Shininess;
#endif

    const float3 xyz = NORMAL(g_SamplerNormal.SampleRemapped(mainTexCoord).xy) * 0.5 + 0.5;
    const float w = exp2(shininess / -15);
    return float4(xyz, w);
}
