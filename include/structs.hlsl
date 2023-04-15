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

struct CameraLight
{
    float4 m_DiffuseSpecular;
    float4 m_Rim;
};

struct InstanceParameter
{
    float4 m_MulColor;
    float4 m_EnvParameter;
    CameraLight m_CameraLight;
    float4 m_Wetness;
};

struct ModelParameter
{
    float4 m_Params;
};

struct SceneParameter
{
    float4 m_OcclusionIntensity;
    float4 m_Wetness;
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
    /* v4 */ float3 normal    : TEXCOORD4;
    /* v5 */ float3 tangent   : TEXCOORD5;
    /* v6 */ float3 bitangent : TEXCOORD6;
    /* v7 */ float4 misc      : TEXCOORD7;
};
