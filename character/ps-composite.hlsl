#include <structs.hlsli>
#include <resources.hlsli>
#include <functions.hlsli>
#include <composite.hlsli>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = g_SamplerDither.Sample(0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

    CompositeShaderHelper comp;
    comp.viewPosition = ps.misc.xyz;

    comp.alpha = ps.color.w * g_SamplerNormal.Sample(ps.texCoord2.xy).z;
    if (!comp.AlphaTest()) discard;
    comp.DivideAlpha();

    comp.CalculateScreenSpaceTexCoord(ps.position.xy);
    comp.SampleGBuffer();
    comp.SampleReflection();
    comp.SampleLightDiffuse();
    comp.occlusionValue = saturate(lerp(2, comp.SampleOcclusion(), comp.alpha));
    comp.CalculateLightAmbientReflection();

#ifdef MODE_SIMPLE
    comp.shininess = 100;
#else
    const float index = g_SamplerIndex.Sample(ps.texCoord2.xy).w;
    const ColorRow colorRow = g_SamplerTable.Lookup(index);

    comp.shininess = colorRow.m_Shininess;
#endif

#ifdef MODE_COMPATIBILITY
    const float3 specularS = g_SamplerSpecular.Sample(ps.texCoord2.xy).xyz;
    const float3 specularSSq = specularS * specularS;
#ifdef COMPAT_MASK
    comp.glossMask = specularSSq.x;
#else
    comp.glossMask = 0;
#endif
#else
    comp.glossMask = 0;
#endif

    comp.BeginCalculateLightDiffuseSpecular();

#ifdef ALUM_EMISSIVE_REDIRECT
    const float emissiveRedirect = ALUM_EMISSIVE_REDIRECT;
#else
    const float emissiveRedirect = max(0.0, lerp(g_EmissiveRedirect.y, g_EmissiveRedirect.x, comp.lightLevel));
#endif

#ifdef MODE_SIMPLE
    comp.diffuseColor = float3(0.7, 0, 0);

    comp.specularMask = 1;
    comp.fresnelValue0 = 1;

    comp.emissiveColor = float3(0.3, 0, 0);
#else
    const float2 tileTexCoord = mul(colorRow.m_TileUVTransform, ps.texCoord2.xy);
    const float tileIndex = nearestNeighbor64(colorRow.m_TileW);
    const float4 tileDiffuseS = g_SamplerTileDiffuse.SampleLevel(float3(tileTexCoord, tileIndex), 0);
    const float4 tileDiffuseSSq = tileDiffuseS * tileDiffuseS;

    comp.diffuseColor = colorRow.m_DiffuseColor * tileDiffuseSSq.xyz;

    comp.specularMask = colorRow.m_SpecularMask * tileDiffuseSSq.w;
    comp.fresnelValue0 = colorRow.m_FresnelValue0;

    comp.emissiveColor = colorRow.m_EmissiveColor;

#ifdef MODE_COMPATIBILITY
    const float3 diffuseS = g_SamplerDiffuse.Sample(ps.texCoord2.xy).xyz;
    comp.diffuseColor *= diffuseS * diffuseS;

#ifdef COMPAT_MASK
    comp.fresnelValue0 *= specularSSq.y;
    comp.specularMask *= specularSSq.z;
#else
    comp.fresnelValue0 *= specularSSq;
#endif
#else
    const float3 maskS = g_SamplerMask.Sample(ps.texCoord2.xy).xyz;
    const float3 maskSSq = maskS * maskS;

    comp.diffuseColor *= maskSSq.x;
    comp.fresnelValue0 *= maskSSq.y;
    comp.specularMask *= maskSSq.z;
#endif

#ifdef DECAL_COLOR
    const float4 decalS = g_SamplerDecal.Sample(ps.texCoord2.zw);
    const float decalAlpha = decalS.w * g_DecalColor.w;

    comp.diffuseColor = lerp(comp.diffuseColor, decalS.xyz * decalS.xyz * g_DecalColor.xyz, decalAlpha);
    comp.fresnelValue0 *= 1 - decalAlpha * 0.75;
#elif defined(DECAL_ALPHA)
    const float decalAlpha = g_SamplerDecal.Sample(ps.texCoord2.zw).y * g_DecalColor.w;

    comp.diffuseColor = lerp(comp.diffuseColor, g_DecalColor.xyz, decalAlpha);
    comp.fresnelValue0 *= 1 - decalAlpha * 0.75;
#endif

#ifdef VERTEX_MASK
    comp.diffuseColor *= ps.color.y;
    comp.specularMask *= ps.color.z;
#else
    comp.diffuseColor *= ps.color.xyz;
#endif
#endif

#ifdef ALUM_LEVEL_3
    comp.aLumLegacyBloom = emissiveRedirect * effectMaskS.w * luminance(g_MaterialParameterDynamic.m_EmissiveColor.xyz);
#else
    comp.aLumLegacyBloom = emissiveRedirect * luminance(g_MaterialParameterDynamic.m_EmissiveColor.xyz);
#endif

    comp.emissiveColor *= g_MaterialParameterDynamic.m_EmissiveColor.xyz;

    comp.ApplyFresnelValue0Directionality();
    comp.ApplyWetness(ps.misc.w);
    comp.OccludeDiffuse();
    comp.EndCalculateLightDiffuseSpecular();

    return comp.Finish();
}
