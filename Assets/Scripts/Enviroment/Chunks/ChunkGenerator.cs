using Cysharp.Threading.Tasks;
using LeliousExtentions;
using System;
using System.Collections.Generic;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.AI;
using UnityEngine.Rendering;
using UnityEngine.ResourceManagement.AsyncOperations;
using Zenject;

public class ChunkGenerator : MonoBehaviour, IDisposable
{
    [SerializeField] private float _chunkSize = 100f;
    [SerializeField] private Vector3 _origin = new Vector3(-950f, 0f, -950f);
    [SerializeField] private Vector3 _startCoordinate;
    [SerializeField] private int _tileResolution = 64;
    [SerializeField] private float _detailDist = 10f;
    [SerializeField] private float _zOffset;
    [SerializeField] private float _distanceToRebuild = 120f;

    private Dictionary<Vector2Int, RuntimeChunkData> _runtimeDataDict;
    private List<NavMeshBuildSource> _globalNavigationSourcesList;
    private readonly List<GameObject> _spawnedChunks = new();
    private NativeArray<ushort> _heightDataNative;
    private NavMeshBuilderService _navMeshBuilder;
    private List<IMapObject> _activeObjects;
    private List<Chunk> _chunks = new();
    private HashSet<Chunk> _dirtyChunks;
    private EnemyFactory _enemyFactory;
    private Vector2 _lastRebuildedPos;
    private PoolService _poolService;
    private Transform _worldParent;
    private float _distPervertex;
    private bool _chunksRebuild;
    private Character _hero;
    private int _sqrtLength;
    private bool _inited;

    [Inject]
    public void Construct(Character hero, PoolService poolService, NavMeshBuilderService navMeshBuilder, EnemyFactory enemyFactory)
    {
        _navMeshBuilder = navMeshBuilder;
        _enemyFactory = enemyFactory;
        _poolService = poolService;
        _hero = hero;

        Init().Forget();
    }

    private async UniTaskVoid UpdateFunc()
    {
        while (true)
        {
            await UniTask.Delay(1000);

            if (_inited && !_chunksRebuild)
            {
                var heroPos = new Vector2(_hero.transform.position.x, _hero.transform.position.z);
                if (LeliousMathematic.FlatDistanceGreaterThan(heroPos, _lastRebuildedPos, _distanceToRebuild))
                {
                    var centerChunk = GetChunkCoord(_hero.transform.position);
                    _lastRebuildedPos = heroPos;
                    UpdateChunks(centerChunk).Forget();
                }
            }

            if(!_chunksRebuild)
            {
                FillGlobalNavigation();
                await RebuildNavMesh(_hero.transform.position);
            }
        } 
    }

    private async UniTaskVoid Init()
    {
        _worldParent = new GameObject("World").transform;

        await CreateChunks();
        await _poolService.InitializePool(30, _worldParent);

        _globalNavigationSourcesList = new();
        _runtimeDataDict = new();
        _dirtyChunks = new();
        _activeObjects = new();

        var handle = Addressables.LoadAssetAsync<TextAsset>("heightmap");
        await handle.ToUniTask();

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
            chunk.Mesh = filter.sharedMesh;
            chunk.GridPosition = new Vector2Int(-1, -1);
            chunk.CreateChunkData();
        }

        var centerChunk = GetChunkCoord(_hero.transform.position);

        await UpdateChunks(centerChunk);
        await UniTask.Yield();
        FillGlobalNavigation();
        await RebuildNavMesh(_hero.transform.position);
        await UniTask.Yield();

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
        UpdateFunc().Forget();
    }

    private async UniTask CreateChunks()
    {
        List<UniTask<GameObject>> spawnTasks = new List<UniTask<GameObject>>();

        for (int i = 0; i < 9; i++)
        {
            var task = Addressables.InstantiateAsync(
                AssetPath.Chunk,
                Vector3.zero,
                Quaternion.identity,
                _worldParent
            ).ToUniTask();

            spawnTasks.Add(task);
        }

        GameObject[] loadedChunks = await UniTask.WhenAll(spawnTasks);

        _spawnedChunks.AddRange(loadedChunks);

        foreach (var item in loadedChunks)
        {
            _chunks.Add(item.GetComponent<Chunk>());
        }
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
        _globalNavigationSourcesList.Clear();
        _dirtyChunks.Clear();

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

        if(chunksToMove.Count == 0)
        {
            _chunksRebuild = false;
            return;
        }
        
        _chunksRebuild = false;
    }

    private async UniTask DelayedChunkRebuild(List<Chunk> chunks)
    {
        await UniTask.Yield();

        foreach (var chunk in chunks)
        {
            await InitializeChunk(chunk, chunk.GridPosition);
            await UniTask.Yield();
        }     
    }

    private async UniTask RebuildNavMesh(Vector3 chunkPos)
    {
        await _navMeshBuilder.RebuildNavMeshData(_globalNavigationSourcesList, chunkPos);
    }

    private async UniTask AssignMapObjects()
    {
        List<IMapObject> objToRemove = new();
        while (true)
        {
            objToRemove.Clear();
            foreach (var item in _chunks)
            {
                Vector2 heroPos = new Vector2(_hero.transform.position.x, _hero.transform.position.z + _zOffset);

                var staticInfo = item.GetChunkObjectsInfoList();
                if (staticInfo != null && staticInfo.Count > 0)
                {
                    foreach (var item2 in staticInfo)
                    {
                        Vector3 staticPos = item2.MapObject != null ? item2.MapObject.Position() : item2.Position;

                        if (LeliousMathematic.FlatDistanceGreaterThan(heroPos, new Vector2(staticPos.x, staticPos.z), _detailDist))
                        {
                            if (item2.MapObject != null)
                            {
                                objToRemove.Add(item2.MapObject);
                                _activeObjects.Remove(item2.MapObject);
                                item2.MapObject = null;
                            }
                        }
                        else
                        {
                            if (item2.MapObject == null)
                            {
                                var obj = _poolService.GetObjectFromPool(item2.Id);
                                item2.SetMapObject(obj);
                                _activeObjects.Add(obj);
                            }
                        }
                    }
                }

                if (_runtimeDataDict.TryGetValue(item.GridPosition, out var runtimeChunk))
                {
                    var creatures = runtimeChunk.RuntimeObjects.ToArray();
                    foreach (var item2 in creatures)
                    {
                        if (!item2.Alive) continue;

                        Vector3 enemyPos = item2.DynamicObject.MapObject != null
                            ? item2.DynamicObject.MapObject.Position()
                            : item2.DynamicObject.Position;

                        if (item2.DynamicObject.MapObject != null)
                        {
                            Vector2Int currentActualChunk = GetChunkCoord(enemyPos);

                            if (currentActualChunk != item.GridPosition)
                            {
                                item2.DynamicObject.Position = enemyPos;
                                Debug.Log($"Migrate to {currentActualChunk}");
                                MigrateCreatureToNewChunk(item.GridPosition, currentActualChunk, item2);

                                continue;
                            }
                        }
                        if (LeliousMathematic.FlatDistanceGreaterThan(heroPos, new Vector2(enemyPos.x, enemyPos.z), _detailDist))
                        {
                            if (item2.DynamicObject.MapObject != null)
                            {
                                item2.DynamicObject.Position = enemyPos;

                                _enemyFactory.DestroyEnemy(item2.DynamicObject.MapObject as IMapCreature);
                                item2.DynamicObject.MapObject = null;
                            }
                        }
                        else
                        {
                            if (item2.DynamicObject.MapObject == null)
                            {
                                var creatureGo = _poolService.GetObjectFromPool(item2.DynamicObject.Id);
                                item2.DynamicObject.SetMapObject(creatureGo);
                                await _enemyFactory.CreateEnemy(creatureGo as IMapCreature, item2.DynamicObject);
                                item2.DynamicObject.MapObject = creatureGo;
                            }
                        }
                    }
                }

                await UniTask.Yield();
            }

            foreach (var item in objToRemove)
            {
                _poolService.ReturnToPool(item);
            }
            await UniTask.Yield();
        }
    }

    private void MigrateCreatureToNewChunk(Vector2Int oldChunkPos, Vector2Int newChunkPos, RuntimeChunkObject obj)
    {
        if (_runtimeDataDict.TryGetValue(oldChunkPos, out var oldChunk))
        {
            oldChunk.RuntimeObjects.Remove(obj);
        }

        if (!_runtimeDataDict.ContainsKey(newChunkPos))
        {
            _runtimeDataDict[newChunkPos] = new RuntimeChunkData(new List<MapCreatureInfo>());
        }

        _runtimeDataDict[newChunkPos].RuntimeObjects.Add(obj);
    }

    private void FillGlobalNavigation()
    {
        _globalNavigationSourcesList.Clear();

        foreach (var obj in _activeObjects)
        {
            if(obj is IMapNavigation navigation)
            {
                if(navigation.HasNavigationMeshes())
                {
                    navigation.FillNavSources(_globalNavigationSourcesList);
                }
            }
        }

        foreach (var item in _chunks)
        {
            item.FillNavSource(_globalNavigationSourcesList);
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
        chunk.transform.position = new Vector3(_origin.x + (100f * chunkPos.x) + 50f, 0f, _origin.z + (100f * chunkPos.y) + 50f);

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
        await locationsHandle.ToUniTask();

        if (locationsHandle.Status == AsyncOperationStatus.Succeeded &&
                locationsHandle.Result != null &&
                locationsHandle.Result.Count > 0)
        {                      
            var handle = Addressables.LoadAssetAsync<TextAsset>($"Chunk_{chunkPos.x}_{chunkPos.y}");
            await handle.ToUniTask();

            if (handle.Status != AsyncOperationStatus.Succeeded)
            {
                Debug.LogError("Failed to load chunk");
            }
            else
            {
                var bytes = handle.Result.bytes;
                var allData = BinaryChunkSerializer.Deserialize(bytes);
                var staticData = new List<MapObjectInfo>();
                var dynamicData = new List<MapCreatureInfo>();

                Addressables.Release(handle);

                foreach (var item in allData)
                {
                    if (item is MapCreatureInfo creature)
                    {
                        dynamicData.Add(creature);
                    }
                    else
                    {
                        staticData.Add(item);
                    }
                }

                await chunk.InitializeChunk(staticData);

                if (!_runtimeDataDict.ContainsKey(chunkPos))
                {
                    _runtimeDataDict[chunkPos] = new RuntimeChunkData(dynamicData);
                }
            }
        }
        
        Addressables.Release(locationsHandle);

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

    public void Dispose()
    {
        foreach (var chunk in _spawnedChunks)
        {
            if (chunk != null)
            {
                Addressables.ReleaseInstance(chunk);
            }
        }

        _spawnedChunks.Clear();
    }
}