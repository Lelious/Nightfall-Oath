using Cysharp.Threading.Tasks;
using System.Collections.Generic;
using Unity.AI.Navigation;
using UnityEngine;
using UnityEngine.AI;

public class NavMeshBuilderService : MonoBehaviour
{
    [SerializeField] private NavMeshSurface _navMeshSurface;

    private NavMeshBuildSettings _settings;
    private NavMeshData _navMeshData;
    private NavMeshDataInstance _instance;
    private bool _onRebuild;

    private void Awake()
    {
        _navMeshData = new();
        _settings = NavMesh.GetSettingsByID(0);
    }

    public async UniTask RebuildNavMeshData(List<NavMeshBuildSource> chunkSources, Vector3 center)
    {
        Debug.Log("UpdatingNav");
        if (_onRebuild) return;

        _onRebuild = !_onRebuild;

        Bounds worldBounds = new Bounds(center, new Vector3(50, 50, 50));

        await NavMeshBuilder.UpdateNavMeshDataAsync(_navMeshData, _settings, chunkSources, worldBounds).ToUniTask();

        if (_instance.valid) _instance.Remove();

        _instance = NavMesh.AddNavMeshData(_navMeshData);

        _onRebuild = !_onRebuild;
    }
}
