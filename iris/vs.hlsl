#include <structs.hlsl>
#include <resources.hlsl>
#include <functions.hlsl>

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

    ps.texCoord0 = vs.texCoord.xy;

#ifdef PASS_G
    ps.color = 0;
#elif defined(PASS_Z) && defined(SUBVIEW_MAIN)
    ps.color.xyz = vs.color.xyz * vs.color.xyz;
    ps.color.w = vs.color.w;
#else
    ps.color = vs.color;
#endif

#if defined(PASS_Z) && defined(SUBVIEW_MAIN)
    ps.misc = ps.position;
#elif defined(PASS_COMPOSITE)
    ps.misc = float4(viewPosition, 0);
#else
    ps.misc = 0;
#endif

#ifdef PASS_Z
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

    ps.texCoord1 = 0;
    ps.texCoord2 = 0;
}
