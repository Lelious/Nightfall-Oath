using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;

[BurstCompile]
public struct ChunkHeightJob : IJobParallelFor
{
    [ReadOnly] public NativeArray<ushort> heightData;

    public NativeArray<float3> vertices;
    public NativeArray<float3> normals;

    public int heightWidth;
    public int heightHeight;

    public float3 chunkWorldPos;
    public float3 origin;
    public float invStep;

    private const float _heightScale = 300f / 65535f;
    public void Execute(int index)
    {
        float3 v = vertices[index];

        float worldX = v.x + chunkWorldPos.x;
        float worldZ = v.z + chunkWorldPos.z;

        int x = (int)math.floor((worldX - origin.x) * invStep);
        int z = (int)math.floor((worldZ - origin.z) * invStep);

        x = math.clamp(x, 0, heightWidth - 1);
        z = math.clamp(z, 0, heightHeight - 1);
        int idx = x + z * heightWidth;

        v.y = heightData[idx] * _heightScale;
        vertices[index] = v;

        float hL = heightData[math.max(idx - 1, 0)] * _heightScale;
        float hR = heightData[math.min(idx + 1, heightData.Length - 1)] * _heightScale;
        float hD = heightData[math.max(idx - heightWidth, 0)] * _heightScale;
        float hU = heightData[math.min(idx + heightWidth, heightData.Length - 1)] * _heightScale;

        float3 normal = math.normalize(new float3(hL - hR, 2f, hD - hU));
        normals[index] = normal;
    }
}
