using UnityEngine;

public class MapEnviromentObject : MonoBehaviour, IMapObject
{
    public bool ExcludeFromBake;
    [SerializeField] private ushort ID;
    [SerializeField] private MapObjectType Type;

    public bool Active() => gameObject.activeInHierarchy;
    public ushort Id() => ID;
    public Vector3 Position() => transform.position;
    public Quaternion Rotation() => transform.rotation;
    public Vector3 Scale() => transform.localScale;
    public void SetActive(bool active) => gameObject.SetActive(active);
    public void SetPosition(Vector3 position) => transform.position = position;
    public void SetRotation(Quaternion rotation) => transform.rotation = rotation;
    public void SetScale(Vector3 scale) => transform.localScale = scale;
    public Transform Transform() => transform;
    public MapObjectType ObjType() => Type;
}