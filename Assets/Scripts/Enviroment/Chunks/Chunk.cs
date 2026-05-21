using Cysharp.Threading.Tasks;
using System.Collections.Generic;
using Unity.Collections;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.AI;
using UnityEngine.ResourceManagement.AsyncOperations;

public class Chunk : MonoBehaviour
{
    [SerializeField] private MeshFilter _meshFilter;
    [HideInInspector] public Mesh Mesh;

    public Vector2Int GridPosition;
    public NativeArray<float3> Vertices;
    public NativeArray<float3> Normals;

    private List<MapObjectInfo> _chunkObjectsInfo;
    private AsyncOperationHandle<Mesh> _navigationMeshHandle;

    private void Start()
    {
        Mesh mesh = Instantiate(_meshFilter.sharedMesh);
        _meshFilter.mesh = mesh;
        mesh.MarkDynamic();
        mesh.UploadMeshData(false);
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

    public void AssignMesh() => _meshFilter.mesh = Mesh;
    public List<MapObjectInfo> GetChunkObjectsInfoList() => _chunkObjectsInfo;

    public async UniTask InitializeChunk(List<MapObjectInfo> chunkObjects) 
    {
        _chunkObjectsInfo = chunkObjects;

        if (_navigationMeshHandle.IsValid())
            Addressables.Release(_navigationMeshHandle);

        var locationsHandle = Addressables.LoadResourceLocationsAsync($"ChunkNav_{GridPosition.x}_{GridPosition.y}");
        await locationsHandle.ToUniTask();

        if (locationsHandle.Status == AsyncOperationStatus.Succeeded &&
                locationsHandle.Result != null &&
                locationsHandle.Result.Count > 0)
        {
            _navigationMeshHandle = Addressables.LoadAssetAsync<Mesh>($"ChunkNav_{GridPosition.x}_{GridPosition.y}");
            await _navigationMeshHandle.ToUniTask();
        }
        Addressables.Release(locationsHandle);
    }

    public void FillNavSource(List<NavMeshBuildSource> sources)
    {
        if (_navigationMeshHandle.IsValid() &&
        _navigationMeshHandle.Status == AsyncOperationStatus.Succeeded)
        {
            Mesh mesh = _navigationMeshHandle.Result;
            sources.Add(new NavMeshBuildSource
            {
                shape = NavMeshBuildSourceShape.Mesh,
                sourceObject = mesh,
                transform = transform.localToWorldMatrix,
                area = 0
            });
        }

    }
}