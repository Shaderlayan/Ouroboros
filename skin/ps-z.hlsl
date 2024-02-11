#include <structs.hlsli>
#include <resources.hlsli>
#include <functions.hlsli>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = g_SamplerDither.Sample(0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

#ifdef SUBVIEW_MAIN
    const float normalSZ = g_SamplerNormal.Sample(ps.texCoord2.xy).z;
    if (normalSZ * ps.color.w < g_AlphaThreshold) discard;

    const float euclideanZ = ps.misc.z / ps.misc.w;
    return 1 / (1 + exp(-euclideanZ * 10 + 5));
#else
    return 0;
#endif
}
