using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class MapEnviromentObject : MonoBehaviour, IMapObject
{
    [SerializeField] private ushort ID;
    [SerializeField] private bool _persistentObject;

    [SerializeField] private List<MeshFilter> _navigationMeshes;

    private NavMeshBuildSource[] _cachedSources;
    private bool _initialized;

    public bool Active() => gameObject.activeInHierarchy;

    public void FillNavSources(List<NavMeshBuildSource> targetList)
    {
        PrecomputeSources();

        for (int i = 0; i < _cachedSources.Length; i++)
        {
            targetList.Add(_cachedSources[i]);
        }
    }

    public void PrecomputeSources()
    {
        _cachedSources = new NavMeshBuildSource[_navigationMeshes.Count];

        for (int i = 0; i < _navigationMeshes.Count; i++)
        {
            _cachedSources[i] = new NavMeshBuildSource
            {
                shape = NavMeshBuildSourceShape.Mesh,
                sourceObject = _navigationMeshes[i].sharedMesh,
                transform = _navigationMeshes[i].transform.localToWorldMatrix,
                area = 0
            };
        }
    }

    public bool HasNavigationMeshes() => _navigationMeshes.Count > 0;
    public ushort Id() => ID;
    public bool IsInitialized() => _initialized;
    public bool PersistentObject() => _persistentObject;
    public Vector3 Position() => transform.position;
    public Quaternion Rotation() => transform.rotation;
    public Vector3 Scale() => transform.localScale;
    public void SetActive(bool active) => gameObject.SetActive(active);
    public void SetPosition(Vector3 position) => transform.position = position;
    public void SetRotation(Quaternion rotation) => transform.rotation = rotation;
    public void SetScale(Vector3 scale) => transform.localScale = scale;
    public Transform Transform() => transform;
}

public class MapObjectInfo
{
    public ushort Id;
    public Vector3 Position;
    public Quaternion Rotation;
    public Vector3 Scale;
    public IMapObject MapObject;

    public MapObjectInfo(ushort id, Vector3 position, Quaternion rotation, Vector3 scale)
    {
        Id = id;
        Position = position;
        Rotation = rotation;
        Scale = scale;
    }

    public void SetMapObject(IMapObject obj)
    {
        MapObject = obj;
        MapObject.SetPosition(Position);
        MapObject.SetRotation(Rotation);
        MapObject.SetScale(Scale);
    }
}
