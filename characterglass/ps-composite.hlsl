#include <structs.hlsli>
#include <resources.hlsli>
#include <functions.hlsli>
#include <composite.hlsli>

static const float2x2 ReflectionTransform = {
    -0.7071067811865476, 0.7071067811865476,
     0.7071067811865476, 0.7071067811865476,
};

float4 main(const PS_Input ps) : SV_TARGET0
{
#ifdef DITHERCLIP_ON
    const float ditherS = g_SamplerDither.Sample(0.25 * trunc(ps.position.xy)).w;
    if (g_InstanceParameter.m_MulColor.w < ditherS) discard;
#endif

    const float index = g_SamplerIndex.Sample(ps.texCoord2.xy).w;
    const ColorRow colorRow = g_SamplerTable.Lookup(index);

    const float3 normalS = g_SamplerNormal.Sample(ps.texCoord2.xy).xyz;
    const float4 maskS = g_SamplerMask.Sample(ps.texCoord2.xy);
    const float4 maskSSq = maskS * maskS;

    CompositeShaderHelper comp;
    comp.viewPosition = ps.misc.xyz;
    comp.alpha = normalS.z * ps.color.w;

    comp.CalculateScreenSpaceTexCoord(ps.position.xy);

    comp.normal = NORMAL(autoNormal(normalS.xy, g_NormalScale));
    comp.normalWeightSq = 1;
    comp.shininess = 1;

    comp.SampleReflection();

    comp.occlusionValue = 1;
    comp.lightDiffuseS = 0.5;

    comp.CalculateLightAmbientReflection();

    comp.occlusionValue = 0;

#ifdef OUTPUT_ADD
    comp.diffuseColor = 0;

    comp.specularMask = colorRow.m_SpecularMask * maskSSq.z;
    comp.fresnelValue0 = colorRow.m_FresnelValue0 * maskSSq.y;

    comp.emissiveColor = colorRow.m_EmissiveColor;
#else
    comp.diffuseColor = ps.color.xyz * colorRow.m_DiffuseColor * maskSSq.x;

    comp.specularMask = 0;
    comp.fresnelValue0 = 0;

    comp.emissiveColor = 0;
#endif

    comp.ApplyFresnelValue0Directionality();
    comp.ApplyWetness(ps.misc.w);
    comp.CalculateLightDiffuseSpecular();

#ifdef OUTPUT_ADD
    const float2 reflectionExtra = pow(saturate(mul(ReflectionTransform, comp.reflection.xy)), colorRow.m_Shininess);
    comp.lightSpecularValue += reflectionExtra.x + reflectionExtra.y;
#endif

    return comp.Finish();
}
