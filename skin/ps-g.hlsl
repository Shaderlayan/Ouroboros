#include <structs.hlsl>
#include <resources.hlsl>
#include <functions.hlsl>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = g_SamplerDither.Sample(0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

    const float3 normalS = g_SamplerNormal.Sample(ps.texCoord2.xy).xyz;

#ifdef PART_FACE
#ifdef PASS_G
    const float alphaThreshold = g_AlphaThreshold;
#endif
#ifdef PASS_G_SEMITRANSPARENCY
    const float alphaThreshold = 1.0 / 255.0;
#endif
    if (normalS.z * ps.color.w < alphaThreshold) discard;
#endif

    const float2 normalBaseRaw = normalS.xy - 0.5;
    const float normalBaseZ = sqrt(max(0, 0.25 - dot(normalBaseRaw, normalBaseRaw)));
    const float2 normalBaseXY = normalBaseRaw * lerp(1, g_CustomizeParameter.m_SkinColor.w, ps.color.x);
    const float3 normalBase = normalize(float3(normalBaseXY, normalBaseZ));

#ifdef PART_FACE
    const float2 tileTexCoord = g_TileScale.x * ps.texCoord2.zw;
#else
    const float2 tileTexCoord = g_TileScale.x * ps.texCoord2.xy;
#endif

    const float tileIndex = 0.015625 * (0.5 + floor(0.5 + g_TileIndex));
    const float2 tileNormalS = g_SamplerTileNormal.SampleLevel(float3(tileTexCoord, tileIndex), 0).xy;
    const float3 tsNormal = normalize(lerp(autoNormal(tileNormalS), sign(normalBase), abs(normalBase)));
    const float3 normal = NORMAL(tsNormal);

    const float3 maskS = g_SamplerMask.Sample(ps.texCoord2.xy).xyz;
    float skinInfluence = maskS.x;
#ifdef PART_FACE
    skinInfluence *= 1 - maskS.z * g_CustomizeParameter.m_LipColor.w;
#endif
    const float3 finalNormal = normal * (1 - skinInfluence * 0.4);
    const float3 xyz = finalNormal * 0.5 + 0.5;

    float shininess = g_Shininess;
#ifdef PART_FACE
    const float lipInfluence = maskS.z * (g_CustomizeParameter.m_LipColor.w > 0.1 ? 1.0 : 0);
    shininess = lerp(shininess, g_LipShininess, lipInfluence);
#endif
    const float finalShininess = lerp(shininess, g_SceneParameter.m_Wetness.y, ps.misc.w);
    const float w = exp2(finalShininess / -15);

    return float4(xyz, w);
}
