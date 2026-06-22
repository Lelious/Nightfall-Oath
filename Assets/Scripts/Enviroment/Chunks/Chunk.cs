using Cysharp.Threading.Tasks;
using System;
using System.Collections.Generic;
using Unity.Collections;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.ResourceManagement.AsyncOperations;

public class Chunk : MonoBehaviour, IDisposable
{
    [SerializeField] private MeshFilter _meshFilter;
    [HideInInspector] public Mesh Mesh;

    public Vector2Int GridPosition;
    public Vector2Int OldGridPosition;
    public NativeArray<float3> Vertices;
    public NativeArray<float3> Normals;

    private List<MapObjectInfo> _chunkObjectsInfo;

    public void CreateChunkData()
    {
        var verts = Mesh.vertices;
        int count = verts.Length;

        Vertices = new NativeArray<float3>(count, Allocator.Persistent);
        Normals = new NativeArray<float3>(count, Allocator.Persistent);

        for (int i = 0; i < count; i++)
        {
            Vertices[i] = verts[i];
        }
    }

    public void AssignMesh() => _meshFilter.mesh = Mesh;
    public List<MapObjectInfo> GetChunkObjectsInfoList() => _chunkObjectsInfo;

    public void InitializeChunk(List<MapObjectInfo> chunkObjects) 
    {
        if (_chunkObjectsInfo == null)
            _chunkObjectsInfo = new List<MapObjectInfo>(100);
        else
            _chunkObjectsInfo.Clear();

        foreach (var item in chunkObjects)
        {
            _chunkObjectsInfo.Add(item);
        }
    }

    public void Dispose()
    {
        if (Vertices.IsCreated)
            Vertices.Dispose();
        if (Normals.IsCreated)
            Normals.Dispose();
    }
}