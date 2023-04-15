float3 skin(const float4 vec, const float4 blendWeight, const int4 blendIndices)
{
    return mul(g_JointMatrixArray[blendIndices.x], vec) * blendWeight.x
         + mul(g_JointMatrixArray[blendIndices.y], vec) * blendWeight.y
         + mul(g_JointMatrixArray[blendIndices.z], vec) * blendWeight.z
         + mul(g_JointMatrixArray[blendIndices.w], vec) * blendWeight.w;
}

#ifdef XFORM_SKIN
#define XFORM(vec) skin((vec), vs.blendWeight, vs.blendIndices)
#elif defined(XFORM_RIGID)
#define XFORM(vec) mul(g_WorldViewMatrix, (vec))
#endif

#define SAMPLE(pair, coords) (pair).T.Sample((pair).S, (coords))
#define SAMPLE_LEVEL(pair, coords, level) (pair).T.SampleLevel((pair).S, (coords), (level))

// like pow() but without warning X3571
#define POW(f, e) exp2(log2((f)) * (e))

float3 autoNormal(const float2 normalSample)
{
    float3 normal;
    normal.xy = normalSample - 0.5;
    normal.z = sqrt(max(0, 0.25 - dot(normal.xy, normal.xy)));
    return normalize(normal);
}

float3 resolveNormal(const float2 normalSample, const float3 normal, const float3 tangent, const float3 bitangent)
{
    const float3 tsNormal = autoNormal(normalSample);
    return normal * tsNormal.z + tangent * tsNormal.x + bitangent * tsNormal.y;
}

float3 resolveNormal(const float3 tsNormal, const float3 normal, const float3 tangent, const float3 bitangent)
{
    return normal * tsNormal.z + tangent * tsNormal.x + bitangent * tsNormal.y;
}

#define NORMAL(normalSample) resolveNormal((normalSample), normalize(ps.normal.xyz), normalize(ps.tangent.xyz), normalize(ps.bitangent.xyz))

float3 mul3x4Rows(const float4 xRow, const float4 yRow, const float4 zRow, const float4 vec)
{
    return float3(dot(xRow, vec), dot(yRow, vec), dot(zRow, vec));
}

#define MUL_3X4_ROWS(array, start, vec) mul3x4Rows((array)[(start)], (array)[(start) + 1], (array)[(start) + 2], (vec))
