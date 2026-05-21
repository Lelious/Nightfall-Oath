using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public interface IMapObject
{
    public ushort Id();
    public bool Active();
    public bool HasNavigationMeshes();
    public void FillNavSources(List<NavMeshBuildSource> targetList);
    public bool PersistentObject();
    public Vector3 Position();
    public Vector3 Scale();
    public Transform Transform();
    public Quaternion Rotation();
    public void SetActive(bool active);
    public void SetPosition(Vector3 position);
    public void SetRotation(Quaternion rotation);
    public void SetScale(Vector3 scale);
    public bool IsInitialized();
}
