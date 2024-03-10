#include <config.hlsli>
#include <structs.hlsli>
#include <resources.hlsli>
#include <functions.hlsli>
#include <iridescence.hlsli>
#include <worryass.hlsli>
#include <composite.hlsli>

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = g_SamplerDither.Sample(0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

    CompositeShaderHelper comp;
    comp.viewPosition = ps.misc.xyz;

    comp.alpha = 1;
    if (!comp.AlphaTest()) discard;
    comp.DivideAlpha();

#ifdef VARIANT_WORRYASS
    // See worryass.hlsl. If you know, you know.
    if (ps.color.x > ps.color.y) {
        return worryass(ps.texCoord0);
    }
#endif

    const float distanceFromCenter = length(frac(ps.texCoord0) - 0.5);
    const RemappedTexCoord mainTexCoord = remapTexCoord(ps.texCoord0, ps.normal.w, g_AsymmetryAdapter.x);

#ifdef ALUM_LEVEL_T
    const float index = g_SamplerIndex.SampleRemapped(mainTexCoord).w;
    const ColorRow colorRow = g_SamplerTable.Lookup(index);
#endif

    comp.CalculateScreenSpaceTexCoord(ps.position.xy);
    comp.SampleLightDiffuse();
    comp.normal = NORMAL(g_SamplerNormal.SampleRemapped(mainTexCoord).xy);
    comp.normalWeightSq = 1;
#ifdef ALUM_LEVEL_T
    comp.shininess = max(0.001, colorRow.m_Shininess);
#else
    comp.shininess = max(0.001, g_Shininess);
#endif
    comp.SampleReflection();
    comp.occlusionValue = comp.SampleOcclusion();
    comp.CalculateLightAmbientReflection();

#ifdef ALUM_LEVEL_T
    comp.shininess = colorRow.m_Shininess;
#else
    comp.shininess = g_Shininess;
#endif

    comp.BeginCalculateLightDiffuseSpecular();

    const float4 maskS = g_SamplerMask.SampleRemapped(mainTexCoord);
    const float3 maskSSq = maskS.xyz * maskS.xyz;

    const float3 mtrlDiffuseColorSq = g_DiffuseColor * g_DiffuseColor;
    const float3 customizeColor = g_CustomizeParameter.m_LeftColor.xyz * ps.color.x
                                + g_CustomizeParameter.m_RightColor.xyz * ps.color.y;

    const float optionRadius = dot(g_OptionRadius, ps.color.xy);
    const float3 customizeOrOptionColor = (optionRadius > 0.0 && optionRadius < distanceFromCenter) ? g_CustomizeParameter.m_OptionColor : customizeColor;

    const float2 catchlightTexCoord = comp.normal.xy * float2(0.5, -0.5) + 0.5;
    const float catchlightAsymmetry = saturate(round(g_AsymmetryAdapter.y));
    const float catchlightUFactor = lerp(1.0, 0.5, catchlightAsymmetry);
    const float catchlightUOffset = lerp(0.0, 0.5, step(0.0, ps.normal.w) * catchlightAsymmetry);
    const float3 catchlightS = g_SamplerCatchlight.Sample(catchlightTexCoord * float2(catchlightUFactor, 1) + float2(catchlightUOffset, 0)).xyz;

    comp.diffuseColor = customizeOrOptionColor * maskSSq.x;
    comp.emissiveColor = 0;

#ifdef ALUM_EMISSIVE_REDIRECT
    const float emissiveRedirect = ALUM_EMISSIVE_REDIRECT;
#else
    const float emissiveRedirect = max(0.0, lerp(g_EmissiveRedirect.y, g_EmissiveRedirect.x, comp.lightLevel));
#endif

    const float emissivePart = emissiveRedirect * (1.0 - maskS.w);
    const float diffusePart = max(0.0001, 1.0 - emissivePart);

#if defined(ALUM_LEVEL_3) || defined(ALUM_LEVEL_T)
    const float4 effectMaskS = g_SamplerEffectMask.SampleRemapped(mainTexCoord);
#endif
#ifdef ALUM_LEVEL_3
    const float4 diffuseS = g_SamplerDiffuse.SampleRemapped(mainTexCoord);
    const float4 emissiveS = g_SamplerEmissive.SampleRemapped(mainTexCoord);

    comp.diffuseColor = lerp(comp.diffuseColor, diffuseS.xyz * diffuseS.xyz, diffuseS.w);
    comp.emissiveColor = lerp(comp.diffuseColor * emissivePart, emissiveS.xyz * emissiveS.xyz * emissiveRedirect, emissiveS.w);
#elif defined(ALUM_LEVEL_T)
    comp.emissiveColor = colorRow.m_EmissiveColor * emissiveRedirect * effectMaskS.z * effectMaskS.z;
    comp.diffuseColor = lerp(maskSSq.x, comp.diffuseColor, maskSSq.z) * colorRow.m_DiffuseColor;
#else
    comp.emissiveColor = comp.diffuseColor * emissivePart;
#endif
#if defined(ALUM_LEVEL_3) || defined(ALUM_LEVEL_T)
    comp.diffuseColor = applyIridescenceSq(comp.diffuseColor, effectMaskS.x, comp.normal);
    comp.aLumLegacyBloom = emissiveRedirect * effectMaskS.w;
#else
    comp.aLumLegacyBloom = emissivePart;
#endif

    comp.diffuseColor *= diffusePart * mtrlDiffuseColorSq;
    comp.emissiveColor += g_EmissiveColor * g_EmissiveColor;
#ifdef ALUM_LEVEL_T
    comp.fresnelValue0 = colorRow.m_FresnelValue0 * maskSSq.y;
    comp.specularMask = colorRow.m_SpecularMask;
#else
    comp.fresnelValue0 = g_FresnelValue0 * maskSSq.y;
    comp.specularMask = g_SpecularMask;
#endif

    comp.ApplyFresnelValue0Directionality();
    comp.EndCalculateLightDiffuseSpecular();
    comp.lightSpecularValue += g_InstanceParameter.m_CameraLight.m_Rim.w * catchlightS;

    return comp.Finish();
}
