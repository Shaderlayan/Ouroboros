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
