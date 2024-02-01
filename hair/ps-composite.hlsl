#include <config.hlsl>
#include <structs.hlsl>
#include <resources.hlsl>
#include <functions.hlsl>
#include <iridescence.hlsl>
#include <composite.hlsl>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = g_SamplerDither.Sample(0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

    CompositeShaderHelper comp;
    comp.viewPosition = ps.misc.xyz;

#ifdef PART_HAIR
    const float alphaS = g_SamplerNormal.Sample(ps.texCoord2.zw).w;
#else
    const float alphaS = g_SamplerNormal.Sample(ps.texCoord2.xy).w;
#endif
    comp.alpha = ps.color.w * alphaS;
    if (!comp.AlphaTest()) discard;
    comp.DivideAlpha();

    comp.CalculateScreenSpaceTexCoord(ps.position.xy);
    comp.SampleLightDiffuse();
    comp.SampleGBuffer();
    comp.SampleReflection();
    const float baseOcclusionValue = 1 - 0.25 * g_SceneParameter.m_OcclusionIntensity.w;
#ifdef PASS_COMPOSITE
    const float occlusionAlpha = saturate((comp.alpha - g_AlphaThreshold) / (1 - g_AlphaThreshold));
    comp.occlusionValue = lerp(baseOcclusionValue, comp.SampleOcclusion(), occlusionAlpha);
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
    comp.occlusionValue = baseOcclusionValue;
#endif
    comp.CalculateLightAmbientReflection();

#ifdef ALUM_LEVEL_T
    const float index = g_SamplerIndex.Sample(ps.texCoord2.xy).z; /* /!\ NOT w */
    const ColorRow colorRow = g_SamplerTable.Lookup(index);
    comp.shininess = colorRow.m_Shininess;
#else
    comp.shininess = g_Shininess;
#endif

    comp.BeginCalculateLightDiffuseSpecular();

#ifdef ALUM_EMISSIVE_REDIRECT
    const float emissiveRedirect = ALUM_EMISSIVE_REDIRECT;
#else
    const float emissiveRedirect = max(0.0, lerp(g_EmissiveRedirect.y, g_EmissiveRedirect.x, comp.lightLevel));
#endif

    const float4 maskS = g_SamplerMask.Sample(ps.texCoord2.xy);
    const float emissivePart = emissiveRedirect * maskS.z;
    const float diffusePart = max(0.0001, 1.0 - emissivePart);
    const float2 maskSXYSq = maskS.xy * maskS.xy;
    const float2 wetSpecDiff = lerp(1, g_SceneParameter.m_Wetness.xw, ps.misc.w);
#ifdef PART_HAIR
    const float maskS2W = g_SamplerMask.Sample(ps.texCoord2.zw).w;
    comp.diffuseColor = lerp(g_CustomizeParameter.m_MainColor.xyz, g_CustomizeParameter.m_MeshColor.xyz, maskS2W);
#endif
#ifdef PART_FACE
    const float decalU = ps.texCoord2.z * g_CustomizeParameter.m_LeftColor.w + g_CustomizeParameter.m_RightColor.w;
    const float decalSY = g_SamplerDecal.Sample(float2(decalU, ps.texCoord2.w)).y;
    comp.diffuseColor = lerp(g_CustomizeParameter.m_MainColor.xyz, g_CustomizeParameter.m_OptionColor.xyz, maskS.w);
    comp.diffuseColor = lerp(comp.diffuseColor, g_DecalColor.xyz, decalSY * g_DecalColor.w);
#endif
    const float3 mtrlDiffuseColorSq = g_DiffuseColor * g_DiffuseColor;

    comp.diffuseColor *= ps.color.xyz * maskSXYSq.x;

#if defined(ALUM_LEVEL_3) || defined(ALUM_LEVEL_T)
    const float4 effectMaskS = g_SamplerEffectMask.Sample(ps.texCoord2.xy);
#endif
#ifdef ALUM_LEVEL_3
    const float wetnessInfluence = max(ps.misc.w, screen(ps.misc.w, effectMaskS.y));
    const float4 diffuseS = g_SamplerDiffuse.Sample(ps.texCoord2.xy);
    const float4 emissiveS = g_SamplerEmissive.Sample(ps.texCoord2.xy);
    const float3 originalDiffuse = comp.diffuseColor;
    const float3 preIriDiffuse = lerp(originalDiffuse, diffuseS.xyz * diffuseS.xyz, diffuseS.w);
    const float3 iriDiffuse = applyIridescence(sqrt(preIriDiffuse), effectMaskS.x, comp.normal);
    comp.diffuseColor = iriDiffuse * iriDiffuse;
    comp.emissiveColor = lerp(originalDiffuse * emissivePart, emissiveS.xyz * emissiveS.xyz * emissiveRedirect, emissiveS.w);
    comp.lightDiffuseValue = lerp(comp.lightDiffuseValue, comp.lightReflection, effectMaskS.z);
    comp.aLumLegacyBloom = emissiveRedirect * effectMaskS.w;
#elif defined(ALUM_LEVEL_T)
    const float wetnessInfluence = max(ps.misc.w, screen(ps.misc.w, effectMaskS.y));
    const float3 originalDiffuse = comp.diffuseColor;
    const float3 preIriDiffuse = lerp(originalDiffuse, colorRow.m_DiffuseColor *  ps.color.xyz * maskSXYSq.x, effectMaskS.z);
    const float3 iriDiffuse = applyIridescence(sqrt(preIriDiffuse), effectMaskS.x, comp.normal);
    comp.diffuseColor = iriDiffuse * iriDiffuse;
    comp.emissiveColor = lerp(originalDiffuse * emissivePart, colorRow.m_EmissiveColor * emissiveRedirect, effectMaskS.z);
    comp.aLumLegacyBloom = emissiveRedirect * effectMaskS.w;
#else
    const float wetnessInfluence = ps.misc.w;
    comp.emissiveColor = comp.diffuseColor * emissivePart;
    comp.aLumLegacyBloom = emissivePart;
#endif

    comp.diffuseColor *= diffusePart * mtrlDiffuseColorSq;
    comp.emissiveColor += g_EmissiveColor * g_EmissiveColor;
#ifdef ALUM_LEVEL_T
    comp.specularMask = colorRow.m_SpecularMask * maskSXYSq.y;
    comp.fresnelValue0 = lerp(g_CustomizeParameter.m_HairFresnelValue0, colorRow.m_FresnelValue0, effectMaskS.z);
#else
    comp.specularMask = g_SpecularMask * maskSXYSq.y;
    comp.fresnelValue0 = g_CustomizeParameter.m_HairFresnelValue0;
#endif

    comp.ApplyFresnelValue0Directionality();
    comp.ApplyWetness(wetnessInfluence);
    comp.OccludeDiffuse();
    comp.EndCalculateLightDiffuseSpecular();

    return comp.Finish();
}
