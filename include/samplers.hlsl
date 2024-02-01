struct RemappedTexCoord
{
    float2 texCoord;
    float2 ddx;
    float2 ddy;
    float tangentFactor;
    float tangentOffset;
};

struct GameSampler2D4
{
    SamplerState S;
    Texture2D<float4> T;

    float4 Sample(float2 texCoord)
    {
        return T.Sample(S, texCoord);
    }

    float4 SampleLevel(float2 texCoord, float level)
    {
        return T.SampleLevel(S, texCoord, level);
    }

    float4 SampleGrad(float2 texCoord, float2 ddx, float2 ddy)
    {
        return T.SampleGrad(S, texCoord, ddx, ddy);
    }

    float4 SampleRemapped(RemappedTexCoord remapped)
    {
        return SampleGrad(remapped.texCoord, remapped.ddx, remapped.ddy);
    }
};

struct GameSampler3D4
{
    SamplerState S;
    Texture3D<float4> T;

    float4 Sample(float3 texCoord)
    {
        return T.Sample(S, texCoord);
    }

    float4 SampleLevel(float3 texCoord, float level)
    {
        return T.SampleLevel(S, texCoord, level);
    }
};

struct GameSamplerCube4
{
    SamplerState S;
    TextureCube<float4> T;

    float4 Sample(float3 texCoord)
    {
        return T.Sample(S, texCoord);
    }

    float4 SampleLevel(float3 texCoord, float level)
    {
        return T.SampleLevel(S, texCoord, level);
    }
};

struct NormalSampler : GameSampler2D4
{
    float4 SampleRemapped(RemappedTexCoord remapped)
    {
        return GameSampler2D4::SampleRemapped(remapped) * float4(remapped.tangentFactor, 1, 1, 1) + float4(remapped.tangentOffset, 0, 0, 0);
    }
};
