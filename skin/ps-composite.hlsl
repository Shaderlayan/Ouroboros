#include <config.hlsli>
#include <structs.hlsli>
#include <resources.hlsli>
#include <functions.hlsli>
#include <iridescence.hlsli>
#include <composite.hlsli>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = g_SamplerDither.Sample(0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

    CompositeShaderHelper comp;
    comp.viewPosition = ps.misc.xyz;

    const RemappedTexCoord mainTexCoord = remapTexCoord(ps.texCoord2.xy, ps.normal.w, g_AsymmetryAdapter.x);

    comp.alpha = ps.color.w * g_SamplerNormal.SampleRemapped(mainTexCoord).z;
#ifdef PART_FACE
    if (!comp.AlphaTest()) discard;
    comp.DivideAlpha();
#endif

    comp.CalculateScreenSpaceTexCoord(ps.position.xy);
    comp.SampleGBuffer();
    comp.SampleReflection();
#ifdef PASS_COMPOSITE
    comp.MultisampleLightDiffuse();
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
    comp.SampleLightDiffuse();
#endif
    comp.occlusionValue = saturate(lerp(2, comp.SampleOcclusion(), comp.alpha));
    comp.CalculateLightAmbientReflection();

    const float4 maskS = g_SamplerMask.SampleRemapped(mainTexCoord);
    const float3 mtrlDiffuseColorSq = g_DiffuseColor * g_DiffuseColor;
#ifdef ALUM_LEVEL_T
    const float index = g_SamplerIndex.SampleRemapped(mainTexCoord).w;
    const ColorRow colorRow = g_SamplerTable.Lookup(index);
    const float3 mtrlFresnelValue0Sq = colorRow.m_FresnelValue0;
    const float specularMask = colorRow.m_SpecularMask;
    comp.shininess = colorRow.m_Shininess;
#else
    const float3 mtrlFresnelValue0Sq = g_FresnelValue0 * g_FresnelValue0;
    const float specularMask = g_SpecularMask;
    comp.shininess = g_Shininess;
#endif

    comp.BeginCalculateLightDiffuseSpecular();
#ifdef ALUM_EMISSIVE_REDIRECT
    const float emissiveRedirect = ALUM_EMISSIVE_REDIRECT;
#else
    const float emissiveRedirect = max(0.0, lerp(g_EmissiveRedirect.y, g_EmissiveRedirect.x, comp.lightLevel));
#endif

#ifdef PART_FACE
    const float lipInfluence = maskS.z * (g_CustomizeParameter.m_LipColor.w > 0.1 ? 1.0 : 0);
    comp.shininess = lerp(comp.shininess, g_LipShininess, lipInfluence);
#endif
    float4 diffuseS = g_SamplerDiffuse.SampleRemapped(mainTexCoord);
#ifdef ALUM_LEVEL_T
    diffuseS.xyz *= colorRow.m_DiffuseColor;
#endif
#if defined(ALUM_LEVEL_3) || defined(ALUM_LEVEL_T)
    const float4 effectMaskS = g_SamplerEffectMask.SampleRemapped(mainTexCoord);
    diffuseS.xyz = applyIridescence(diffuseS.xyz, effectMaskS.x, comp.normal);
    const float wetnessInfluence = max(ps.misc.w, screen(ps.misc.w, effectMaskS.y));
#else
    diffuseS.xyz = applyIridescence(diffuseS.xyz, iridescenceFromSkinInfluence(maskS.x), comp.normal);
    const float wetnessInfluence = ps.misc.w;
#endif
    const float3 diffuseSSq = diffuseS.xyz * diffuseS.xyz;

    const float emissivePart = emissiveRedirect * (1.0 - diffuseS.w);
    const float diffusePart = max(0.0, 1.0 - emissivePart);

    comp.diffuseColor = lerp(1, g_CustomizeParameter.m_SkinColor.xyz, maskS.x);
    comp.fresnelValue0 = lerp(mtrlFresnelValue0Sq, g_CustomizeParameter.m_SkinFresnelValue0.xyz, maskS.x);
#ifdef PART_BODY_HRO
    const float specularSq = 0.04;
    const float3 hairColor = lerp(g_CustomizeParameter.m_MainColor.xyz, g_CustomizeParameter.m_MeshColor.xyz, maskS.z);
    comp.diffuseColor = lerp(comp.diffuseColor, hairColor, maskS.y);
#else
    const float specularSq = maskS.y * maskS.y;
#ifdef PART_BODY
    const float3 hairColor = lerp(g_CustomizeParameter.m_MainColor.xyz, g_CustomizeParameter.m_MeshColor.xyz, maskS.w);
    comp.diffuseColor = lerp(comp.diffuseColor, hairColor, saturate(maskS.z * g_StdHairInfluence));
#endif
#endif
    comp.diffuseColor *= diffuseSSq;
#ifdef PART_FACE
    comp.fresnelValue0 = lerp(comp.fresnelValue0, g_LipFresnelValue0, lipInfluence);
#endif
#ifdef PART_BODY_HRO
    comp.fresnelValue0 = lerp(comp.fresnelValue0, g_CustomizeParameter.m_HairFresnelValue0.xyz, maskS.y);
#endif
#ifdef PART_BODY
    comp.fresnelValue0 = lerp(comp.fresnelValue0, g_CustomizeParameter.m_HairFresnelValue0.xyz, saturate(maskS.z * g_StdHairInfluence));
#endif

#ifdef ALUM_LEVEL_3
    const float4 emissiveS = g_SamplerEmissive.SampleRemapped(mainTexCoord);
    comp.emissiveColor = lerp(comp.diffuseColor * emissivePart, emissiveS.xyz * emissiveS.xyz * emissiveRedirect, emissiveS.w);
    comp.lightDiffuseValue = lerp(comp.lightDiffuseValue, comp.lightReflection, effectMaskS.z);
#elif defined(ALUM_LEVEL_T)
    comp.emissiveColor = colorRow.m_EmissiveColor * emissiveRedirect * effectMaskS.z * effectMaskS.z;
#else
    comp.emissiveColor = comp.diffuseColor * emissivePart;
#endif
    comp.diffuseColor *= diffusePart;
#if defined(ALUM_LEVEL_3) || defined(ALUM_LEVEL_T)
    comp.aLumLegacyBloom = emissiveRedirect * effectMaskS.w;
#else
    comp.aLumLegacyBloom = emissivePart;
#endif

#ifdef PART_FACE
    const float2 tileBaseTexCoord = ps.texCoord2.zw;
#else
    const float2 tileBaseTexCoord = mainTexCoord.texCoord;
#endif
#ifdef ALUM_LEVEL_T
    const float2 tileTexCoord = mul(colorRow.m_TileUVTransform, tileBaseTexCoord);
    const float tileIndex = nearestNeighbor64(colorRow.m_TileW);
#else
    const float2 tileTexCoord = g_TileScale.x * tileBaseTexCoord;
    const float tileIndex = 0.015625 * (0.5 + floor(0.5 + g_TileIndex));
#endif
    const float4 tileDiffuseS = g_SamplerTileDiffuse.SampleLevel(float3(tileTexCoord, tileIndex), 0);
    const float4 tileDiffuseSSq = tileDiffuseS * tileDiffuseS;
    comp.diffuseColor *= tileDiffuseSSq.xyz;
#ifdef PART_FACE
    comp.diffuseColor = lerp(comp.diffuseColor, g_CustomizeParameter.m_LipColor.xyz, g_CustomizeParameter.m_LipColor.w * maskS.z);
#endif
#ifdef PART_FACE
    const float decalU = ps.texCoord2.z * g_CustomizeParameter.m_LeftColor.w + g_CustomizeParameter.m_RightColor.w;
    const float decalSY = g_SamplerDecal.Sample(float2(decalU, ps.texCoord2.w)).y;
#else
    const float decalSY = g_SamplerDecal.Sample(ps.texCoord2.zw).y;
#endif
    comp.diffuseColor = lerp(comp.diffuseColor, g_DecalColor.xyz, decalSY * g_DecalColor.w);

    comp.diffuseColor *= ps.color.y * mtrlDiffuseColorSq;
    comp.fresnelValue0 *= specularSq;
    comp.specularMask = ps.color.z * tileDiffuseSSq.w * specularMask;
    comp.emissiveColor += g_EmissiveColor * g_EmissiveColor;

    comp.ApplyFresnelValue0Directionality();
    comp.ApplyWetness(wetnessInfluence);
    comp.OccludeDiffuse();
    comp.EndCalculateLightDiffuseSpecular();

    return comp.Finish();
}
