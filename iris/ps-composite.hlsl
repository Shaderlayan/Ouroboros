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

    comp.alpha = 1;
    if (!comp.AlphaTest()) discard;
    comp.DivideAlpha();

    comp.CalculateScreenSpaceTexCoord(ps.position.xy);
    comp.SampleLightDiffuse();
    comp.normal = NORMAL(g_SamplerNormal.Sample(ps.texCoord0).xy);
    comp.normalWeightSq = 1;
    comp.shininess = max(0.001, g_Shininess);
    comp.SampleReflection();
    comp.occlusionValue = comp.SampleOcclusion();
    comp.CalculateLightAmbientReflection();

    const float2 maskS = g_SamplerMask.Sample(ps.texCoord0).xy;
    const float2 maskSSq = maskS * maskS;

    const float3 mtrlDiffuseColorSq = g_DiffuseColor * g_DiffuseColor;
    const float3 customizeColor = g_CustomizeParameter.m_LeftColor.xyz * ps.color.x
                                + g_CustomizeParameter.m_RightColor.xyz * ps.color.y;

    const float2 catchlightTexCoord = comp.normal.xy * float2(0.5, -0.5) + 0.5;
    const float3 catchlightS = g_SamplerCatchlight.Sample(catchlightTexCoord).xyz;

    comp.diffuseColor = customizeColor * mtrlDiffuseColorSq * maskSSq.x;
    comp.fresnelValue0 = g_FresnelValue0 * maskSSq.y;
    comp.specularMask = g_SpecularMask;
    comp.shininess = g_Shininess;
    comp.emissiveColor = 0;

    comp.ApplyFresnelValue0Directionality();
    comp.CalculateLightDiffuseSpecular();
    comp.lightSpecularValue += g_InstanceParameter.m_CameraLight.m_Rim.w * catchlightS;

    return comp.Finish();
}
