#include <samplers.hlsl>
#include <color-table.hlsl>

#ifndef MATERIAL_PARAMETER_SIZE
#if defined(SHPK_HAIR) || defined(SHPK_IRIS) || defined(SHPK_SKIN) || defined(SHPK_CHARACTER) || defined(SHPK_CHARACTERGLASS)

#define MATERIAL_PARAMETER_SIZE 6

#define g_DiffuseColor         (g_MaterialParameter[0].xyz)
#define g_AlphaThreshold       (g_MaterialParameter[0].w)
#define g_FresnelValue0        (g_MaterialParameter[1].xyz)
#define g_SpecularMask         (g_MaterialParameter[1].w)
#define g_LipFresnelValue0     (g_MaterialParameter[2].xyz)
#define g_Shininess            (g_MaterialParameter[2].w)
#define g_EmissiveColor        (g_MaterialParameter[3].xyz)
#define g_LipShininess         (g_MaterialParameter[3].w)
#define g_TileScale            (g_MaterialParameter[4].xy)
#define g_AmbientOcclusionMask (g_MaterialParameter[4].z)
#define g_TileIndex            (g_MaterialParameter[4].w)
#define g_ScatteringLevel      (g_MaterialParameter[5].x)
#define g_UNK_15B70E35         (g_MaterialParameter[5].y)
#define g_NormalScale          (g_MaterialParameter[5].z)

#endif
#endif

#ifdef MATERIAL_PARAMETER_SIZE
cbuffer g_MaterialParameter
{
    float4 g_MaterialParameter[MATERIAL_PARAMETER_SIZE];
}
#endif

cbuffer g_MaterialParameterDynamic
{
    MaterialParameterDynamic g_MaterialParameterDynamic;
}

cbuffer g_CommonParameter
{
    CommonParameter g_CommonParameter;
}

cbuffer g_CameraParameter
{
    CameraParameter g_CameraParameter;
}

cbuffer g_CustomizeParameter
{
    CustomizeParameter g_CustomizeParameter;
}

cbuffer g_WorldViewMatrix
{
    row_major float3x4 g_WorldViewMatrix;
}

cbuffer g_JointMatrixArray
{
    row_major float3x4 g_JointMatrixArray[64];
}

#ifdef HAS_INSTANCE_PARAMETER
cbuffer g_InstanceParameter
{
    InstanceParameter g_InstanceParameter;
}
#endif

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

cbuffer g_ModelParameter
{
    ModelParameter g_ModelParameter;
}

GameSampler2D4 g_SamplerViewPosition;
GameSampler2D4 g_SamplerDither;
GameSampler2D4 g_SamplerLightDiffuse;
GameSampler2D4 g_SamplerLightSpecular;
GameSampler2D4 g_SamplerGBuffer;
GameSampler2D4 g_SamplerDiffuse;
GameSampler2D4 g_SamplerNormal;
GameSampler2D4 g_SamplerMask;
GameSampler2D4 g_SamplerDecal;
ColorTable g_SamplerTable;
GameSampler3D4 g_SamplerTileDiffuse;
GameSampler3D4 g_SamplerTileNormal;
GameSampler2D4 g_SamplerIndex;
GameSampler2D4 g_SamplerCatchlight;
GameSamplerCube4 g_SamplerReflection;
GameSampler2D4 g_SamplerOcclusion;
