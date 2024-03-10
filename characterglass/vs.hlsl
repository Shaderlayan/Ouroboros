#include <structs.hlsli>
#include <resources.hlsli>
#include <functions.hlsli>

void main(const VS_Input vs, out PS_Input ps)
{
    const float3 viewPosition = XFORM(float4(vs.position, 1));
#ifdef PASS_Z
    ps.position = mul(g_CameraParameter.m_MainViewToProjectionMatrix, float4(viewPosition, 1));
#ifndef SUBVIEW_CUBE0
    ps.position.z = max(1e-05, ps.position.z);
#endif
#else
    ps.position = mul(g_CameraParameter.m_ProjectionMatrix, float4(viewPosition, 1));
#endif

#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
    ps.color = vs.color;
    ps.texCoord2 = vs.texCoord;

    ps.normal.xyz = normalize(XFORM(float4(vs.normal, 0)));
    const float4 binormal = vs.binormal * 2 - 1;
    ps.bitangent = normalize(XFORM(float4(binormal.xyz, 0)));
    ps.tangent = normalize(cross(ps.bitangent, ps.normal.xyz) * binormal.w);

    ps.misc.xyz = viewPosition;

    const float4 wetness = g_InstanceParameter.m_Wetness;
    ps.misc.w = clamp(wetness.x * (vs.position.y * g_ModelParameter.m_Params.x + wetness.y),
        wetness.z, wetness.w);
#else
    ps.color = 0;
    ps.texCoord2 = 0;
    ps.normal.xyz = 0;
    ps.tangent = 0;
    ps.bitangent = 0;
    ps.misc = 0;
#endif

    ps.normal.w = vs.position.x;

    ps.texCoord0 = 0;
    ps.texCoord1 = 0;
}
