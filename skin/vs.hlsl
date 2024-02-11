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

#ifdef SUBVIEW_MAIN
    ps.color.xyz = vs.color.xyz * vs.color.xyz;
    ps.color.w = vs.color.w;

    ps.texCoord2 = vs.texCoord;
#else
    ps.color = 0;

    ps.texCoord2 = 0;
#endif

#if !defined(PASS_Z)
    ps.misc.xyz = viewPosition;

    const float4 wetness = g_InstanceParameter.m_Wetness;
    ps.misc.w = clamp(wetness.x * (vs.position.y * g_ModelParameter.m_Params.x + wetness.y),
        wetness.z, wetness.w);
#elif defined(SUBVIEW_MAIN)
    ps.misc = ps.position;
#else
    ps.misc = 0;
#endif

#ifndef PASS_G
    ps.normal.xyz = 0;
    ps.tangent = 0;
    ps.bitangent = 0;
#else
    ps.normal.xyz = normalize(XFORM(float4(vs.normal, 0)));
    const float4 binormal = vs.binormal * 2 - 1;
    ps.bitangent = normalize(XFORM(float4(binormal.xyz, 0)));
    ps.tangent = normalize(cross(ps.bitangent, ps.normal.xyz) * binormal.w);
#endif

    ps.normal.w = vs.position.x;

    ps.texCoord0 = 0;
    ps.texCoord1 = 0;
}
