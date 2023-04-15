#ifndef MATERIAL_PARAMETER_SIZE
#if defined(SHPK_IRIS) || defined(SHPK_SKIN)

#define MATERIAL_PARAMETER_SIZE 6

#define g_DiffuseColor     (g_MaterialParameter[0].xyz)
#define g_AlphaThreshold   (g_MaterialParameter[0].w)
#define g_FresnelValue0    (g_MaterialParameter[1].xyz)
#define g_SpecularMask     (g_MaterialParameter[1].w)
#define g_LipFresnelValue0 (g_MaterialParameter[2].xyz)
#define g_Shininess        (g_MaterialParameter[2].w)
#define g_EmissiveColor    (g_MaterialParameter[3].xyz)
#define g_LipShininess     (g_MaterialParameter[3].w)
#define g_TileScale        (g_MaterialParameter[4].xy)
#define g_AreaAlignment    (g_MaterialParameter[4].z)
#define g_TileIndex        (g_MaterialParameter[4].w)
#define g_ScatteringLevel  (g_MaterialParameter[5].x)
#define g_MaterialParameter_15B70E35 (g_MaterialParameter[5].y)
#define g_NormalScale      (g_MaterialParameter[5].z)

#endif
#endif

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

cbuffer g_InstanceParameter
{
    InstanceParameter g_InstanceParameter;
}

cbuffer g_SceneParameter
{
    SceneParameter g_SceneParameter;
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

#define S_s S

struct {
    SamplerState S;
    Texture2D<float4> T;
} g_SamplerViewPosition;

struct {
    SamplerState S;
    Texture2D<float4> T;
} g_SamplerDither;

struct {
    SamplerState S;
    Texture2D<float4> T;
} g_SamplerLightDiffuse;

struct {
    SamplerState S;
    Texture2D<float4> T;
} g_SamplerLightSpecular;

struct {
    SamplerState S;
    Texture2D<float4> T;
} g_SamplerGBuffer;

struct {
    SamplerState S;
    Texture2D<float4> T;
} g_SamplerDiffuse;

struct {
    SamplerState S;
    Texture2D<float4> T;
} g_SamplerNormal;

struct {
    SamplerState S;
    Texture2D<float4> T;
} g_SamplerMask;

struct {
    SamplerState S;
    Texture2D<float4> T;
} g_SamplerDecal;

struct {
    SamplerState S;
    Texture3D<float4> T;
} g_SamplerTileDiffuse;

struct {
    SamplerState S_s;
    Texture3D<float4> T;
} g_SamplerTileNormal;

struct {
    SamplerState S;
    Texture2D<float4> T;
} g_SamplerCatchlight;

struct {
    SamplerState S;
    TextureCube<float4> T;
} g_SamplerReflection;

struct {
    SamplerState S;
    Texture2D<float4> T;
} g_SamplerOcclusion;
