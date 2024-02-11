struct CameraLight
{
    float4 m_DiffuseSpecular;
    float4 m_Rim;
};

struct CameraParameter
{
    row_major float3x4 m_ViewMatrix;
    row_major float3x4 m_InverseViewMatrix;
    row_major float4x4 m_ViewProjectionMatrix;
    row_major float4x4 m_InverseViewProjectionMatrix;
    row_major float4x4 m_InverseProjectionMatrix;
    row_major float4x4 m_ProjectionMatrix;
    row_major float4x4 m_MainViewToProjectionMatrix;
    float3 m_EyePosition;
    float3 m_LookAtVector;
};

struct CommonParameter
{
    float4 m_RenderTarget;
    float4 m_Viewport;
    float4 m_Misc;
    float4 m_Misc2;
};

struct CustomizeParameter
{
    float4 m_SkinColor;
    float4 m_SkinFresnelValue0;
    float4 m_LipColor;
    float3 m_MainColor;
    float3 m_HairFresnelValue0;
    float3 m_MeshColor;
    float4 m_LeftColor;
    float4 m_RightColor;
    float3 m_OptionColor;
};

struct DecalParameter
{
    row_major float3x4 m_WorldViewMatrix;
    row_major float3x4 m_InversWorldViewMatrix;
    row_major float4x4 m_WorldViewProjMatrix;
    row_major float4x4 m_InversWorldViewProjMatrix;
    float4 m_Param;
    float4 m_Material0;
    float4 m_Material1;
};

struct DirectionalShadowParameter
{
    row_major float4x4 m_ShadowProjectionMatrix;
    float4 m_ShadowDistance;
    float4 m_ShadowMapParameter;
};

struct GrassCommonParam
{
    float4 m_GrassNormal;
    float4 m_Param;
};

struct InstanceData
{
    row_major float3x4 m_TransformMatrix;
    float4 m_InstanceParam0;
    float4 m_InstanceParam1;
    float4 m_InstanceParam2;
};

#if defined(SHPK_CHARACTER) || defined(SHPK_CHARACTERGLASS) || defined(SHPK_HAIR) || defined(SHPK_IRIS) || defined(SHPK_SKIN)
#define HAS_INSTANCE_PARAMETER
struct InstanceParameter
{
    float4 m_MulColor;
    float4 m_EnvParameter;
    CameraLight m_CameraLight;
    float4 m_Wetness;
};
#endif

#if defined(SHPK_LIGHTSHAFT)
#define HAS_INSTANCE_PARAMETER
struct InstanceParameter
{
    row_major float3x4 transform;
    row_major float3x4 rotate;
    float4 misc[4];
};
#endif

#if defined(SHPK_RIVER) || defined(SHPK_WATER)
#define HAS_INSTANCE_PARAMETER
struct InstanceParameter
{
    row_major float3x4 m_WorldViewMatrix;
    float4 m_Misc;
};
#endif

#if defined(SHPK_VERTICALFOG)
#define HAS_INSTANCE_PARAMETER
typedef float4 InstanceParameter;
#endif

#if defined(SHPK_PLANELIGHTING) || defined(SHPK_DIRECTIONALLIGHTING) || defined(SHPK_DIRECTIONALSHADOW) || defined(SHPK_LINELIGHTING) || defined(SHPK_POINTLIGHTING) || defined(SHPK_SPOTLIGHTING)
#define HAS_LIGHT_PARAM
struct LightParam
{
    float3 m_Position;
    float3 m_Direction;
    float3 m_DiffuseColor;
    float3 m_SpecularColor;
    float4 m_Attenuation;
    float4 m_ClipMin;
    float3 m_ClipMax;
    float3 m_FadeScale;
    float4 m_ShadowTexMask;
    float4 m_PlaneRayDirection;
    row_major float3x4 m_PlaneInversMatrix;
    row_major float3x4 m_WorldViewInversMatrix;
    row_major float4x4 m_LightMapMatrix;
    row_major float4x4 m_WorldViewProjectionMatrix;
#ifndef SHPK_DIRECTIONALSHADOW
    float4 m_HeightAttenuationPlane;
    float4 m_HeightAttenuation;
#endif
};
#endif

struct MaterialParameterDynamic
{
    float4 m_EmissiveColor;
};

struct ModelParameter
{
    float4 m_Params;
};

struct OmniShadowParam
{
    row_major float4x4 m_ViewProjectionMatrix[4];
    float4 m_Resolution;
};

struct PS_DecalSpecificParameters
{
    float4 BlendRate;
    float4 LightApplyRate;
};

struct PS_DocumentParameters
{
    float4 ScreenSize;
    float4 ModulateColor;
    float4 FogParam;
    float4 CameraParam;
};

struct PS_ModelLightParameters
{
    float4 Scene_AmbientColor;
    float4 DirectionalLight_Direction;
    float4 DirectionalLight_Color;
    float4 PointLightParameters[4];
};

struct PS_ModelSpecificParameters
{
    float4 EyePosition;
    float4 FresnelParameter[3];
    float4 WorldPosition;
    float4 ViewportPosition;
};

#if defined(SHPK_3DUI)
#define HAS_PARAMETER
struct Parameter
{
    float4 renderTarget;
    float4 viewport;
};
#endif

#if defined(SHPK_LIGHTSHAFT)
#define HAS_PARAMETER
typedef float4 Parameter[2];
#endif

#if defined(SHPK_VERTICALFOG)
#define HAS_PARAMETER
typedef float4 Parameter[3];
#endif

struct SceneParameter
{
    float4 m_OcclusionIntensity;
    float4 m_Wetness;
};

struct ShadowMaskParameter
{
    row_major float4x4 m_WorldViewProjectionMatrix;
    float4 m_Param;
};

struct UnderWaterParam
{
    float4 m_ViewSpaceWaterPlane;
    float4 m_ViewSpaceHeightAttenuationPlane;
    float4 m_Param;
    float4 m_UvScroll;
    float4 m_UvSize;
};

struct VS_PerInstanceParameters
{
    row_major float4x4 WorldMatrix;
    float4 Parameters;
    float4 Color;
};

struct WaterParameter
{
    float4 m_WavingParam;
    float4 m_GBufferSize;
    float4 m_GBufferPixelSize;
    float4 m_RenderTargetSize;
    float4 m_RenderTargetPixelSize;
    float4 m_HalfViewPositionPixelSize;
    float4 m_RLRParam;
    float4 m_NoiseSize;
    float4 m_WaveletTexcoordV;
    float4 m_WaveletMaskTexcoordV;
    float4 m_WaveletAlpha;
    float4 m_WaveletMaskAlpha;
    float4 m_WaveletTopBlend;
    float4 m_Roughness;
    float4 m_FogColor;
    float4 m_Misc;
    float4 m_UnderCausticsParam;
    float4 m_UpperCausticsParam;
};

struct WavingParam
{
    float3 m_WindVector;
    float3 m_UpVector;
    float4 m_WavingParam;
};

struct VS_Input
{
    /* v0 */ float3 position     : POSITION0;
    /* v1 */ float4 color        : COLOR0;
    /* v2 */ float3 normal       : NORMAL0;
    /* v3 */ float4 texCoord     : TEXCOORD0;
    /* v4 */ float3 tangent      : TANGENT0;
    /* v5 */ float4 binormal     : BINORMAL0;
    /* v6 */ float4 blendWeight  : BLENDWEIGHT0;
    /* v7 */ int4   blendIndices : BLENDINDICES0;
};

struct PS_Input
{
    /* v0 */ float4 position  : SV_POSITION0;
    /* v1 */ float4 color     : COLOR0;
    /* v2 */ float2 texCoord0 : TEXCOORD0;
    /* w2 */ float2 texCoord1 : TEXCOORD1;
    /* v3 */ float4 texCoord2 : TEXCOORD2;
    /* v4 */ float4 normal    : TEXCOORD4;
    /* v5 */ float3 tangent   : TEXCOORD5;
    /* v6 */ float3 bitangent : TEXCOORD6;
    /* v7 */ float4 misc      : TEXCOORD7;
};
