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
    const float3 mtrlFresnelValue0Sq = g_FresnelValue0 * g_FresnelValue0;
    const float3 diffuseS = g_SamplerDiffuse.Sample(ps.texCoord2.xy).xyz;
    const float3 diffuseSSq = diffuseS * diffuseS;
    const float3 maskS = g_SamplerMask.Sample(ps.texCoord2.xy).xyz;
    comp.diffuseColor = lerp(1, g_CustomizeParameter.m_SkinColor.xyz, maskS.x);
    comp.fresnelValue0 = lerp(mtrlFresnelValue0Sq, g_CustomizeParameter.m_SkinFresnelValue0.xyz, maskS.x);
#ifdef PART_BODY_HRO
    const float specularSq = 0.04;
    const float3 hairColor = lerp(g_CustomizeParameter.m_MainColor.xyz, g_CustomizeParameter.m_MeshColor.xyz, maskS.z);
    comp.diffuseColor = lerp(comp.diffuseColor, hairColor, maskS.y);
#else
    const float specularSq = maskS.y * maskS.y;
#endif
    comp.diffuseColor *= diffuseSSq;
    comp.shininess = g_Shininess;
#ifdef PART_FACE
    const float lipInfluence = maskS.z * (g_CustomizeParameter.m_LipColor.w > 0.1 ? 1.0 : 0);
    comp.fresnelValue0 = lerp(comp.fresnelValue0, g_LipFresnelValue0, lipInfluence);
    comp.shininess = lerp(comp.shininess, g_LipShininess, lipInfluence);
#endif
#ifdef PART_BODY_HRO
    comp.fresnelValue0 = lerp(comp.fresnelValue0, g_CustomizeParameter.m_HairFresnelValue0.xyz, maskS.y);
#endif
#ifdef PART_FACE
    const float2 tileTexCoord = g_TileScale.x * ps.texCoord2.zw;
#else
    const float2 tileTexCoord = g_TileScale.x * ps.texCoord2.xy;
#endif
    const float tileIndex = 0.015625 * (0.5 + floor(0.5 + g_TileIndex));
    const float4 tileDiffuseS = g_SamplerTileDiffuse.SampleLevel(float3(tileTexCoord, tileIndex), 0);
    const float4 tileDiffuseSSq = tileDiffuseS * tileDiffuseS;
    comp.diffuseColor *= tileDiffuseSSq.xyz;
#ifdef PART_FACE
    comp.diffuseColor = lerp(comp.diffuseColor, g_CustomizeParameter.m_LipColor.xyz, g_CustomizeParameter.m_LipColor.w * maskS.z);
    const float decalU = ps.texCoord2.z * g_CustomizeParameter.m_LeftColor.w + g_CustomizeParameter.m_RightColor.w;
    const float decalSY = g_SamplerDecal.Sample(float2(decalU, ps.texCoord2.w)).y;
#else
    const float decalSY = g_SamplerDecal.Sample(ps.texCoord2.zw).y;
#endif
    comp.diffuseColor = lerp(comp.diffuseColor, g_DecalColor.xyz, decalSY * g_DecalColor.w);
    const float3 mtrlDiffuseColorSq = g_DiffuseColor * g_DiffuseColor;

    comp.diffuseColor *= ps.color.y * mtrlDiffuseColorSq;
    comp.fresnelValue0 *= specularSq;
    comp.specularMask = ps.color.z * tileDiffuseSSq.w * g_SpecularMask;
    comp.glossMask = 0;
    comp.emissiveColor = g_EmissiveColor * g_EmissiveColor;

    comp.ApplyFresnelValue0Directionality();
    comp.ApplyWetness(ps.misc.w);
    comp.OccludeDiffuse();
    comp.CalculateLightDiffuseSpecular();

    return comp.Finish();
}
