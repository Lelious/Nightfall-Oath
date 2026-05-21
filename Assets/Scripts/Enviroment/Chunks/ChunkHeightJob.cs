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

        int x = (int)math.round((worldX - origin.x) * invStep);
        int z = (int)math.round((worldZ - origin.z) * invStep);

        x = math.clamp(x, 0, heightWidth - 1);
        z = math.clamp(z, 0, heightHeight - 1);
        int idx = x + z * heightWidth;

        v.y = heightData[idx] * _heightScale;
        vertices[index] = v;

        int xL = math.max(x - 1, 0);
        int xR = math.min(x + 1, heightWidth - 1);
        int zD = math.max(z - 1, 0);
        int zU = math.min(z + 1, heightHeight - 1);

        float hL = heightData[xL + z * heightWidth] * _heightScale;
        float hR = heightData[xR + z * heightWidth] * _heightScale;
        float hD = heightData[x + zD * heightWidth] * _heightScale;
        float hU = heightData[x + zU * heightWidth] * _heightScale;

        float stepMeter = 1f / invStep;
        float3 normal = math.normalize(new float3(hL - hR, 2f * stepMeter, hD - hU));
        normals[index] = normal;
    }
}
