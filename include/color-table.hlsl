struct ColorRow
{
    float3 m_DiffuseColor;
    float m_SpecularMask;
    float3 m_FresnelValue0;
    float m_Shininess;
    float3 m_EmissiveColor;
    float m_TileW;
    row_major float2x2 m_TileUVTransform;
};

struct ColorTable : GameSampler2D4
{
    ColorRow Lookup(float index)
    {
        const float vBase = index * 15.0;
        const float vOffFilter = frac(index * 7.5);
        const float vNumerator = 0.5 + lerp(vBase, floor(vBase + 0.5), floor(vOffFilter + vOffFilter));
        const float v = 0.0625 * vNumerator;
        const float tileWV = 0.0625 * (0.5 + floor(vNumerator));

        ColorRow ret;

        const float4 diffuseS = Sample(float2(0.125, v));
        ret.m_DiffuseColor = diffuseS.xyz;
        ret.m_SpecularMask = diffuseS.w;

        const float4 specularS = Sample(float2(0.375, v));
        ret.m_FresnelValue0 = specularS.xyz;
        ret.m_Shininess = specularS.w;

        ret.m_EmissiveColor = Sample(float2(0.625, v)).xyz;
        ret.m_TileW = Sample(float2(0.625, tileWV)).w;

        const float4 transformS = Sample(float2(0.875, v));
        ret.m_TileUVTransform._11_12 = transformS.xy;
        ret.m_TileUVTransform._21_22 = transformS.zw;

        return ret;
    }
};
