#include <structs.hlsl>
#include <resources.hlsl>
#include <functions.hlsl>
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

    const float4 maskS = g_SamplerMask.Sample(ps.texCoord2.xy);
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

    comp.diffuseColor *= ps.color.xyz * maskSXYSq.x * mtrlDiffuseColorSq;
    comp.specularMask = g_SpecularMask * maskSXYSq.y;
    comp.fresnelValue0 = g_CustomizeParameter.m_HairFresnelValue0;
    comp.shininess = g_Shininess;
    comp.emissiveColor = 0;

    comp.ApplyFresnelValue0Directionality();
    comp.ApplyWetness(ps.misc.w);
    comp.OccludeDiffuse();
    comp.CalculateLightDiffuseSpecular();

    return comp.Finish();
}
