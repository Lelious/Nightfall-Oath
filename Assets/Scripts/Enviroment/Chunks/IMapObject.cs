using UnityEngine;

public interface IMapObject
{
    public ushort Id();
    public bool Active();
    public Vector3 Position();
    public Quaternion Rotation();
    public Vector3 Scale();
    public bool PersistentObject();
    public void SetActive(bool active);
    public void SetPosition(Vector3 position);
    public void SetRotation(Quaternion rotation);
    public void SetScale(Vector3 scale);
    public Transform Transform();
}