#include <samplers.hlsl>
#include <color-table.hlsl>
#include <mtrl-parameters.hlsl>

#ifdef MATERIAL_PARAMETER_SIZE
cbuffer g_MaterialParameter
{
    float4 g_MaterialParameter[MATERIAL_PARAMETER_SIZE];
}
#endif

cbuffer g_CommonParameter
{
    CommonParameter g_CommonParameter;
}

cbuffer g_RoofParameter
{
	float4 g_RoofParameter;
}

cbuffer g_WetnessParameter
{
	float4 g_WetnessParameter[2];
}

cbuffer g_DirectionalShadowParameter
{
	DirectionalShadowParameter g_DirectionalShadowParameter;
}

cbuffer g_OmniShadowParam
{
	OmniShadowParam g_OmniShadowParam;
}

cbuffer g_CameraParameter
{
    CameraParameter g_CameraParameter;
}

#ifdef HAS_LIGHT_PARAM
cbuffer g_LightParam
{
	LightParam g_LightParam;
}
#endif

cbuffer g_UnderWaterParam
{
	UnderWaterParam g_UnderWaterParam;
}

cbuffer g_CloudShadowMatrix
{
	row_major float4x4 g_CloudShadowMatrix;
}

cbuffer g_GrassCommonParam
{
	GrassCommonParam g_GrassCommonParam;
}

cbuffer g_CustomizeParameter
{
    CustomizeParameter g_CustomizeParameter;
}

cbuffer g_TransformMatrix
{
	row_major float4x4 g_TransformMatrix;
}

cbuffer g_WorldMatrix
{
	row_major float3x4 g_WorldMatrix;
}

cbuffer g_WorldViewMatrix
{
    row_major float3x4 g_WorldViewMatrix;
}

cbuffer g_WorldViewProjMatrix
{
	row_major float4x4 g_WorldViewProjMatrix;
}

cbuffer g_JointMatrixArray
{
    row_major float3x4 g_JointMatrixArray[64];
}

#ifdef HAS_PARAMETER
cbuffer g_Parameter
{
	Parameter g_Parameter;
}
#endif

cbuffer g_InstancingData
{
	float4 g_InstancingData[198];
}

cbuffer g_InstanceData
{
	InstanceData g_InstanceData;
}

#ifdef HAS_INSTANCE_PARAMETER
cbuffer g_InstanceParameter
{
    InstanceParameter g_InstanceParameter;
}
#endif

cbuffer g_PlateEadg
{
	float4 g_PlateEadg[2];
}

cbuffer g_WavingParam
{
	WavingParam g_WavingParam;
}

cbuffer g_EadgBias
{
	float4 g_EadgBias;
}

cbuffer g_WindParam
{
	float4 g_WindParam;
}

cbuffer g_GrassGridParam
{
	float4 g_GrassGridParam;
}

cbuffer g_BushNoInstancingData
{
	float4 g_BushNoInstancingData[5];
}

cbuffer g_BushInstancingData
{
	float4 g_BushInstancingData[200];
}

cbuffer g_RoofMatrix
{
	row_major float4x4 g_RoofMatrix;
}

cbuffer g_RoofProjectionMatrix
{
	row_major float4x4 g_RoofProjectionMatrix;
}

cbuffer g_GeometryParam
{
	row_major float4x4 g_GeometryParam;
}

cbuffer g_ModelParameter
{
    ModelParameter g_ModelParameter;
}

cbuffer g_MaterialParam
{
	row_major float4x4 g_MaterialParam;
}

cbuffer g_MaterialParameterDynamic
{
    MaterialParameterDynamic g_MaterialParameterDynamic;
}

cbuffer g_SceneParameter
{
    SceneParameter g_SceneParameter;
}

cbuffer g_LightDirection
{
    float3 g_LightDirection;
}

cbuffer g_DecalColor
{
    float4 g_DecalColor;
}

cbuffer g_AmbientParam
{
    float4 g_AmbientParam[6];
}

cbuffer g_AmbientExtra
{
	float4 g_AmbientExtra[4];
}

cbuffer g_BGAmbientParameter
{
	float4 g_BGAmbientParameter;
}

cbuffer g_WaterParameter
{
	WaterParameter g_WaterParameter;
}

cbuffer g_DecalParameter
{
	DecalParameter g_DecalParameter;
}

cbuffer g_ShadowMaskParameter
{
	ShadowMaskParameter g_ShadowMaskParameter;
}

cbuffer g_VSParam
{
	float4 g_VSParam[5];
}

cbuffer g_PSParam
{
	float4 g_PSParam[5];
}

cbuffer g_VS_ViewProjectionMatrix
{
	row_major float4x4 g_VS_ViewProjectionMatrix;
}

cbuffer g_VS_PerInstanceParameters
{
	VS_PerInstanceParameters g_VS_PerInstanceParameters;
}

cbuffer g_PS_ViewProjectionInverseMatrix
{
	row_major float4x4 g_PS_ViewProjectionInverseMatrix;
}

cbuffer g_PS_Parameters
{
	float4 g_PS_Parameters;
}

cbuffer g_PS_UvTransform
{
	float4 g_PS_UvTransform[8];
}

cbuffer g_PS_InstanceExtraParameters
{
	float4 g_PS_InstanceExtraParameters;
}

cbuffer g_PS_DocumentParameters
{
	PS_DocumentParameters g_PS_DocumentParameters;
}

cbuffer g_PS_DecalSpecificParameters
{
	PS_DecalSpecificParameters g_PS_DecalSpecificParameters;
}

cbuffer g_PS_ModelSpecificParameters
{
	PS_ModelSpecificParameters g_PS_ModelSpecificParameters;
}

cbuffer g_PS_ModelLightParameters
{
	PS_ModelLightParameters g_PS_ModelLightParameters;
}

cbuffer g_ToneMapParameter
{
	float4 g_ToneMapParameter;
}

cbuffer g_FogParameter
{
	float4 g_FogParameter[3];
}

GameSampler2D4 g_SamplerViewPosition;
GameSampler2D4 g_SamplerVPosition;
GameSampler2D4 g_SamplerDither;
GameSampler2D4 g_SamplerColorMap0;
GameSampler2D4 g_SamplerColorMap1;
GameSampler2D4 g_SamplerNormalMap0;
GameSampler2D4 g_SamplerNormalMap1;
GameSampler2D4 g_SamplerSpecularMap0;
GameSampler2D4 g_SamplerSpecularMap1;
GameSamplerCube4 g_SamplerEnvMap;
GameSampler2D4 g_SamplerLightDiffuse;
GameSampler2D4 g_SamplerLightSpecular;
GameSampler2D4 g_SamplerAttenuation;
GameSampler2D4 g_SamplerOmniShadowStatic;
GameSampler2D4 g_SamplerOmniShadowDynamic;
GameSamplerCube4 g_SamplerOmniShadowIndexTable;
GameSampler2D4 g_SamplerGBuffer;
GameSampler2D4 g_SamplerGBuffer1;
GameSampler2D4 g_SamplerGBuffer2;
GameSampler2D4 g_SamplerGBuffer3;
#if defined(SHPK_PLANELIGHTING) || defined(SHPK_SPOTLIGHTING)
GameSampler2D4 g_SamplerLight;
#endif
#if defined(SHPK_POINTLIGHTING)
GameSamplerCube4 g_SamplerLight;
#endif
GameSampler2D4 g_SamplerShadow;
GameSampler2D4 g_CloudShadowSampler;
GameSampler2D4 g_RoofSampler;
GameSampler2D4 g_AnimSampler;
#if defined(SHPK_RIVER) || defined(SHPK_WATER)
GameSampler3D4 g_SamplerCaustics;
#endif
#if defined(SHPK_DIRECTIONALLIGHTING)
GameSampler2D4 g_SamplerCaustics;
#endif
GameSampler2D4 g_SamplerColor1;
GameSampler2D4 g_SamplerColor2;
GameSampler2D4 g_SamplerColor3;
GameSampler2D4 g_SamplerColor4;
GameSampler2D4 g_SamplerDistortion;
GameSampler2D4 g_SamplerPalette;
GameSampler2D4 g_SamplerDiffuse;
GameSampler2D4 g_SamplerNormal;
GameSampler2D4 g_SamplerMask;
GameSampler2D4 g_SamplerSpecular;
GameSampler2D4 g_SamplerDecal;
ColorTable g_SamplerTable;
GameSampler3D4 g_SamplerTileDiffuse;
GameSampler3D4 g_SamplerTileNormal;
GameSampler2D4 g_SamplerIndex;
GameSampler2D4 g_SamplerCatchlight;
GameSamplerCube4 g_SamplerReflection;
GameSampler2D4 g_SamplerOcclusion;
GameSampler2D4 g_SamplerDepth;
GameSampler2D4 g_ToneMapSampler;
GameSampler2D4 g_SkySampler;
GameSampler2D4 g_Sampler;
GameSampler2D4 g_SamplerFresnel;
GameSampler2D4 g_SamplerColorMap;
GameSampler2D4 g_SamplerNormalMap;
GameSampler2D4 g_SamplerMaskMap;
GameSampler2D4 g_SamplerSpecularMap;
GameSampler2D4 g_SamplerDistortionMap;
GameSampler2D4 g_SamplerWaveMap;
GameSampler2D4 g_SamplerWhitecapMap;
GameSampler2D4 g_SamplerWaveletMap0;
GameSampler2D4 g_SamplerWaveletMap1;
GameSampler2D4 g_SamplerReflectionMap;
GameSampler2D4 g_SamplerNoise;
GameSampler2D4 g_SamplerWaveletNoise;
GameSampler2D4 g_SamplerRefractionMap;
