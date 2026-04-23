using System.Collections.Generic;
using Unity.Collections;
using Unity.Mathematics;
using UnityEngine;

public class Chunk : MonoBehaviour
{
    [SerializeField] private MeshFilter _meshFilter;
    [HideInInspector] public Mesh Mesh;

    public Vector2Int GridPosition;
    public NativeArray<float3> Vertices;
    public NativeArray<float3> Normals;

    private List<IMapObject> _chunkObjects = new();

    private void Start()
    {
        Mesh mesh = Instantiate(_meshFilter.sharedMesh);
        _meshFilter.mesh = mesh;
        mesh.MarkDynamic();
        Mesh = mesh;

        var verts = Mesh.vertices;
        int count = verts.Length;

        Vertices = new NativeArray<float3>(count, Allocator.Persistent);
        Normals = new NativeArray<float3>(count, Allocator.Persistent);

        for (int i = 0; i < count; i++)
        {
            Vertices[i] = verts[i];
        }
    }

    public void AssignMesh()
    {
        _meshFilter.mesh = Mesh;
    }

    public void UpdateChunkObjects(Vector2 heroPosition)
    {

    }

    public void InitializeChunk()
    {

    }
}