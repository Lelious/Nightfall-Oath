using Cysharp.Threading.Tasks;
using LeliousExtentions;
using System;
using System.Collections.Generic;
using System.Threading;
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
    private Vector3 _origin = new Vector3(-1000f, 0f, -1000f);
    [SerializeField] private int _tileResolution = 64;
    [SerializeField] private float _detailDist = 50f;
    [SerializeField] private float _zOffset;
    [SerializeField] private float _distanceToRebuild = 120f;

    private readonly List<IMapObject> _objToRemove = new();
    private readonly List<MapCreatureInfo> _cachedDynamicData = new List<MapCreatureInfo>(128);
    [SerializeField] private List<MapObjectInfo> _cachedStaticData = new List<MapObjectInfo>(128);
    private readonly List<MapObjectInfo> _cachedInteractiveData = new List<MapObjectInfo>(128);

    private Dictionary<Vector2Int, RuntimeChunkData> _runtimeDataDict;
    private Dictionary<Vector2Int, NavMeshBuildSource> _globalNavigationSources;
    private Dictionary<Vector2Int, AsyncOperationHandle> _loadedNavMeshHandles;
    private readonly List<GameObject> _spawnedChunks = new();
    private WorldGraphicStreamService _graphicStreamService;
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
    public void Construct(Character hero, PoolService poolService, NavMeshBuilderService navMeshBuilder, EnemyFactory enemyFactory, WorldGraphicStreamService graphicService)
    {
        _graphicStreamService = graphicService;
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
        }
    }

    private async UniTaskVoid Init()
    {
        _worldParent = new GameObject("World").transform;

        await CreateChunks();
        await _poolService.InitializePool(30, _worldParent);

        _globalNavigationSources = new(9);
        _loadedNavMeshHandles = new(9);
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
            chunk.OldGridPosition = new Vector2Int(-1, -1);
            chunk.CreateChunkData();
        }

        var centerChunk = GetChunkCoord(_hero.transform.position);

        await UpdateChunks(centerChunk);
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
        await RebuildNavMesh(_hero.transform.position);
        _poolService.RemoveNotPersistantFarObjects(new Vector2(_hero.transform.position.x, _hero.transform.position.z), _detailDist * 3f);

        if (chunksToMove.Count == 0)
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
            await InitializeChunk(chunk);
            await UniTask.Yield();
        }
    }

    private async UniTask RebuildNavMesh(Vector3 chunkPos)
    {
        await _navMeshBuilder.RebuildNavMeshData(_globalNavigationSources, chunkPos);
    }

    private async UniTask AssignMapObjects()
    {
        while (true)
        {
            _objToRemove.Clear();
            Vector2 heroPos = new Vector2(_hero.transform.position.x, _hero.transform.position.z + _zOffset);

            foreach (var item in _chunks)
            {
                var chunkInfo = item.GetChunkObjectsInfoList();
                if (chunkInfo != null && chunkInfo.Count > 0)
                {
                    foreach (var item2 in chunkInfo)
                    {
                        Vector3 itemPos = item2.MapObject != null ? item2.MapObject.Position() : item2.Position;

                        switch (item2.Type)
                        {
                            case MapObjectType.StaticDecoration:
                                if (LeliousMathematic.FlatDistanceGreaterThan(heroPos, new Vector2(itemPos.x, itemPos.z), _detailDist))
                                {
                                    if(item2.Initialized)
                                    {
                                        _graphicStreamService.UnregisterObject(item2.Id, itemPos, item2.Rotation, item2.Scale);
                                        item2.Initialized = false;
                                    }
                                }
                                else
                                {
                                    if(!item2.Initialized)
                                    {
                                        _graphicStreamService.RegisterObject(item2.Id, itemPos, item2.Rotation, item2.Scale);
                                        item2.Initialized = true;
                                    }
                                }
                                break;

                            case MapObjectType.Interactive:
                                if (LeliousMathematic.FlatDistanceGreaterThan(heroPos, new Vector2(itemPos.x, itemPos.z), _detailDist))
                                {
                                    if (item2.MapObject != null)
                                    {
                                        _objToRemove.Add(item2.MapObject);
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

                                        if (_runtimeDataDict.TryGetValue(item.GridPosition, out var runtimeChunk2))
                                        {
                                            var savedState = runtimeChunk2.RuntimeInteractiveObjects.Find(x => x.TargetObject == item2);

                                            if (savedState != null)
                                            {
                                                //if (obj is IInteractiveObject interactiveComponent)
                                                //{
                                                //    interactiveComponent.ApplyRuntimeState(savedState);
                                                //}
                                            }
                                        }
                                    }
                                }
                                break;
                            default:
                                break;
                        }
                    }
                }

                if (_runtimeDataDict.TryGetValue(item.GridPosition, out var runtimeChunkData))
                {
                    for (int i = runtimeChunkData.RuntimeDynamicObjects.Count - 1; i >= 0; i--)
                    {
                        var item2 = runtimeChunkData.RuntimeDynamicObjects[i];

                        if (!item2.Alive) continue;

                        var creatureInfo = item2.CreatureInfo;

                        Vector3 enemyPos = creatureInfo.MapObject != null
                            ? creatureInfo.MapObject.Position()
                            : creatureInfo.Position;

                        if (creatureInfo.MapObject != null)
                        {
                            Vector2Int currentActualChunk = GetChunkCoord(enemyPos);

                            if (currentActualChunk != item.GridPosition)
                            {
                                creatureInfo.Position = enemyPos;
                                Debug.Log($"Migrate to {currentActualChunk}");
                                MigrateCreatureToNewChunk(item.GridPosition, currentActualChunk, item2);
                                continue;
                            }
                        }

                        if (LeliousMathematic.FlatDistanceGreaterThan(heroPos, new Vector2(enemyPos.x, enemyPos.z), _detailDist))
                        {
                            if (creatureInfo.MapObject != null)
                            {
                                creatureInfo.Position = enemyPos;
                                _enemyFactory.DestroyEnemy(creatureInfo.MapObject as IMapCreature);
                                creatureInfo.MapObject = null;
                            }
                        }
                        else
                        {
                            if (creatureInfo.MapObject == null)
                            {
                                var creatureGo = _poolService.GetObjectFromPool(creatureInfo.Id);
                                creatureInfo.SetMapObject(creatureGo);
                                await _enemyFactory.CreateEnemy(creatureGo as IMapCreature, creatureInfo);
                                creatureInfo.MapObject = creatureGo;
                            }
                        }
                    }
                }

                await UniTask.Yield(PlayerLoopTiming.Update);
            }

            foreach (var item in _objToRemove)
            {
                _poolService.ReturnToPool(item);
            }

            await UniTask.Yield(PlayerLoopTiming.Update);
        }
    }

    private void MigrateCreatureToNewChunk(Vector2Int oldChunkPos, Vector2Int newChunkPos, RuntimeChunkObject obj)
    {
        if (_runtimeDataDict.TryGetValue(oldChunkPos, out var oldChunk))
        {
            oldChunk.RuntimeDynamicObjects.Remove((RuntimeCreatureState)obj);
        }

        if (!_runtimeDataDict.ContainsKey(newChunkPos))
        {
            _runtimeDataDict[newChunkPos] = new RuntimeChunkData(new List<MapCreatureInfo>(), new List<MapObjectInfo>());
        }

        _runtimeDataDict[newChunkPos].RuntimeDynamicObjects.Add((RuntimeCreatureState)obj);
    }

    private void SetChunkToGridPosition(Chunk chunk, Vector2Int coord)
    {
        chunk.OldGridPosition = chunk.GridPosition;
        chunk.GridPosition = coord;

        chunk.transform.position = new Vector3(_origin.x + (100f * chunk.GridPosition.x) + 50f, 0f, _origin.z + (100f * chunk.GridPosition.y) + 50f);
    }

    private async UniTask InitializeChunk(Chunk chunk)
    {
        if (!chunk.OldGridPosition.Equals(new Vector2Int(-1, -1)))
        {
            if (_loadedNavMeshHandles.TryGetValue(chunk.OldGridPosition, out var oldHandle))
            {
                Addressables.Release(oldHandle);
                _loadedNavMeshHandles.Remove(chunk.OldGridPosition);
            }
            _globalNavigationSources.Remove(chunk.OldGridPosition);
        }

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

        var locationsHandle = Addressables.LoadResourceLocationsAsync($"Chunk_{chunk.GridPosition.x}_{chunk.GridPosition.y}");
        await locationsHandle.ToUniTask();

        if (locationsHandle.Status == AsyncOperationStatus.Succeeded &&
                locationsHandle.Result != null &&
                locationsHandle.Result.Count > 0)
        {
            var handle = Addressables.LoadAssetAsync<TextAsset>($"Chunk_{chunk.GridPosition.x}_{chunk.GridPosition.y}");
            await handle.ToUniTask();

            if (handle.Status != AsyncOperationStatus.Succeeded)
            {
                Debug.LogError($"Failed to load chunk asset at {chunk.GridPosition}");
                Addressables.Release(locationsHandle);
                return;
            }

            var bytes = handle.Result.bytes;
            var allData = BinaryChunkSerializer.Deserialize(bytes);

            _cachedStaticData.Clear();
            _cachedDynamicData.Clear();
            _cachedInteractiveData.Clear();

            Addressables.Release(handle);

            foreach (var item in allData)
            {
                switch (item.Type)
                {
                    case MapObjectType.StaticDecoration:
                        _cachedStaticData.Add(item);
                        break;
                    case MapObjectType.Creature:
                        _cachedDynamicData.Add((MapCreatureInfo)item);
                        break;
                    case MapObjectType.Interactive:
                        _cachedInteractiveData.Add(item);
                        break;
                    default:
                        break;
                }
            }

            chunk.InitializeChunk(_cachedStaticData);

            if (!_runtimeDataDict.ContainsKey(chunk.GridPosition))
            {
                _runtimeDataDict[chunk.GridPosition] = new RuntimeChunkData(_cachedDynamicData, _cachedInteractiveData);
            }
        }

        Addressables.Release(locationsHandle);

        var jobHandle = job.Schedule(chunk.Vertices.Length, 64);
        await jobHandle.ToUniTask(PlayerLoopTiming.Update);

        ApplyMeshData(chunk);

        var navigationHandle = Addressables.LoadResourceLocationsAsync($"ChunkNav_{chunk.GridPosition.x}_{chunk.GridPosition.y}");
        await navigationHandle.ToUniTask();

        if (navigationHandle.Status == AsyncOperationStatus.Succeeded &&
                navigationHandle.Result != null &&
                navigationHandle.Result.Count > 0)
        {
            var handle = Addressables.LoadAssetAsync<Mesh>($"ChunkNav_{chunk.GridPosition.x}_{chunk.GridPosition.y}");
            await handle.ToUniTask();

            if (handle.Status != AsyncOperationStatus.Succeeded)
            {
                Debug.LogError($"Failed to load chunk navmesh at {chunk.GridPosition}");
                Addressables.Release(navigationHandle);
            }
            else
            {
                _loadedNavMeshHandles[chunk.GridPosition] = handle;

                Mesh navMesh = handle.Result;
                NavMeshBuildSource source = new NavMeshBuildSource
                {
                    shape = NavMeshBuildSourceShape.Mesh,
                    sourceObject = navMesh,
                    transform = Matrix4x4.TRS(chunk.transform.position, Quaternion.identity, Vector3.one),
                    area = 0
                };

                _globalNavigationSources[chunk.GridPosition] = source;
                Addressables.Release(navigationHandle);
            }
        }
        else
        {
            Addressables.Release(navigationHandle);
        }
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