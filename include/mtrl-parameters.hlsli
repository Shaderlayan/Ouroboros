#ifndef MATERIAL_PARAMETER_SIZE

#if defined(SHPK_BGCOLORCHANGE) || defined(SHPK_CRYSTAL) || defined(SHPK_BGCRESTCHANGE)

#define MATERIAL_PARAMETER_SIZE 10

#endif

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

#if defined(SHPK_RIVER) || defined(SHPK_WATER)

#define MATERIAL_PARAMETER_SIZE 13

#endif

#if defined(SHPK_LIGHTSHAFT)

#define MATERIAL_PARAMETER_SIZE 5

#endif

#if defined(SHPK_BGUVSCROLL)

#define MATERIAL_PARAMETER_SIZE 12

#endif

#if defined(SHPK_BG)

#define MATERIAL_PARAMETER_SIZE 11

#endif

#if defined(SHPK_VERTICALFOG)

#define MATERIAL_PARAMETER_SIZE 4

#endif

#endif
