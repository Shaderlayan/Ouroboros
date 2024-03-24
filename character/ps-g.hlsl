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
    const float2 opacityTexCoord = lerp(ps.texCoord2.xy, ps.texCoord2.zw, g_OpacityTexCoord);
    const float alphaS = g_SamplerNormal.Sample(opacityTexCoord).z;
    const float alpha = ps.color.w * alphaS;
    if (alpha < alphaThreshold) discard;

#ifdef MODE_SIMPLE
    const float3 normal = normalize(ps.normal.xyz);
    float shininess = 100;
#else
    const float index = g_SamplerIndex.Sample(ps.texCoord2.xy).w;
    const ColorRow colorRow = g_SamplerTable.Lookup(index);

    const float3 normalBase = autoNormal(normalS.xy);

    const float2 tileTexCoord = mul(colorRow.m_TileUVTransform, ps.texCoord2.xy);
    const float tileIndex = nearestNeighbor64(colorRow.m_TileW);
    const float2 tileNormalS = g_SamplerTileNormal.SampleLevel(float3(tileTexCoord, tileIndex), 0).xy;
    const float3 tsNormal = normalize(lerp(autoNormal(tileNormalS), sign(normalBase), abs(normalBase)));
    const float3 normal = NORMAL(tsNormal);

    float shininess = colorRow.m_Shininess;
#endif

    const float3 xyz = normal * 0.5 + 0.5;

#ifdef PASS_G_SEMITRANSPARENCY
    const float w = alpha / g_AlphaThreshold;
#else
#ifdef ALUM_LEVEL_3
    const float4 effectMaskS = g_SamplerEffectMask.Sample(ps.texCoord2.xy);
    const float wetnessInfluence = max(ps.misc.w, screen(ps.misc.w, effectMaskS.y));
#else
    const float wetnessInfluence = ps.misc.w;
#endif

    shininess = lerp(shininess, g_SceneParameter.m_Wetness.y, wetnessInfluence);
#ifdef COMPAT_MASK
    const float specularSX = g_SamplerSpecular.Sample(ps.texCoord2.xy).x;
    const float specularSXSq = specularSX * specularSX;
    shininess = (g_UNK_15B70E35 * specularSXSq < 0.01) ? shininess : 1.0;
#endif
    const float w = exp2(shininess / -15);
#endif

    return float4(xyz, w);
}
