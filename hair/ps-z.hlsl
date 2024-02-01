#include <structs.hlsl>
#include <resources.hlsl>
#include <functions.hlsl>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = g_SamplerDither.Sample(0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

#ifdef SUBVIEW_MAIN
#ifdef ALUM_LEVEL_T
    const float alphaS = 1; // Channel stolen for the index map. It is most often white in vanilla anyway.
#else
    const float alphaS = g_SamplerNormal.Sample(ps.texCoord2.xy).z;
#endif
#else
    const float alphaS = g_SamplerNormal.Sample(ps.texCoord2.zw).w;
#endif
    if (alphaS * ps.color.w < g_AlphaThreshold) discard;

#ifdef SUBVIEW_MAIN
    const float euclideanZ = ps.misc.z / ps.misc.w;
    return 1 / (1 + exp(-euclideanZ * 10 + 5));
#else
    return 0;
#endif
}
