using Unity.Mathematics;

public struct Vertex
{
    public float3 position;
    public float3 normal;

    public Vertex(float3 position, float3 normal)
    {
        this.position = position;
        this.normal = normal;
    }
}
