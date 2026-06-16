using Cysharp.Threading.Tasks;
using System.Collections.Generic;
using Unity.AI.Navigation;
using UnityEngine;
using UnityEngine.AI;

public class NavMeshBuilderService : MonoBehaviour
{
    [SerializeField] private NavMeshSurface _navMeshSurface;

    private readonly List<NavMeshBuildSource> _cachedSourcesList = new List<NavMeshBuildSource>(9);
    private NavMeshBuildSettings _settings;
    private NavMeshData _navMeshData;
    private NavMeshDataInstance _instance;
    private bool _onRebuild;

    private void Awake()
    {
        _navMeshData = new();
        _settings = NavMesh.GetSettingsByID(0);
        _settings.overrideTileSize = true;
        _settings.tileSize = 64;

        _settings.overrideVoxelSize = true;
        _settings.voxelSize = 0.45f;

        _settings.buildHeightMesh = false;
        _settings.minRegionArea = 3.0f;

        _settings.maxJobWorkers = (uint)Mathf.Max(1, SystemInfo.processorCount - 2);
    }

    public async UniTask RebuildNavMeshData(Dictionary<Vector2Int, NavMeshBuildSource> chunkSources, Vector3 center)
    {
        if (_onRebuild) return;
        _onRebuild = true;

        try
        {
            _cachedSourcesList.Clear();
            foreach (var source in chunkSources.Values)
            {
                _cachedSourcesList.Add(source);
            }

            Bounds bounds = new Bounds(center, Vector3.one * 300f);

            var asyncOp = NavMeshBuilder.UpdateNavMeshDataAsync(_navMeshData, _settings, _cachedSourcesList, bounds);

            while (!asyncOp.isDone)
            {
                await UniTask.Yield(PlayerLoopTiming.Update);
            }

            await UniTask.Yield(PlayerLoopTiming.Update);

            if (_instance.valid) _instance.Remove();
            _instance = NavMesh.AddNavMeshData(_navMeshData);
        }
        finally
        {
            _onRebuild = false;
        }
    }

    private List<Bounds> SplitBounds(Vector3 center, Vector3 totalSize, int divisions)
    {
        List<Bounds> boundsList = new List<Bounds>();
        Vector3 subSize = new Vector3(totalSize.x / divisions, totalSize.y, totalSize.z / divisions);
        Vector3 startPos = center - (totalSize / 2f) + (subSize / 2f);

        for (int x = 0; x < divisions; x++)
        {
            for (int z = 0; z < divisions; z++)
            {
                Vector3 subCenter = startPos + new Vector3(x * subSize.x, 0, z * subSize.z);
                boundsList.Add(new Bounds(subCenter, subSize));
            }
        }
        return boundsList;
    }
}
