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

#if defined(PASS_Z) && !defined(SUBVIEW_SHADOW0)
    ps.color.xyz = vs.color.xyz * vs.color.xyz;
    ps.color.w = vs.color.w;
#else
    ps.color = vs.color;
#endif

    ps.texCoord2 = vs.texCoord;

#if defined(PASS_Z) && defined(SUBVIEW_MAIN)
    ps.misc = ps.position;
#elif defined(PASS_G) || defined(PASS_COMPOSITE)
    ps.misc.xyz = viewPosition;

    const float4 wetness = g_InstanceParameter.m_Wetness;
    ps.misc.w = clamp(wetness.x * (vs.position.y * g_ModelParameter.m_Params.x + wetness.y),
        wetness.z, wetness.w);
#else
    ps.misc = 0;
#endif

#if !defined(PASS_G) && !defined(PASS_G_SEMITRANSPARENCY)
    ps.normal = 0;
    ps.tangent = 0;
    ps.bitangent = 0;
#else
    ps.normal = normalize(XFORM(float4(vs.normal, 0)));
    const float4 binormal = vs.binormal * 2 - 1;
    ps.bitangent = normalize(XFORM(float4(binormal.xyz, 0)));
    ps.tangent = normalize(cross(ps.bitangent, ps.normal) * binormal.w);
#endif

    ps.texCoord0 = 0;
    ps.texCoord1 = 0;
}