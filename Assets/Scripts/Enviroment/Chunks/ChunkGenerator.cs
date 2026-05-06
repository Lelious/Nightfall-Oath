using Cysharp.Threading.Tasks;
using LeliousExtentions;
using System.Collections.Generic;
using Unity.AI.Navigation;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.AI;
using UnityEngine.Rendering;
using UnityEngine.ResourceManagement.AsyncOperations;
using Zenject;

public class ChunkGenerator : MonoBehaviour
{
    [SerializeField] private Character _hero;
    [SerializeField] private List<Chunk> _chunks = new();
    [SerializeField] private float _chunkSize = 100f;
    [SerializeField] private Vector3 _origin = new Vector3(-950f, 0f, -950f);
    [SerializeField] private Vector3 _startCoordinate;
    [SerializeField] private int _tileResolution = 64;
    [SerializeField] private NavMeshSurface _surf;
    [SerializeField] private float _detailDist = 10f;
    [SerializeField] private float _zOffset;
    [SerializeField] private float _distanceToRebuild = 120f;
    [SerializeField] private ObjectDatabase _dataBase;

    [Inject]
    private PoolService _poolService;
    private int _sqrtLength;
    private float _distPervertex;
    private bool _chunksRebuild;
    private Vector2 _lastRebuildedPos;
    private NativeArray<ushort> _heightDataNative;
    private bool _inited;

    private void Start()
    {
        Init().Forget();
    }

    private void Update()
    {
        if (!_inited) return;
        if (_chunksRebuild) return;

        if(LeliousMathematic.FlatDistanceGreaterThan(new Vector2(_hero.transform.position.x, _hero.transform.position.z), _lastRebuildedPos, _distanceToRebuild))
        {
            var centerChunk = GetChunkCoord(_hero.transform.position);
            _lastRebuildedPos = GridToWorldPos(centerChunk);
            UpdateChunks(centerChunk).Forget();
        }
    }

    private async UniTaskVoid Init()
    {
        _poolService.InitializePool(_dataBase, 30);

        var handle = Addressables.LoadAssetAsync<TextAsset>("heightmap");
        await handle.Task;

        if (handle.Status != AsyncOperationStatus.Succeeded)
        {
            Debug.LogError("Failed to load heightmap");
            return;
        }

        var bytes = handle.Result.bytes;
        _heightDataNative = HeightmapSerializer.Load(bytes);

        _sqrtLength = Mathf.FloorToInt(Mathf.Sqrt(_heightDataNative.Length));
        _distPervertex = _chunkSize / (_tileResolution - 1);

        Addressables.Release(handle);

        foreach (var chunk in _chunks)
        {
            var filter = chunk.GetComponent<MeshFilter>();
            var mesh = filter.mesh;
            filter.sharedMesh = Instantiate(mesh);
            filter.sharedMesh.MarkDynamic();
            chunk.GridPosition = new Vector2Int(-1, -1);
        }

        var centerChunk = GetChunkCoord(_hero.transform.position);
        await UpdateChunks(centerChunk);
        await UniTask.Delay(100);
        NavMeshHit hit;

        if (NavMesh.SamplePosition(
                _hero.transform.position,
                out hit,
                100f,
                NavMesh.AllAreas))
        {
            _hero.transform.position = hit.position;
            _hero.GetComponent<NavMeshAgent>().Warp(hit.position);
        }

        AssignMapObjects().Forget();
        _inited = true;
        Debug.Log($"{_heightDataNative.Length}");
    }

    private List<Vector2Int> GetSpawnDirections(Vector2Int center)
    {
        List<Vector2Int> spawnPoints = new List<Vector2Int>();

        for (int x = -1; x <= 1; x++)
        {
            for (int y = -1; y <= 1; y++)
            {
                var point = new Vector2Int(center.x + x, center.y + y);
                if (point.x < 0 || point.y - y < 0) continue;

                spawnPoints.Add(point);
            }
        }
        return spawnPoints;
    }

    private Vector2Int GetChunkCoord(Vector3 pos)
    {
        int x = Mathf.FloorToInt((pos.x - _origin.x) / _chunkSize);
        int y = Mathf.FloorToInt((pos.z - _origin.z) / _chunkSize);
        return new Vector2Int(x, y);
    }

    private async UniTask UpdateChunks(Vector2Int centerChunk)
    {
        if (_chunksRebuild) return;
        _chunksRebuild = true;

        var gridPositions = GetSpawnDirections(centerChunk);
        var newPosSet = new HashSet<Vector2Int>(gridPositions);
        var occupied = new HashSet<Vector2Int>();
        var chunksToMove = new List<Chunk>();

        foreach (var chunk in _chunks)
        {
            if (newPosSet.Contains(chunk.GridPosition))
            {
                occupied.Add(chunk.GridPosition);
            }
            else
            {
                chunksToMove.Add(chunk);
            }
        }

        var freePositions = new List<Vector2Int>();

        foreach (var pos in gridPositions)
        {
            if (!occupied.Contains(pos))
            {
                freePositions.Add(pos);
            }
        }

        for (int i = 0; i < freePositions.Count; i++)
        {
            var chunk = chunksToMove[i];
            var newPos = freePositions[i];

            SetChunkToGridPosition(chunk, newPos);
        }

        await DelayedChunkRebuild(chunksToMove);
        _poolService.RemoveNotPersistantFarObjects(new Vector2(_hero.transform.position.x, _hero.transform.position.z), _detailDist * 3f);
    }

    private async UniTask DelayedChunkRebuild(List<Chunk> chunks)
    {
        await UniTask.Yield();

        while (chunks.Count > 0)
        {
            var chunk = chunks[0];
            await InitializeChunk(chunk, chunk.GridPosition);
            chunks.Remove(chunk);
            await UniTask.Delay(100);
        }

        await UniTask.Delay(100);
        await RebuildNavMesh();
    }

    private async UniTask RebuildNavMesh()
    {
        await _surf.UpdateNavMesh(_surf.navMeshData);
        _chunksRebuild = false;
    }

    private Vector2 GridToWorldPos(Vector2Int gridPos)
    {
        return new Vector2(_origin.x + gridPos.x * _chunkSize, _origin.z + gridPos.y * _chunkSize);
    }

    private async UniTask AssignMapObjects()
    {
        List<IMapObject> objToRemove = new();

        while (true)
        {
            objToRemove.Clear();

            foreach (var item in _chunks)
            {
                var info = item.GetChunkObjectsInfoList();

                if (info == null || info.Count == 0) break;

                foreach (var item2 in info)
                {
                    if (LeliousMathematic.FlatDistanceGreaterThan(new Vector2(_hero.transform.position.x, _hero.transform.position.z + _zOffset),
                    new Vector2(item2.Position.x, item2.Position.z), _detailDist))
                    {
                        if(item2.MapObject != null)
                        {
                            objToRemove.Add(item2.MapObject);
                            item2.MapObject = null;
                        }
                    }
                    else
                    {
                        if(item2.MapObject == null)
                        {
                            item2.SetMapObject(_poolService.GetObjectFromPool(item2.Id));
                        }
                    }
                }               
            }

            foreach (var item in objToRemove)
            {
                _poolService.ReturnToPool(item);
            }
            await UniTask.Yield();
        }
    }

    private void SetChunkToGridPosition(Chunk chunk, Vector2Int coord)
    {
        chunk.transform.position = new Vector3(
               _origin.x + coord.x * _chunkSize,
               0f,
               _origin.z + coord.y * _chunkSize
           );

        chunk.GridPosition = coord;
    }

    private async UniTask InitializeChunk(Chunk chunk, Vector2Int chunkPos)
    {
        chunk.transform.position = new Vector3(_origin.x + 100f * chunkPos.x, 0f, _origin.z + 100f * chunkPos.y);

        var job = new ChunkHeightJob
        {
            vertices = chunk.Vertices,
            normals = chunk.Normals,
            heightData = _heightDataNative,
            heightWidth = _sqrtLength,
            heightHeight = _sqrtLength,

            chunkWorldPos = new float3(chunk.transform.position.x, 0f, chunk.transform.position.z),
            origin = new float3(_origin.x, 0f, _origin.z),
            invStep = 1f / _distPervertex
        };

        var locationsHandle = Addressables.LoadResourceLocationsAsync($"Chunk_{chunkPos.x}_{chunkPos.y}");
        await locationsHandle.Task;

        if (locationsHandle.Result == null || locationsHandle.Result.Count == 0)
        {
            Debug.LogWarning($"Asset not found: {$"Chunk_{chunkPos.x}_{chunkPos.y}"}");
            Addressables.Release(locationsHandle);
        }

        var handle = Addressables.LoadAssetAsync<TextAsset>($"Chunk_{chunkPos.x}_{chunkPos.y}");
        await handle.Task;

        if (handle.Status != AsyncOperationStatus.Succeeded)
        {
            Debug.LogError("Failed to load chunk");
        }
        else
        {
            var bytes = handle.Result.bytes;
            chunk.InitializeChunk(BinaryChunkSerializer.Deserialize(bytes));
            Addressables.Release(handle);
        }      

        var jobHandle = job.Schedule(chunk.Vertices.Length, 64);
        await jobHandle.ToUniTask(PlayerLoopTiming.Update);

        ApplyMeshData(chunk);
    }

    private void ApplyMeshData(Chunk chunk)
    {
        var meshDataArray = Mesh.AllocateWritableMeshData(1);
        var meshData = meshDataArray[0];

        meshData.SetVertexBufferParams(
            _tileResolution * _tileResolution,
            new VertexAttributeDescriptor(VertexAttribute.Position),
            new VertexAttributeDescriptor(VertexAttribute.Normal)
        );

        var vertexBuffer = meshData.GetVertexData<Vertex>(0);

        for (int i = 0; i < _tileResolution * _tileResolution; i++)
        {
            vertexBuffer[i] = new Vertex
            {
                position = chunk.Vertices[i],
                normal = chunk.Normals[i]
            };
        }

        meshData.SetIndexBufferParams(chunk.Mesh.triangles.Length, IndexFormat.UInt32);
        var indexBuffer = meshData.GetIndexData<int>();
        indexBuffer.CopyFrom(chunk.Mesh.triangles);

        meshData.subMeshCount = 1;
        meshData.SetSubMesh(0, new SubMeshDescriptor(0, chunk.Mesh.triangles.Length));

        Mesh.ApplyAndDisposeWritableMeshData(meshDataArray, chunk.Mesh);
        chunk.Mesh.RecalculateBounds();
        chunk.AssignMesh();
    }
}
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
