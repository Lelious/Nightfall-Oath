using Cysharp.Threading.Tasks;
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.Rendering;
using Zenject;

public class WorldGraphicStreamService : IInitializable, IDisposable
{
    private Dictionary<ushort, Dictionary<int, InstanceBuffer>> _masterRenderQueue;
    private Dictionary<ushort, MeshData> _configIdCache;
    private Dictionary<Mesh, Material[]> _meshMaterialCache;
    private Dictionary<ushort, Mesh> _loadedMeshes = new();
    private Dictionary<ushort, int> _meshRefCount = new();
    private HashSet<ushort> _meshesInLoadingProgress = new HashSet<ushort>();
    private MeshMaterialConfig _meshConfig;
    private bool _isConfigLoaded;
    private const int INSTANCE_BUFFER_MAX_SIZE = 200;

    public void Initialize()
    {
        _masterRenderQueue = new Dictionary<ushort, Dictionary<int, InstanceBuffer>>();
        _meshMaterialCache = new Dictionary<Mesh, Material[]>();
        _loadedMeshes = new Dictionary<ushort, Mesh>();
        _meshRefCount = new Dictionary<ushort, int>();
        _meshesInLoadingProgress = new();

        RenderPipelineManager.beginCameraRendering += OnBeginCameraRendering;
        LoadConfigAsync().Forget();
    }

    public void OnBeginCameraRendering(ScriptableRenderContext context, Camera camera)
    {
        if (camera.cameraType == CameraType.Preview || camera.cameraType == CameraType.Reflection) return;
        if (!_isConfigLoaded) return;

        RenderQueues();    
    }

    public void RegisterObject(ushort meshID, Vector3 pos, Quaternion rot, Vector3 scale)
    {
        if (!_isConfigLoaded) return;

        if (!_configIdCache.TryGetValue(meshID, out MeshData meshData))
        {
            return;
        }

        Matrix4x4 matrix = Matrix4x4.TRS(pos, rot, scale);

        if (!_loadedMeshes.TryGetValue(meshID, out Mesh targetMesh))
        {
            if (!_meshesInLoadingProgress.Contains(meshID))
            {
                LoadMeshIfNeeded(meshID).Forget();
            }
        }

        if (_meshRefCount.ContainsKey(meshID))
            _meshRefCount[meshID]++;
        else
            _meshRefCount[meshID] = 1;

        if (!_masterRenderQueue.TryGetValue(meshID, out var subMeshDict))
        {
            subMeshDict = new Dictionary<int, InstanceBuffer>();
            _masterRenderQueue[meshID] = subMeshDict;
        }

        if (subMeshDict.TryGetValue(0, out var firstBuffer))
        {
            for (int i = 0; i < firstBuffer.Count; i++)
            {
                if (firstBuffer.Matrices[i] == matrix) return;
            }
        }

        int exactSubMeshCount = meshData.SubMeshMaterials != null ? meshData.SubMeshMaterials.Length : 1;

        for (int subMeshIndex = 0; subMeshIndex < exactSubMeshCount; subMeshIndex++)
        {
            if (!subMeshDict.TryGetValue(subMeshIndex, out var buffer))
            {
                buffer = new InstanceBuffer();
                buffer.Initialize(INSTANCE_BUFFER_MAX_SIZE);
            }

            if (buffer.Count < INSTANCE_BUFFER_MAX_SIZE)
            {
                buffer.Matrices[buffer.Count] = matrix;
                buffer.Count++;

                subMeshDict[subMeshIndex] = buffer;
            }
        }
    }

    public void UnregisterObject(ushort meshID, Vector3 pos, Quaternion rot, Vector3 scale)
    {
        if (!_isConfigLoaded) return;
        if (!_loadedMeshes.TryGetValue(meshID, out Mesh targetMesh)) return;
        Matrix4x4 matrix = Matrix4x4.TRS(pos, rot, scale);
        bool wasRemoved = false;

        if (_masterRenderQueue.TryGetValue(meshID, out var subMeshDict))
        {
            if (subMeshDict.TryGetValue(0, out var firstBuffer))
            {
                for (int i = 0; i < firstBuffer.Count; i++)
                {
                    if (firstBuffer.Matrices[i] == matrix)
                    {
                        for (int j = i; j < firstBuffer.Count - 1; j++)
                        {
                            firstBuffer.Matrices[j] = firstBuffer.Matrices[j + 1];
                        }
                        firstBuffer.Count--;
                        subMeshDict[0] = firstBuffer;
                        wasRemoved = true;
                        break;
                    }
                }
            }

            if (wasRemoved)
            {
                for (int subMeshIndex = 1; subMeshIndex < targetMesh.subMeshCount; subMeshIndex++)
                {
                    if (subMeshDict.TryGetValue(subMeshIndex, out var buffer))
                    {
                        for (int i = 0; i < buffer.Count; i++)
                        {
                            if (buffer.Matrices[i] == matrix)
                            {
                                for (int j = i; j < buffer.Count - 1; j++)
                                {
                                    buffer.Matrices[j] = buffer.Matrices[j + 1];
                                }
                                buffer.Count--;

                                subMeshDict[subMeshIndex] = buffer;
                                break;
                            }
                        }
                    }
                }

                UnregisterAndReleaseMesh(meshID);
            }
        }
    }

    private void UnregisterAndReleaseMesh(ushort meshID)
    {
        if (!_loadedMeshes.ContainsKey(meshID)) return;

        _meshRefCount[meshID]--;

        if (_meshRefCount[meshID] <= 0)
        {
            Mesh meshToRelease = _loadedMeshes[meshID];

            _masterRenderQueue.Remove(meshID);
            _meshMaterialCache.Remove(meshToRelease);
            _loadedMeshes.Remove(meshID);
            _meshRefCount.Remove(meshID);
            _meshesInLoadingProgress.Remove(meshID);

            if (_configIdCache.TryGetValue(meshID, out var meshData))
            {
                meshData.meshReference.ReleaseAsset();
            }
        }
    }

    private void RenderQueues() 
    {
        foreach (var queueEntry in _masterRenderQueue)
        {
            ushort meshID = queueEntry.Key;
            var subMeshes = queueEntry.Value;

            if (!_loadedMeshes.TryGetValue(meshID, out Mesh currentMesh)) continue;
            if (!_meshMaterialCache.TryGetValue(currentMesh, out Material[] materials) || materials == null) continue;

            foreach (var subMeshEntry in subMeshes)
            {
                int subMeshIndex = subMeshEntry.Key;
                InstanceBuffer buffer = subMeshEntry.Value;

                int count = buffer.Count;
                if (count == 0) continue;
                if (subMeshIndex >= currentMesh.subMeshCount) continue;

                Material targetMaterial = materials[subMeshIndex];
                if (targetMaterial == null) continue;

                RenderParams rp = new RenderParams(targetMaterial);
                rp.shadowCastingMode = ShadowCastingMode.On;
                rp.receiveShadows = true;
                rp.lightProbeUsage = LightProbeUsage.BlendProbes;

                Graphics.RenderMeshInstanced(
                    rparams: rp,
                    mesh: currentMesh,
                    submeshIndex: subMeshIndex,
                    instanceData: buffer.Matrices,
                    instanceCount: count
                );
            }
        }
    }

    private async UniTask LoadMeshIfNeeded(ushort meshID)
    {
        await UniTask.WaitUntil(() => _isConfigLoaded);

        if (_loadedMeshes.ContainsKey(meshID)) return;
        if (_meshesInLoadingProgress.Contains(meshID)) return;
        if (!_configIdCache.TryGetValue(meshID, out var meshData)) return;

        _meshesInLoadingProgress.Add(meshID);

        Mesh loadedMesh = await meshData.meshReference.LoadAssetAsync().ToUniTask();

        Bounds realBounds = loadedMesh.bounds;
        loadedMesh.bounds = new Bounds(realBounds.center, realBounds.size * 3f);

        _meshMaterialCache[loadedMesh] = meshData.SubMeshMaterials;
        _loadedMeshes[meshID] = loadedMesh;
        _meshesInLoadingProgress.Remove(meshID);
    }

    public void ClearQueues()
    {
        foreach (var subMeshDict in _masterRenderQueue.Values)
        {
            List<int> keys = new List<int>(subMeshDict.Keys);
            foreach (int key in keys)
            {
                var buffer = subMeshDict[key];
                buffer.Count = 0;
                subMeshDict[key] = buffer;
            }
        }
    }

    private async UniTaskVoid LoadConfigAsync()
    {
        _meshConfig = await Addressables.LoadAssetAsync<MeshMaterialConfig>(AssetPath.StaticMeshesDatabase).ToUniTask();
        _isConfigLoaded = _meshConfig != null;

        if (_isConfigLoaded)
        {
            _configIdCache = new Dictionary<ushort, MeshData>(_meshConfig.allMeshes.Length);
            foreach (var data in _meshConfig.allMeshes)
            {
                _configIdCache[data.Id] = data;
            }
        }
    }

    public void Dispose()
    {
        RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;

        if (_masterRenderQueue != null)
        {
            foreach (var subMeshDict in _masterRenderQueue.Values)
            {
                foreach (var buffer in subMeshDict.Values)
                {
                    buffer.Dispose();
                }
            }
            _masterRenderQueue.Clear();
        }

        if (_loadedMeshes != null && _configIdCache != null)
        {
            foreach (var loadedMeshEntry in _loadedMeshes)
            {
                ushort meshID = loadedMeshEntry.Key;
                if (_configIdCache.TryGetValue(meshID, out var meshData))
                {
                    meshData.meshReference.ReleaseAsset();
                }
            }
        }

        _loadedMeshes?.Clear();
        _meshMaterialCache?.Clear();
        _meshRefCount?.Clear();
        _meshesInLoadingProgress?.Clear();
    }
}
