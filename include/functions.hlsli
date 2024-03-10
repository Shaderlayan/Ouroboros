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

// like pow() but without warning X3571
#define POW(f, e) exp2(log2((f)) * (e))

float3 autoNormal(const float2 normalSample, const float normalScale = 1.0)
{
    float3 normal;
    normal.xy = normalSample - 0.5;
    normal.z = sqrt(max(0, 0.25 - dot(normal.xy, normal.xy)));
    normal.xy *= normalScale;
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

float luminance(const float3 rgb)
{
    return dot(rgb, float3(0.29891, 0.58661, 0.11448));
}

float3 ambientColor(const float3 direction)
{
    return g_AmbientParam[3].w * saturate(MUL_3X4_ROWS(g_AmbientParam, 0, float4(direction, 1)));
}

float nearestNeighbor64(const float value)
{
    return 0.015625 * (0.5 + floor(64 * value));
}

RemappedTexCoord remapTexCoord(const float2 texCoord, const float rawX, const float remappingParam)
{
    const float sanitizedRemappingParam = clamp(round(remappingParam), -1.0, 1.0);
    const float isLeftSide = step(0.0, rawX);
    const float uFactorAbs = pow(0.5, sanitizedRemappingParam);
    const float uFactorSign = lerp(1.0, -1.0, (1.0 - isLeftSide) * (1.0 - step(abs(sanitizedRemappingParam), 0.0)));
    const float uFactor = uFactorAbs * uFactorSign;
    const float uOffset = lerp(abs(1 - uFactorAbs), 1 - uFactorAbs, isLeftSide);
    const float2 factor = float2(uFactor, 1.0);
    const float2 offset = float2(uOffset, 0.0);

    RemappedTexCoord ret;
    ret.texCoord = frac(texCoord) * factor + offset;
    ret.ddx = ddx(texCoord) * factor;
    ret.ddy = ddy(texCoord) * factor;
    ret.tangentFactor = uFactorSign;
    ret.tangentOffset = (1 - uFactorSign) * 0.5;

    return ret;
}

// screen(x, y) = 1 - (1 - x) * (1 - y) = x + y - x * y = lerp(x, 1, y)

float screen(const float x, const float y)
{
    return x + y - x * y;
}

float2 screen(const float2 x, const float2 y)
{
    return x + y - x * y;
}

float3 screen(const float3 x, const float3 y)
{
    return x + y - x * y;
}

float4 screen(const float4 x, const float4 y)
{
    return x + y - x * y;
}

// Color space conversion

float3 lab2xyz(const float3 lab)
{
    const float y = (lab.x + 16.) / 116.;
    const float3 v = float3(lab.y / 500. + y, y, y - lab.z / 200.);
    const float3 v3 = v * v * v;
    const float3 rawXyz = lerp(v3, (v - 16./116.) / 7.787, step(v3, 0.008856));

    return float3(0.95047, 1.00000, 1.08883) * rawXyz;
}

float3 linRgb2rgb(const float3 linRgb)
{
    return saturate(lerp(1.055 * pow(abs(linRgb), 1./2.4) - 0.055, 12.92 * linRgb, step(linRgb, 0.0031308)));
}

float3 xyz2rgb(const float3 xyz)
{
    return linRgb2rgb(float3(
        dot(xyz, float3( 3.2406, -1.5372, -0.4986)),
        dot(xyz, float3(-0.9689,  1.8758,  0.0415)),
        dot(xyz, float3( 0.0557, -0.2040,  1.0570))
    ));
}

float3 lab2rgb(const float3 lab)
{
    return xyz2rgb(lab2xyz(lab));
}

float3 oklab2rgb(const float3 oklab)
{
    float3 lms = float3(
        dot(oklab, float3(1.0,  0.3963377774,  0.2158037573)),
        dot(oklab, float3(1.0, -0.1055613458, -0.0638541728)),
        dot(oklab, float3(1.0, -0.0894841775, -1.2914855480))
    );

    float3 lms3 = lms * lms * lms;

    return linRgb2rgb(float3(
        dot(lms3, float3( 4.0767416621, -3.3077115913,  0.2309699292)),
		dot(lms3, float3(-1.2684380046,  2.6097574011, -0.3413193965)),
		dot(lms3, float3(-0.0041960863, -0.7034186147,  1.7076147010))
    ));
}
